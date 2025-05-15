extends Area3D

@export var tempo_ativo := 5.0
@export var speed_boost := 2.0
@export var boost_duration := 10.0

signal powerup_coletado(powerup: Node)

func _ready():
	print("PowerUp iniciado. Timer configurado.")
	$despawn_timer.wait_time = tempo_ativo
	$despawn_timer.one_shot = true
	$despawn_timer.start()

	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Players"):
		emit_signal("powerup_coletado", self)
		aplicar_efeito(body)
		queue_free()

func _on_despawn_timer_timeout():
	print("DESPAWNANDO...")
	queue_free()

func aplicar_efeito(player):
	if player.has_method("aplicar_boost_velocidade"):
		player.aplicar_boost_velocidade(boost_duration, speed_boost)
