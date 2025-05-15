extends Node3D

var all_players = []
var team_a_players = []
var team_b_players = []

# joystic 0 eh o vermelho, time a
# joystic 1 eh o azul, time b
var last_switch_time_a := -1
var last_switch_time_b := -1

var switch_delay := 1.2

var current_index_a = 0
var current_index_b = 0

func _on_blue_team_gol_body_entered(body: Node3D) -> void:
	get_node("/root/Main/Placar").contabilizar_gols("B")
	body.freeze = true
	body.get_node("MeshInstance3D").visible = false
	await get_tree().create_timer(2.0).timeout
	body.global_transform.origin = Vector3(0, 0.5, 0)
	body.get_node("MeshInstance3D").visible = true
	body.freeze = false
		
func _on_red_team_gol_body_entered(body: Node3D) -> void:
	get_node("/root/Main/Placar").contabilizar_gols("A")
	body.freeze = true
	body.get_node("MeshInstance3D").visible = false
	await get_tree().create_timer(2.0).timeout
	body.global_transform.origin = Vector3(0, 0.5, 0)
	body.get_node("MeshInstance3D").visible = true
	body.freeze = false

func _ready():
	# Pega todos os jogadores
	var all_players = get_tree().get_nodes_in_group("Players")
	team_a_players = get_tree().get_nodes_in_group("Time_A")
	team_b_players = get_tree().get_nodes_in_group("Time_B")
	
	# Ativa o primeiro jogador de cada time
	if team_a_players.size() > 0:
		team_a_players[0].is_active = true
	if team_b_players.size() > 0:
		team_b_players[0].is_active = true

func _process(delta):
	if Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER):
			if(Time.get_ticks_msec() / 1000.0 - last_switch_time_a >= switch_delay):
				team_a_players[current_index_a].is_active = false
				if team_a_players[current_index_a].held_ball:
					team_a_players[current_index_a].held_ball.freeze = false
					team_a_players[current_index_a].held_ball = null
				last_switch_time_a = Time.get_ticks_msec() / 1000.0
				current_index_a = (current_index_a + 1) % team_a_players.size()
				print(current_index_a)
				team_a_players[current_index_a].is_active = true

	if Input.is_joy_button_pressed(1, JOY_BUTTON_RIGHT_SHOULDER):
			if(Time.get_ticks_msec() / 1000.0 - last_switch_time_b >= switch_delay):
				team_b_players[current_index_b].is_active = false
				if team_b_players[current_index_b].held_ball:
					team_b_players[current_index_b].held_ball.freeze = false
					team_b_players[current_index_b].held_ball = null
				last_switch_time_b = Time.get_ticks_msec() / 1000.0
				current_index_b = (current_index_b + 1) % team_b_players.size()
				team_b_players[current_index_b].is_active = true


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
