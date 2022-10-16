extends CanvasLayer

onready var tree = $MarginContainer/VBoxContainer/HBoxContainer/Tree
onready var pages_container = $MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer

var back_to = null
var pages = {}

func _ready():
	tree.connect("item_selected", self, "_on_item_selected")
	$MarginContainer/VBoxContainer/Button.connect("pressed", self, "_go_back")
	
	var root = tree.create_item()
	tree.set_hide_root(true)
	var volume = tree.create_item(root)
	volume.set_text(0, "Volume")
	volume.set_tooltip(0, " ")
	var controls = tree.create_item(root)
	controls.set_text(0, "Controls")
	controls.set_tooltip(0, " ")
	var misc = tree.create_item(root)
	misc.set_text(0, "Misc")
	misc.set_tooltip(0, " ")
	
	pages = {
		volume: pages_container.get_node("Volume"),
		controls: pages_container.get_node("Controls"),
		misc: pages_container.get_node("Misc")
	}
	

func _on_item_selected():
	for item in pages:
		pages[item].set_visible(item == tree.get_selected())

func _go_back():
	if back_to:
		get_parent().change_scene_to(back_to)
