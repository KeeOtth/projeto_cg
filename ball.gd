extends RigidBody3D

@export var pickup_distance := 1.5
@export var min_dot := 0.52
var holder: CharacterBody3D = null

func _physics_process(delta):
	if holder:
		var hold_pos = holder.global_transform.origin + holder.get_node("Pivot").transform.basis.z * -1.2
		hold_pos.y = 0.39 #aproximadamente o raio da bola

		global_transform.origin = hold_pos

func try_pick_up(player: CharacterBody3D) -> bool:
	if $"..".is_lateral:
		return false
	
	var player_pos = player.global_transform.origin
	var player_dir = -player.get_node("Pivot").transform.basis.z.normalized()
	var to_ball = global_transform.origin - player_pos
	to_ball.y = 0
	
	var distance = to_ball.length()
	var dir_to_ball = to_ball.normalized()
	var dot = player_dir.dot(dir_to_ball)

	if distance <= pickup_distance and dot >= min_dot:
		if holder and holder != player:
			holder.held_ball = null
		holder = player
		return true
	return false


func throw_ball(impulse_strength: float):
	if not holder:
		return
	freeze = false
	var impulse_direction = -holder.get_node("Pivot").basis.z.normalized()
	apply_impulse(impulse_direction * impulse_strength)
	holder = null

func pass_to(direction: Vector3, force: float):
	holder = null
	apply_impulse(direction * force)
	
func _on_body_entered(body):
	if body is CharacterBody3D:
		if "Time_Azul" in body.get_groups():
			Globals.last_team = Globals.TIME_AZUL
		else:
			Globals.last_team = Globals.TIME_VERMELHO
