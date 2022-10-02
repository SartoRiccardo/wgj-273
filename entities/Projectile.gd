extends Node2D

export (Resource) var projectile_data
export (int) var speed = 500

var target = null
var hit = false

func _ready():
	$Sprite.set_texture(projectile_data.texture)
	$Hurtbox.connect("area_entered", self, "_on_projectile_hit")

func _process(delta):
	if target == null or hit:
		return
	global_position = global_position.move_toward(target.global_position, speed*delta)

func set_target(new_target):
	target = new_target
	target.add_to_group("targeted")

func _on_projectile_hit(_a2d):
	if hit:
		return
	hit = true
	
	if target.is_in_group("targeted"):
		target.remove_from_group("targeted")
	target.get_hit(projectile_data)
	if not projectile_data.bounce:
		queue_free()
	else:
		$AnimationPlayer.play("bounce")
