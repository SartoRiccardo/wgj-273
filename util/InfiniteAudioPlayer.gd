extends Node


func play():
	var audio = get_child(0)
	if audio.is_playing():
		audio = audio.duplicate()
		add_child(audio)
		audio.play()
		yield(audio, "finished")
		audio.queue_free()
	else:
		audio.play()
