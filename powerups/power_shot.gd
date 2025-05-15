extends Area3D

@export var tempo_ativo := 17
@export var boost_duration := 10.0
@export var strenght_bonus := 2

signal powerup_coletado(powerup: Node)
signal powerup_despawn(powerup: Node)

func _ready():
	print_debug("PowerUp iniciado. Timer configurado.")
	$despawn_timer.wait_time = tempo_ativo
	$despawn_timer.one_shot = true
	$despawn_timer.start()
	
	$piscar_timer.wait_time = tempo_ativo - 3
	$piscar_timer.one_shot = true
	$piscar_timer.start()

	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Players"):
		emit_signal("powerup_coletado", self)
		aplicar_efeito(body)
		queue_free()

func _on_despawn_timer_timeout():
	emit_signal("powerup_despawn", self)
	queue_free()

func aplicar_efeito(player):
	player.aplicar_powershot(boost_duration, strenght_bonus)

func _on_piscar_timer_timeout() -> void:
	$blink_timer.wait_time = 0.2
	$blink_timer.start()
	$blink_timer.timeout.connect(_piscar)

func _piscar():
	visible = not visible
