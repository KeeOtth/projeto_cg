extends CanvasLayer

func _process(delta):
	var main = get_node("/root/Main")
	visible = main.is_replaying
