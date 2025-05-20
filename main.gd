extends Node3D

var all_players = []
var team_azul_players = []
var team_vermelho_players = []

# joystic 0 eh o vermelho
# joystic 1 eh o azul
var last_switch_time_azul := -1
var last_switch_time_vermelho := -1

var switch_delay := 1.2

var current_index_azul = 0
var current_index_vermelho = 0

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
var original_frame_0 = []


## laterais
var is_gol := false
var is_lateral := false
var lateral_team = null  # "Azul" ou "Vermelho"
var lateral_player: CharacterBody3D = null

func _on_blue_team_gol_body_entered(body: Node3D) -> void:
	is_gol = true
	for player_blue in team_azul_players:
		player_blue.anim.play(bad_animations.pick_random())
	
	for player_red in team_vermelho_players:
		player_red.anim.play(good_animations.pick_random())

	get_node("/root/Main/Placar").contabilizar_gols(Globals.TIME_VERMELHO)
	body.freeze = true
	body.get_node("MeshInstance3D").visible = false

	await get_tree().create_timer(5.0).timeout
	for player in all_players:
		player.anim.play("idle")
	start_replay()
	body.get_node("MeshInstance3D").visible = true
	body.freeze = false

func _on_red_team_gol_body_entered(body: Node3D) -> void:
	is_gol = true
	for player_blue in team_azul_players:
		player_blue.anim.play(good_animations.pick_random())
	
	for player_red in team_vermelho_players:
		player_red.anim.play(bad_animations.pick_random())
		
	get_node("/root/Main/Placar").contabilizar_gols(Globals.TIME_AZUL)
	body.freeze = true
	body.get_node("MeshInstance3D").visible = false

	await get_tree().create_timer(5.0).timeout
	for player in all_players:
		player.anim.play("idle")
	start_replay()
	body.get_node("MeshInstance3D").visible = true
	body.freeze = false



func _ready():
	# Pega todos os jogadores
	all_players = get_tree().get_nodes_in_group("Players")
	team_azul_players = get_tree().get_nodes_in_group("Time_Azul")
	team_vermelho_players = get_tree().get_nodes_in_group("Time_Vermelho")
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
	if team_azul_players.size() > 0:
		team_azul_players[0].is_active = true
	if team_vermelho_players.size() > 0:
		team_vermelho_players[0].is_active = true
	
	original_frame_0 = {
		"ball_pos": $Ball.global_transform.origin,
		"team_azul": [],
		"team_vermelho": [],
		"direction_a": [],
		"direction_b": []
	}

	for player in all_players:
		player.get_node("Pivot").look_at(Vector3(0, 0, 0), Vector3.UP)
		player.anim.play("Robot_Idle")

	for player in team_azul_players:
		var pos = player.global_transform.origin
		var rot = player.get_node("Pivot").global_transform.basis

		original_frame_0["team_azul"].append({
			"position": pos,
			"pivot_basis": rot,
			"animation": player.anim.current_animation
		})

	for player in team_vermelho_players:
		var pos = player.global_transform.origin
		var rot = player.get_node("Pivot").global_transform.basis

		original_frame_0["team_vermelho"].append({
			"position": pos,
			"pivot_basis": rot,
			"animation": player.anim.current_animation
		})
	


func _process(_delta):
	if not is_replaying:
		var frame = {
			"ball_pos": $Ball.global_transform.origin,
			"team_azul": [],
			"team_vermelho": [],
			"direction_a": [],
			"direction_b": [],
		}

		for player in team_azul_players:
			var pos = player.global_transform.origin
			var rot = player.get_node("Pivot").global_transform.basis

			frame["team_azul"].append({
				"position": pos,
				"pivot_basis": rot,
				"animation": player.anim.current_animation
			})


		for player in team_vermelho_players:
			var pos = player.global_transform.origin
			var rot = player.get_node("Pivot").global_transform.basis

			frame["team_vermelho"].append({
				"position": pos,
				"pivot_basis": rot,
				"animation": player.anim.current_animation
			})

		replay_frames.append(frame)
		if replay_frames.size() > MAX_REPLAY_FRAMES:
			replay_frames.pop_front()

	if is_replaying:
		$Ball.freeze = true
		if replay_index < replay_frames.size():
			var frame = replay_frames[replay_index]
			$Ball.global_transform.origin = frame["ball_pos"]
			
			for i in frame["team_azul"].size():
				var last_pos = team_azul_players[i].global_transform.origin
				team_azul_players[i].global_transform.origin = frame["team_azul"][i]["position"] 

				if frame["team_azul"][i]["animation"] != team_azul_players[i].anim.current_animation:
					team_azul_players[i].anim.play(frame["team_azul"][i]["animation"])

				team_azul_players[i].global_transform.origin = frame["team_azul"][i]["position"] 
				team_azul_players[i].get_node("Pivot").global_transform.basis = frame["team_azul"][i]["pivot_basis"]
				
			for i in frame["team_vermelho"].size():
				var last_pos = team_vermelho_players[i].global_transform.origin
				team_vermelho_players[i].global_transform.origin = frame["team_vermelho"][i]["position"] 
				
				if frame["team_vermelho"][i]["animation"] != team_vermelho_players[i].anim.current_animation:
					team_vermelho_players[i].anim.play(frame["team_vermelho"][i]["animation"])
					
				team_vermelho_players[i].global_transform.origin = frame["team_vermelho"][i]["position"] 
				team_vermelho_players[i].get_node("Pivot").global_transform.basis = frame["team_vermelho"][i]["pivot_basis"]

			replay_index += 1
		else:
			$Ball.freeze = false
			is_replaying = false
			replay_index = 0
			$Ball.global_transform.origin = original_frame_0["ball_pos"]
			$Ball.get_node("MeshInstance3D").visible = true
			$Ball.holder = null
			for i in original_frame_0["team_azul"].size():
				team_azul_players[i].global_transform.origin = original_frame_0["team_azul"][i]["position"] 
				team_azul_players[i].get_node("Pivot").global_transform.basis = original_frame_0["team_azul"][i]["pivot_basis"]
				team_azul_players[i].anim.play("Robot_Idle")
				team_azul_players[i].is_active = false
				team_azul_players[i].set_physics_process(false)
				team_azul_players[i].held_ball = null
			for i in original_frame_0["team_vermelho"].size():
				team_vermelho_players[i].global_transform.origin = original_frame_0["team_vermelho"][i]["position"] 
				team_vermelho_players[i].get_node("Pivot").global_transform.basis = original_frame_0["team_vermelho"][i]["pivot_basis"]
				team_vermelho_players[i].anim.play("Robot_Idle")
				team_vermelho_players[i].is_active = false
				team_vermelho_players[i].set_physics_process(false)
				team_vermelho_players[i].held_ball = null

			# Ativa o primeiro jogador de cada time
			if team_azul_players.size() > 0:
				team_azul_players[0].is_active = true
			if team_vermelho_players.size() > 0:
				team_vermelho_players[0].is_active = true
			for player in all_players:
				player.set_physics_process(true)
			
			is_gol = false
	
	if not is_replaying and not is_lateral:
		if Input.is_joy_button_pressed(1, JOY_BUTTON_RIGHT_SHOULDER):
				if(Time.get_ticks_msec() / 1000.0 - last_switch_time_azul >= switch_delay):
					team_azul_players[current_index_azul].is_active = false
					if team_azul_players[current_index_azul].held_ball:
						team_azul_players[current_index_azul].held_ball.holder = null
						team_azul_players[current_index_azul].held_ball = null
					last_switch_time_azul = Time.get_ticks_msec() / 1000.0
					current_index_azul = (current_index_azul + 1) % team_azul_players.size()
					team_azul_players[current_index_azul].is_active = true

		if Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER):
				if(Time.get_ticks_msec() / 1000.0 - last_switch_time_vermelho >= switch_delay):
					team_vermelho_players[current_index_vermelho].is_active = false
					if team_vermelho_players[current_index_vermelho].held_ball:
						team_vermelho_players[current_index_vermelho].held_ball.holder = null
						team_vermelho_players[current_index_vermelho].held_ball = null
					last_switch_time_vermelho = Time.get_ticks_msec() / 1000.0
					current_index_vermelho = (current_index_vermelho + 1) % team_vermelho_players.size()
					team_vermelho_players[current_index_vermelho].is_active = true

func _on_lateral_body_entered(area: Area3D, body: Node3D) -> void:
	if is_lateral or is_replaying:
		return
	
	print("Bola saiu pela lateral:", area.name)

	is_lateral = true
	body.freeze = true
	body.get_node("MeshInstance3D").visible = false

	var pos = body.global_transform.origin
	pos.y = 0
	if Globals.last_team == Globals.TIME_AZUL:
		lateral_team =  Globals.TIME_VERMELHO
	else:
		lateral_team =  Globals.TIME_AZUL

	var players = null
	if lateral_team == Globals.TIME_AZUL:
		players = team_azul_players
	else:
		players =  team_vermelho_players

	lateral_player = get_nearest_player(players, pos)
	lateral_player.global_transform.origin = pos
	await get_tree().create_timer(1.0).timeout
	body.get_node("MeshInstance3D").visible = true
	body.freeze = false

	if body.holder:
		body.holder.held_ball = null
		body.holder = null


	# fazer o lateral olhar para o centro di canmpo
	lateral_player.anim.play("Robot_Idle")
	lateral_player.get_node("Pivot").look_at(Vector3(0, 0, 0), Vector3.UP)
	var other = lateral_player.get_nearest_teammate()

	for player in players:
			player.is_active = false
			player.is_batedor = false
			player.anim.play("Robot_Idle")
			
	lateral_player.is_batedor = true
	
	if other:
		other.is_active = true
		other.is_batedor = false
		other.anim.play("Robot_Idle")
	else:
		print("NENHUM JOGADOR PROXIMO")
	
	lateral_player.held_ball = body
	body.holder = lateral_player

	print("Lateral para o time:", lateral_team)


func _on_escanteio_area_entered(area: Area3D, body: Node3D) -> void:
	print("Bola saiu para escanteio:", area.name)

	# Define os corners do campo
	var corners = {
		"Azul_sup": Vector3(-18, 0, 28),
		"Azul_inf": Vector3(18, 0, 28),
		"Verm_sup": Vector3(-18, 0, -28),
		"Verm_inf": Vector3(18, 0, -28)
	}

	if area.name in corners:
		body.global_transform.origin = corners[area.name]
		body.freeze = true
		body.get_node("MeshInstance3D").visible = true
		print("Bola posicionada no corner:", corners[area.name])

	_on_lateral_body_entered(area, body)


func start_replay():
	is_replaying = true
	replay_index = 0
	
func get_nearest_player(players: Array, position: Vector3) -> CharacterBody3D:
	var closest = null
	var min_dist = INF
	for player in players:
		var dist = player.global_transform.origin.distance_to(position)
		if dist < min_dist:
			min_dist = dist
			closest = player
	return closest
