extends Node3D

@export var powerup_scene: PackedScene
@export var cooldown_entre_spawns := 1.0
@export var tempo_powerup_em_campo := 5.0
@export var area_spawn := AABB(Vector3.ZERO, Vector3(30, 0, 20))  # área no campo

var pode_spawnar := true

func _ready():
	_start_spawner()

func _start_spawner():
	spawn_powerup()
	await get_tree().create_timer(cooldown_entre_spawns).timeout
	_start_spawner()

func spawn_powerup():
	if not pode_spawnar:
		return

	var powerup = powerup_scene.instantiate()
	powerup.position = _posicao_aleatoria()
	add_child(powerup)

	powerup.tempo_ativo = tempo_powerup_em_campo
	powerup.connect("powerup_coletado", Callable(self, "_on_powerup_coletado"))

func _posicao_aleatoria() -> Vector3:
	var min = area_spawn.position
	var size = area_spawn.size
	return Vector3(
		randf_range(min.x+5, min.x+5 + size.x),
		0.5, #Altura do chão
		randf_range(min.z+5, min.z+5 + size.z)
	)

func _on_powerup_coletado(_powerup):
	print("Power-up foi coletado por um jogador!")
