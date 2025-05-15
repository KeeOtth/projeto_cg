extends Node3D

@export var powerup_scenes: Array[PackedScene]
@export var tempo_powerup_em_campo := 20
@export var powerup_limit := 10
var powerup_count := 0
var pode_spawnar := true

func _on_powerup_coletado(_powerup):
	powerup_count -= 1
	print_debug("Power-up foi coletado por um jogador!")

func _on_powerup_despawn(_powerup):
	powerup_count -= 1
	print_debug("Power-up foi coletado por um jogador!")

func _on_power_timer_timeout() -> void:
	if not pode_spawnar or powerup_count>= powerup_limit:
		return

	var powerup_scene = powerup_scenes.pick_random()
	var powerup = powerup_scene.instantiate()
	var spawn_location = get_node("../SpawnPath/SpawnLocation")
	spawn_location.progress_ratio = randf()
	
	powerup_count+=1
	
	powerup.tempo_ativo = tempo_powerup_em_campo
	powerup.position = spawn_location.position
	powerup.connect("powerup_coletado", Callable(self, "_on_powerup_coletado"))
	powerup.connect("powerup_despawn", Callable(self, "_on_powerup_despawn"))

	add_child(powerup)
