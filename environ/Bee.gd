extends Sprite

export (Vector2) var wander_center = Vector2.ZERO
export (int) var wander_range = 20
export (Curve) var path_progression

var rng = RandomNumberGenerator.new()
var wander_target = Vector2.ZERO
var wander_start = wander_target
var wander_progress = 0.0
var wander_speed = 10
var distance = 0.0

func _ready():
	rng.randomize()
	wander_start = position
	print(position, wander_start)

func _process(delta):
	if is_close_to_destination() or distance <= 0:
		var wander_angle = rng.randf_range(0, 2*PI)
		var wander_distance = rng.randf_range(0, wander_range)
		wander_start = position
		wander_target = Vector2(
			cos(wander_angle)*wander_distance,
			sin(wander_angle)*wander_distance
		)
		distance = wander_start.distance_to(wander_target)
		wander_progress = 0.0
		set_flip_h(wander_target.x - wander_start.x < 0)
	
	position = wander_start.linear_interpolate(wander_target,
		path_progression.interpolate(clamp(wander_progress/distance, 0, 1)))
	wander_progress += delta*wander_speed

func is_close_to_destination():
	return stepify(wander_target.x, 0.001) == stepify(position.x, 0.001) and \
		stepify(wander_target.y, 0.001) == stepify(position.y, 0.001)
