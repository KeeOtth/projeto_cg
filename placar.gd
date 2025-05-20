extends CanvasLayer

var gols_A = 0
var gols_B = 0

@onready var label_time = $HBoxContainer/LabelPlacar

func contabilizar_gols(time):
	if time == Globals.TIME_AZUL:
		gols_A += 1
	elif time == Globals.TIME_VERMELHO:
		gols_B += 1
	else:
		error_string(0)
	label_time.text = "Azul %d X %d Vermelho" % [gols_A, gols_B]
