extends Node3D

var players = []
var current_index = 0

func _on_blue_team_gol_body_entered(body: Node3D) -> void:
	if body.is_in_group("Ball"):
		print("GOOOOOOL")
		
		get_node("/root/Main/Placar").contabilizar_gols("B")
		
		body.freeze = true
		body.get_node("MeshInstance3D").visible = false
		await get_tree().create_timer(2.0).timeout
		body.global_transform.origin = Vector3(0, 0.5, 0)
		body.get_node("MeshInstance3D").visible = true
		body.freeze = false
		
func _on_red_team_gol_body_entered(body: Node3D) -> void:
	if body.is_in_group("Ball"):
		print("GOOOOOOL")
		
		get_node("/root/Main/Placar").contabilizar_gols("A")
		
		body.freeze = true
		body.get_node("MeshInstance3D").visible = false
		await get_tree().create_timer(2.0).timeout
		body.global_transform.origin = Vector3(0, 0.5, 0)
		body.get_node("MeshInstance3D").visible = true
		body.freeze = false

func _ready():
	# Encontra todos os jogadores (assumindo grupo "Players")
	players = get_tree().get_nodes_in_group("Players")
	if players.size() > 0:
		players[0].is_active = true

func _process(delta):
	if Input.is_action_just_pressed("switch_player"):
		# Desativa o atual
		players[current_index].is_active = false

		if players[current_index].held_ball:
			players[current_index].held_ball.freeze = false
			players[current_index].held_ball = null
		
		# Avança para o próximo
		current_index = (current_index + 1) % players.size()

		# Ativa o novo
		players[current_index].is_active = true


func _on_lateral_body_entered(body: Node3D) -> void:
		
		body.freeze = true
		body.get_node("MeshInstance3D").visible = false
		await get_tree().create_timer(2.0).timeout
		body.global_transform.origin = Vector3(0, 0.5, 0)
		body.get_node("MeshInstance3D").visible = true
		body.freeze = false


func _on_lateral_2_body_entered(body: Node3D) -> void:
		
		body.freeze = true
		body.get_node("MeshInstance3D").visible = false
		await get_tree().create_timer(2.0).timeout
		body.global_transform.origin = Vector3(0, 0.5, 0)
		body.get_node("MeshInstance3D").visible = true
		body.freeze = false
