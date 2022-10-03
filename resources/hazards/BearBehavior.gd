extends Resource
class_name BearBehavior

signal docile_change(status)

export (bool) var docile = false

func set_docile(new_docile):
	docile = new_docile
	emit_signal("docile_change", docile)
