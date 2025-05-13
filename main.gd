extends Node3D


var players = []
var current_index = 0

func _on_blue_team_gol_body_entered(body: Node3D) -> void:
	print("Red fez Gol")
	pass # Replace with function body.


func _on_red_team_gol_body_entered(body: Node3D) -> void:
	print("Blue fez Gol")
	pass # Replace with function body.


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
