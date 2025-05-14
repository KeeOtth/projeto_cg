extends CanvasLayer

var gols_A = 0
var gols_B = 0

@onready var label_time_A = $HBoxContainer/TimeA
@onready var label_time_B = $HBoxContainer/TimeB

func contabilizar_gols(time: String):
	if time == "A":
		gols_A += 1
		label_time_A.text = "Time A: %d" % gols_A
	elif time == "B":
		gols_B += 1
		label_time_B.text = "TimeB: %d" % gols_B
