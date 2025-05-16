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
var bad_animations = [
	"Robot_Death",
	"Robot_No",
	"Robot_Punch"
]

var good_animations = [
	"Robot_Dance",
	"Robot_Jump",
	"Robot_ThumbsUp",
	"Robot_Yes",
]

const MAX_REPLAY_FRAMES := 600 # ~5s a 60 FPS
var replay_frames := []
var is_replaying := false
var replay_index := 0


func _on_blue_team_gol_body_entered(body: Node3D) -> void:
	for player_blue in team_a_players:
		player_blue.anim.play(bad_animations.pick_random())
	
	for player_red in team_b_players:
		player_red.anim.play(good_animations.pick_random())

	get_node("/root/Main/Placar").contabilizar_gols("B")
	body.freeze = true
	body.get_node("MeshInstance3D").visible = false

	await get_tree().create_timer(3.0).timeout
	start_replay()
	body.global_transform.origin = Vector3(0, 0.5, 0)
	body.get_node("MeshInstance3D").visible = true
	body.freeze = false
	


func _on_red_team_gol_body_entered(body: Node3D) -> void:
	for player_blue in team_a_players:
		player_blue.anim.play(good_animations.pick_random())
	
	for player_red in team_b_players:
		player_red.anim.play(bad_animations.pick_random())
		
	get_node("/root/Main/Placar").contabilizar_gols("A")
	body.freeze = true
	body.get_node("MeshInstance3D").visible = false
	start_replay()
	await get_tree().create_timer(2.0).timeout
	body.global_transform.origin = Vector3(0, 0.5, 0)
	body.get_node("MeshInstance3D").visible = true
	body.freeze = false



func _ready():
	# Pega todos os jogadores
	all_players = get_tree().get_nodes_in_group("Players")
	team_a_players = get_tree().get_nodes_in_group("Time_A")
	team_b_players = get_tree().get_nodes_in_group("Time_B")
	var escanteios = [
		$Sketchfab_Scene/Sketchfab_model/jeej/Stadium/Field/Linhas_de_fundo/Azul_sup,
		$Sketchfab_Scene/Sketchfab_model/jeej/Stadium/Field/Linhas_de_fundo/Azul_inf,
		$Sketchfab_Scene/Sketchfab_model/jeej/Stadium/Field/Linhas_de_fundo/Verm_inf,
		$Sketchfab_Scene/Sketchfab_model/jeej/Stadium/Field/Linhas_de_fundo/Verm_sup
	]
	var laterais = [
		$Sketchfab_Scene/Sketchfab_model/jeej/Stadium/Field/Laterais/Lateral_sup,
		$Sketchfab_Scene/Sketchfab_model/jeej/Stadium/Field/Laterais/Lateral_inf
	]
	
	
	for lateral in laterais:
		lateral.body_entered.connect(
			func(body): _on_lateral_body_entered(lateral, body)
			)

	for area in escanteios:
		area.body_entered.connect(
			func(body): _on_escanteio_area_entered(area, body)
		)

	# Ativa o primeiro jogador de cada time
	if team_a_players.size() > 0:
		team_a_players[0].is_active = true
	if team_b_players.size() > 0:
		team_b_players[0].is_active = true

func _process(delta):
	if not is_replaying:
		var frame = {
			"ball_pos": $Ball.global_transform.origin,
			"team_a": [],
			"team_b": [],
			"direction_a": [],
			"direction_b": []
		}

		for player in team_a_players:
			var pos = player.global_transform.origin
			var rot = player.get_node("Pivot").global_transform.basis

			frame["team_a"].append({
				"position": pos,
				"pivot_basis": rot
			})


		for player in team_b_players:
			var pos = player.global_transform.origin
			var rot = player.get_node("Pivot").global_transform.basis

			frame["team_b"].append({
				"position": pos,
				"pivot_basis": rot
			})

		replay_frames.append(frame)
		if replay_frames.size() > MAX_REPLAY_FRAMES:
			replay_frames.pop_front()

	if is_replaying:
		$Ball.freeze = true
		if replay_index < replay_frames.size():
			var frame = replay_frames[replay_index]
			$Ball.global_transform.origin = frame["ball_pos"]
			
			for i in frame["team_a"].size():
				var last_pos = team_a_players[i].global_transform.origin
				team_a_players[i].global_transform.origin = frame["team_a"][i]["position"] 

				var vel = (frame["team_a"][i]["position"] - last_pos).length()
				if vel > 0.1:
					if team_a_players[i].anim.current_animation != "Robot_Running":
						team_a_players[i].anim.play("Robot_Running")
				else:
					if team_b_players[i].anim.current_animation != "Robot_Idle":
						team_a_players[i].anim.play("Robot_Idle")
				team_a_players[i].global_transform.origin = frame["team_a"][i]["position"] 
				team_a_players[i].get_node("Pivot").global_transform.basis = frame["team_a"][i]["pivot_basis"]
				
			for i in frame["team_b"].size():
				var last_pos = team_b_players[i].global_transform.origin
				team_b_players[i].global_transform.origin = frame["team_b"][i]["position"] 

				var vel = abs((frame["team_b"][i]["position"]  - last_pos).length())

				if vel > 0.1:
					if team_b_players[i].anim.current_animation != "Robot_Running":
						team_b_players[i].anim.play("Robot_Running")
				else:
					if team_b_players[i].anim.current_animation != "Robot_Idle":
						team_b_players[i].anim.play("Robot_Idle")

				team_b_players[i].global_transform.origin = frame["team_b"][i]["position"] 
				team_b_players[i].get_node("Pivot").global_transform.basis = frame["team_b"][i]["pivot_basis"]

			replay_index += 1
		else:
			get_tree().reload_current_scene()
			for player in all_players:
				player.set_physics_process(true)
	
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


func _on_lateral_body_entered(area: Area3D, body: Node3D) -> void:
	print("Bola saiu pela área:", area.name)
	body.freeze = true
	body.get_node("MeshInstance3D").visible = false
	await get_tree().create_timer(2.0).timeout
	body.global_transform.origin = Vector3(0, 0.5, 0)
	body.get_node("MeshInstance3D").visible = true
	body.freeze = false

func _on_escanteio_area_entered(area: Area3D, body: Node3D) -> void:
	print("Bola saiu pela área:", area.name)
	body.freeze = true
	body.get_node("MeshInstance3D").visible = false
	await get_tree().create_timer(2.0).timeout
	body.global_transform.origin = Vector3(0, 0.5, 0)
	body.get_node("MeshInstance3D").visible = true
	body.freeze = false
	
func start_replay():
	is_replaying = true
	replay_index = 0
