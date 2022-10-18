extends AudioStreamPlayer

export (float) var min_pitch = 0.8
export (float) var max_pitch = 1.2

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func play(from_position: float = 0.0) -> void:
	set_pitch_scale(rng.randf_range(min_pitch, max_pitch)) 
	.play(from_position)
