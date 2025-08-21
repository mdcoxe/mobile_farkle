extends Control

@onready var return_to_start_button: Button = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/ButtonContainer/ReturnToStartButton
@onready var font_size_timer: Timer = $FontSizeTimer
@onready var total_score_value: Label = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Values/TotalScoreValue
@onready var highes_roll_value: Label = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Values/HighesRollValue
@onready var farkle_count_value: Label = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Values/FarkleCountValue
@onready var rounds_count_value: Label = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Values/RoundsCountValue
@onready var results_label: Label = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/ResultsLabel

var current_font_size = 21
var direction = 1 

func _ready():
	return_to_start_button.add_theme_font_size_override("font_size", current_font_size)	
	font_size_timer.start()
	
	
func _on_font_size_timer_timeout() -> void:
	current_font_size += direction

	# Reverse direction if font size hits a limit
	if current_font_size >= 36 or current_font_size <= 28:
		direction *= -1
		
	return_to_start_button.add_theme_font_size_override("font_size", current_font_size)


func _on_return_to_start_button_pressed() -> void:
	WinManager.did_win = false
	get_tree().change_scene_to_file("res://Start.tscn")

func show_stats(stats: Dictionary):
	# Update the UI labels with the values from the stats dictionary.
	results_label.text = stats["message"]
	total_score_value.text = str(stats["total_score"])
	rounds_count_value.text = str(stats["round_count"])
	farkle_count_value.text = str(stats["farkle_count"])

	if stats["win"]:
		results_label.modulate = Color(0.1, 0.8, 0.1)  # Green for win
	else:
		results_label.modulate = Color(0.8, 0.1, 0.1)  # Red for loss
	
