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

var target_velocity = Vector3.ZERO
@export var held_ball: RigidBody3D = null

func _process(delta):
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
	process_common(delta)

func process_common(delta):
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	$Pivot/DirectionalIndicator.visible = is_active
	
	velocity = target_velocity
	move_and_slide()
	
func process_active(delta):
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
	if Input.is_action_just_pressed("hold_ball") or (Input.is_joy_button_pressed(joystick_id, JOY_BUTTON_X) and can_press_x):
		timer_button["X"] = Time.get_ticks_msec()
		if held_ball:
			held_ball.freeze = false
			held_ball = null
		else:
			var player_pos = global_transform.origin
			var player_dir = -$Pivot.transform.basis.z
			player_dir = player_dir.normalized()
			var max_distance = 1.5
			var min_dot = 0.52
			
			for ball in get_tree().get_nodes_in_group("Ball"):
				print_debug("vamos la")
				if ball is RigidBody3D:
					var to_ball = (ball.global_transform.origin - player_pos)
					to_ball.y = 0
					var distance = to_ball.length()
					var direction_to_ball = to_ball.normalized()
					var dot = player_dir.dot(direction_to_ball)
					
					if distance <= max_distance and dot >= min_dot:
						print_debug("oxe pegouy")
						held_ball = ball
						held_ball.freeze = true
						break

	if (Input.is_action_just_pressed("attack") or  Input.is_joy_button_pressed(joystick_id, JOY_BUTTON_A)) and held_ball:
		held_ball.freeze = false
		var hold_pos = global_transform.origin + $Pivot.transform.basis.z * -1.6 + Vector3(0, 0.37, 0)
		held_ball.global_transform.origin = hold_pos
		var impulse_direction = -$Pivot.basis.z.normalized()
		held_ball.apply_impulse(impulse_direction * actual_impulse_strenght)
		if actual_impulse_strenght > base_impulse_strenght:
			actual_impulse_strenght = base_impulse_strenght
		held_ball = null

	if held_ball:
		var hold_pos = global_transform.origin + $Pivot.transform.basis.z * -1.2 + Vector3(0, 0.37, 0)
		held_ball.global_transform.origin = hold_pos
