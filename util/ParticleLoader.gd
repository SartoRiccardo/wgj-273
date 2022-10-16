# https://www.youtube.com/watch?v=kbDj9V2MZvw
extends CanvasLayer

var material_list = preload("res://util/material_list.tres")

func _ready():
	var item_amt = material_list.materials.size()
	if material_list.shaders.size() > item_amt:
		item_amt = material_list.shaders.size()
	for i in item_amt:
		var particle = Particles2D.new()
		if i < material_list.materials.size():
			var mat = material_list.materials[i]
			particle.set_process_material(mat)
		if i < material_list.shaders.size():
			var shdr = material_list.shaders[i]
			particle.set_material(shdr)
		
		particle.set_one_shot(true)
		particle.set_modulate(Color.transparent)
		particle.set_emitting(true)
		add_child(particle)
		
var frames = 0
func _process(_d):
	frames += 1
	if frames >= 3:
		Helpers.remove_all_children(self)
		get_parent().remove_child(self)
