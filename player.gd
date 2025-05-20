extends CharacterBody3D

@export var joystick_id := 0
@onready var collision = $CollisionShape3D
@export var anim: AnimationPlayer = null
@export var base_speed = 8
@export var speed = base_speed
@export var fall_acceleration = 75
@export var is_active = false
@export var time := "Azul"
@export var base_impulse_strenght := 20
var is_rotating = false
var is_passing = false

var actual_impulse_strenght = base_impulse_strenght
var deadzone = 0.2

var cores_times = {
	"Azul": Color(0.306, 0.365, 0.796),
	"Vermelho": Color(0.796, 0.306, 0.314)
}
var fixed_delay_button = 1000 #ms
var timer_button = {
	"X": 0
}

var is_batedor = false
var target_velocity = Vector3.ZERO
@export var held_ball: RigidBody3D = null

func _process(_delta):
	if !get_node("/root/Main").is_replaying:
		if anim.current_animation in ["Robot_Running", "Robot_Idle", null, ""]:
			if target_velocity:
				anim.play("Robot_Running")
			else:
				anim.play("Robot_Idle")
		
func _ready():
	anim = $Pivot/Robot/AnimationPlayer
	
	var cor = cores_times.get(time, Color(1,1,1))
	aplicar_cor_nos_meshes_do_indicador(cor)
	aplicar_cor_nos_meshes_dos_players(cor)

func aplicar_cor_nos_meshes_dos_players(cor: Color):
	var robot = $Pivot/Robot/RobotArmature/Skeleton3D
	if robot:
		print_debug("Entrou aqui viu!(la ele)")
		for filhos in robot.get_children():
			if filhos is MeshInstance3D:
				var mat = StandardMaterial3D.new()
				mat.albedo_color = cor
				filhos.set_surface_override_material(0, mat)
			else:
				for filho in filhos.get_children():
					if filho is MeshInstance3D:
						var mat = StandardMaterial3D.new()
						mat.albedo_color = cor
						filho.set_surface_override_material(0, mat)

func aplicar_cor_nos_meshes_do_indicador(cor: Color):
	var indicador = $Pivot/DirectionalIndicator
	if indicador:
		for filho in indicador.get_children():
			if filho is MeshInstance3D:
				var mat = StandardMaterial3D.new()
				mat.albedo_color = cor
				filho.set_surface_override_material(0, mat)

func aplicar_boost_velocidade(duracao: float, multiplicador: float):
	speed = base_speed * multiplicador
	print("Boost de velocidade aplicado")
	await get_tree().create_timer(duracao).timeout
	speed = base_speed
	print("Boost de velocidade finalizado")

func aplicar_powershot(duracao: float, multiplicador: float):
	actual_impulse_strenght = base_impulse_strenght * multiplicador
	print_debug("Powershot aplicado!")
	await get_tree().create_timer(duracao).timeout
	actual_impulse_strenght = base_impulse_strenght
	print_debug("Powershot finalizado!")

func _physics_process(delta):
	target_velocity = Vector3.ZERO
	if is_active:
		process_active(delta)
	elif is_batedor:
		process_batedor(delta)
	elif !get_node("/root/Main").is_lateral and !is_rotating and !get_node("/root/Main").is_replaying:
		process_inactive(delta)

	process_common(delta)

func process_inactive(delta):
	if get_node("/root/Main").is_replaying or get_node("/root/Main").is_gol:
		return
	
	var ball = null
	if get_tree().has_group("Ball"):
		var balls = get_tree().get_nodes_in_group("Ball")
		if balls.size() > 0:
			ball = balls[0]
	
	if ball == null:
		target_velocity = Vector3.ZERO
		return
	
	var ball_pos = ball.global_transform.origin
	var my_pos = global_transform.origin
	var dir_to_ball = (ball_pos - my_pos)
	dir_to_ball.y = 0
	
	var dist_to_ball = dir_to_ball.length()
	var keep_distance = 5 
	var avoid_teammate_distance = 10
	
	var teammates = []
	if time == "Azul":
		teammates = get_tree().get_nodes_in_group("Time_Azul")
	else:
		teammates = get_tree().get_nodes_in_group("Time_Vermelho")
	
	var avoid_dir = Vector3.ZERO
	var close_teammates_count = 0
	for mate in teammates:
		if mate == self:
			continue
		var to_mate = my_pos - mate.global_transform.origin
		to_mate.y = 0
		var dist_mate = to_mate.length()
		if dist_mate < avoid_teammate_distance and dist_mate > 0:
			avoid_dir += to_mate.normalized() * (avoid_teammate_distance - dist_mate)
			close_teammates_count += 1
	
	var extra_avoidance = 0.0
	if close_teammates_count > 0:
		extra_avoidance = close_teammates_count * 0.5
	

	var target_pos = ball_pos - dir_to_ball.normalized() * (keep_distance + extra_avoidance)
	
	if dist_to_ball < keep_distance + extra_avoidance:
		var right_dir = Vector3(dir_to_ball.z, 0, -dir_to_ball.x).normalized()
		var side_pos = ball_pos + right_dir * (keep_distance + extra_avoidance)
		if (side_pos - my_pos).length() > 0.5:
			target_pos = side_pos
		else:
			target_pos = my_pos
	
	target_pos += avoid_dir
	
	# Garante que target_pos não fique dentro da bolha da bola
	var to_ball_from_target = target_pos - ball_pos
	to_ball_from_target.y = 0
	if to_ball_from_target.length() < (keep_distance + extra_avoidance):
		target_pos = ball_pos + to_ball_from_target.normalized() * (keep_distance + extra_avoidance)
	
	# Direção para onde ir
	var move_dir = target_pos - my_pos
	move_dir.y = 0
	
	if move_dir.length() > 0.1:
		move_dir = move_dir.normalized()

		var current_basis = $Pivot.basis
		var target_basis = Basis.looking_at(move_dir, Vector3.UP)
		$Pivot.basis = current_basis.slerp(target_basis, delta * 5)
		
		var speed_factor = 1.0
		if dist_to_ball < 10.0:
			speed_factor = 0.4
		elif dist_to_ball < 20.0:
			speed_factor = 0.7
		
		target_velocity.x = move_dir.x * base_speed * speed_factor
		target_velocity.z = move_dir.z * base_speed * speed_factor
	else:
		target_velocity = Vector3.ZERO
		if dist_to_ball > 0.1:
			var current_basis = $Pivot.basis
			var target_basis = Basis.looking_at(dir_to_ball.normalized(), Vector3.UP)
			$Pivot.basis = current_basis.slerp(target_basis, delta * 5)


func process_batedor(delta):
	if get_node("/root/Main").is_replaying:
		return

	var direction = Vector3.ZERO
	# nao pode andar, apenas rotacionar um angulo de min 20 ateh max 160 com o joystick right
	# ou seja, so pode fazer uma meia lua
	if Input.get_joy_axis(joystick_id, JOY_AXIS_RIGHT_Y) > deadzone:
		direction.x += Input.get_joy_axis(joystick_id, JOY_AXIS_RIGHT_Y)
	if Input.get_joy_axis(joystick_id, JOY_AXIS_RIGHT_Y) < -deadzone:
		direction.x += Input.get_joy_axis(joystick_id, JOY_AXIS_RIGHT_Y)
	if Input.get_joy_axis(joystick_id, JOY_AXIS_RIGHT_X) > deadzone:
		direction.z -= Input.get_joy_axis(joystick_id, JOY_AXIS_RIGHT_X)
	if Input.get_joy_axis(joystick_id, JOY_AXIS_RIGHT_X) < -deadzone:
		direction.z -= Input.get_joy_axis(joystick_id, JOY_AXIS_RIGHT_X)

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		var current_basis = $Pivot.basis
		var target_basis = Basis.looking_at(direction, Vector3.UP)
		$Pivot.basis = current_basis.slerp(target_basis, delta*3)

	if Input.is_joy_button_pressed(joystick_id, JOY_BUTTON_B):
		var main = get_node("/root/Main")

		if main.is_lateral and held_ball:
			held_ball.freeze = false
			held_ball.throw_ball(actual_impulse_strenght)
			held_ball = null
			main.is_lateral = false
			main.lateral_team = null
			main.lateral_player = null

func process_common(delta):
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	$Pivot/DirectionalIndicator.visible = is_active
	
	velocity = target_velocity
	move_and_slide()



func process_active(delta):
	if get_node("/root/Main").is_replaying:
		return
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_back"):
		direction.x += 1
	elif Input.get_joy_axis(joystick_id, JOY_AXIS_LEFT_Y) > deadzone:
		direction.x += Input.get_joy_axis(joystick_id, JOY_AXIS_LEFT_Y)
	
	if Input.is_action_pressed("move_forward"):
		direction.x -= 1
	elif Input.get_joy_axis(joystick_id, JOY_AXIS_LEFT_Y) < -deadzone:
		direction.x += Input.get_joy_axis(joystick_id, JOY_AXIS_LEFT_Y)
		
	if Input.is_action_pressed("move_right"):
		direction.z -= 1
	elif Input.get_joy_axis(joystick_id, JOY_AXIS_LEFT_X) > deadzone:
		direction.z -= Input.get_joy_axis(joystick_id, JOY_AXIS_LEFT_X)
		
	if Input.is_action_pressed("move_left"):
		direction.z += 1
	elif Input.get_joy_axis(joystick_id, JOY_AXIS_LEFT_X) < -deadzone:
		direction.z -= Input.get_joy_axis(joystick_id, JOY_AXIS_LEFT_X)

	

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		var current_basis = $Pivot.basis
		var target_basis = Basis.looking_at(direction, Vector3.UP)
		$Pivot.basis = current_basis.slerp(target_basis, delta * 10.0)

	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider is RigidBody3D and target_velocity.length() > 0.1:
				var offset = (collider.global_transform.origin - global_transform.origin)
				offset.y = 0
				offset = offset.normalized() * 0.01
				collider.global_transform.origin += offset
				collider.apply_impulse(collision.get_normal() * -1 * 0.5, offset)
	# gambiarra
	var can_press_x = true
	if(timer_button["X"] + fixed_delay_button > Time.get_ticks_msec()):
		can_press_x = false

	if (Input.is_action_just_pressed("hold_ball") or (Input.is_joy_button_pressed(joystick_id, JOY_BUTTON_X) and can_press_x)):
		timer_button["X"] = Time.get_ticks_msec()
		if held_ball:
			held_ball.holder = null
			held_ball = null
		else:
			for ball in get_tree().get_nodes_in_group("Ball"):
				if ball is RigidBody3D and ball.has_method("try_pick_up") and ball.try_pick_up(self):
					held_ball = ball
					if time == "Azul":
						Globals.last_team = Globals.TIME_AZUL
					else:
						Globals.last_team = Globals.TIME_VERMELHO
					print(Globals.last_team)
					break

	if (Input.is_action_just_pressed("attack") or Input.is_joy_button_pressed(joystick_id, JOY_BUTTON_A)) and held_ball:
		held_ball.throw_ball(actual_impulse_strenght)
		held_ball = null

	if Input.is_joy_button_pressed(joystick_id, JOY_BUTTON_B) and held_ball and not get_node("/root/Main").is_lateral:
		var teammate = get_nearest_teammate()
		if teammate:
			is_rotating = true
			var ball = held_ball
			var to_target = teammate.global_transform.origin - global_transform.origin
			var distance = to_target.length()
			var pass_dir = to_target.normalized()

			var min_force = 3.0
			var max_force = actual_impulse_strenght * 0.7
			var force = clamp(distance, min_force, max_force)

			is_active = false
			teammate.is_active = true
			await rotate_towards(pass_dir)

			if held_ball == ball:
				ball.pass_to(pass_dir, force)
				held_ball = null


func get_nearest_teammate() -> CharacterBody3D:
	var teammates = []
	if time == "Azul":
		teammates = get_tree().get_nodes_in_group("Time_Azul")
	else:
		teammates = get_tree().get_nodes_in_group("Time_Vermelho")
	
	var closest_player = null
	var min_dist = INF
	
	for p in teammates:
		if p == self:
			continue
		var dist = global_transform.origin.distance_to(p.global_transform.origin)
		if dist < min_dist:
			min_dist = dist
			closest_player = p
	
	return closest_player

func rotate_towards(target_dir: Vector3) -> void:
	var target_basis = Basis.looking_at(target_dir, Vector3.UP)
	while $Pivot.basis.get_euler().distance_to(target_basis.get_euler()) > 0.05:
		$Pivot.basis = $Pivot.basis.slerp(target_basis, 0.1)
		await get_tree().process_frame
	is_rotating = false
