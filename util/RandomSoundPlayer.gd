extends Node

export (bool) var loop = false

var rng = RandomNumberGenerator.new()
var loop_is_playing = false

func _ready():
	rng.randomize()

func play():
	var children = get_children()
	if children.size() == 0 or \
			loop_is_playing and loop:
		return
	
	var success = false
	var tries = 0
	while !success and tries < 3:
		var idx = rng.randi_range(0, children.size()-1)
		var child = children[idx]
		if child.has_method("play"):
			success = true
			child.play()
			if loop:
				loop_is_playing = true
				child.connect("finished", self, "_on_audio_finished_loop", [child])
		tries += 1

func stop():
	loop_is_playing = false
	for child in get_children():
		if child.has_method("stop"):
			child.stop()
		if child.is_connected("finished", self, "_on_audio_finished_loop"):
			child.disconnect("finished", self, "_on_audio_finished_loop")

func fade_out(time: float):
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	for child in get_children():
		tween.tween_property(child, "volume_db", -80.0, time)

func _on_audio_finished_loop(audio):
	loop_is_playing = false
	audio.disconnect("finished", self, "_on_audio_finished_loop")
	play()
