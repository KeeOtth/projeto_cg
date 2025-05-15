extends CanvasLayer

var gols_A = 0
var gols_B = 0

@onready var label_time = $HBoxContainer/LabelPlacar

func contabilizar_gols(time: String):
	if time == "A":
		gols_A += 1
	else:
		gols_B += 1
	label_time.text = "CSA %d X %d CRB" % [gols_A, gols_B]
