extends CharacterBody3D

@export var speed = 8
@export var fall_acceleration = 75
@export var is_active = false

var target_velocity = Vector3.ZERO
@export var held_ball: RigidBody3D = null

func _physics_process(delta):
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	$Pivot/DirectionalIndicator.visible = is_active
	if not is_active:
		return
	
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_back"):
		direction.x += 1
	if Input.is_action_pressed("move_forward"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.z -= 1
	if Input.is_action_pressed("move_left"):
		direction.z += 1

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

	if Input.is_action_just_pressed("hold_ball"):
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
				if ball is RigidBody3D:
					var to_ball = (ball.global_transform.origin - player_pos)
					to_ball.y = 0
					var distance = to_ball.length()
					var direction_to_ball = to_ball.normalized()
					var dot = player_dir.dot(direction_to_ball)
					
					if distance <= max_distance and dot >= min_dot:
						held_ball = ball
						held_ball.freeze = true
						break

	if Input.is_action_just_pressed("ui_accept") and held_ball:
		held_ball.freeze = false
		var hold_pos = global_transform.origin + $Pivot.transform.basis.z * -1.6 + Vector3(0, 0.37, 0)
		held_ball.global_transform.origin = hold_pos
		var impulse_direction = -$Pivot.basis.z.normalized()
		var impulse_strength = 20.0
		held_ball.apply_impulse(impulse_direction * impulse_strength)
		held_ball = null

	if held_ball:
		var hold_pos = global_transform.origin + $Pivot.transform.basis.z * -1.2 + Vector3(0, 0.37, 0)
		held_ball.global_transform.origin = hold_pos

	# Moving the Character
	velocity = target_velocity
	move_and_slide()
