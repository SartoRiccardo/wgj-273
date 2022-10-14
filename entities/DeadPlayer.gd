extends KinematicBody2D

var direction = Vector2.ZERO
var speed = 0.0
var cause = Enums.DeathCause.HEALTH

func _ready():
	match cause:
		Enums.DeathCause.HEALTH:
			pass
		Enums.DeathCause.HUNGER:
			pass
	var anim_name = ("death_%s"%Enums.DeathCause.keys()[cause]).to_lower()
	if $AnimatedSprite.frames.has_animation(anim_name):
		$AnimatedSprite.set_animation(anim_name)
		$AnimatedSprite.connect("animation_finished", $AnimatedSprite, "set_playing", [false])

func _process(delta):
	speed = lerp(0.0, speed, pow(2, -6*delta))
	move_and_slide(direction*speed)

func init_from(player, death_cause):
	cause = death_cause
	global_position = player.global_position
	var hurt_particles = player.get_node("Particles/Hurt").duplicate()
	hurt_particles.set_emitting(true)
	add_child(hurt_particles)
