extends SpringArm3D

@onready var bola = get_node("/root/Main/Ball")

var altura := 20.0
var distancia := 2.0
var suavidade := 3.0


func _process(delta):
	if bola == null:
		return

	var bola_pos = bola.global_transform.origin
	var alvo = Vector3(bola_pos.x+8, altura, bola_pos.z + distancia)

	# Move suavemente sem rotacionar
	global_transform.origin = global_transform.origin.lerp(alvo, suavidade * delta)
