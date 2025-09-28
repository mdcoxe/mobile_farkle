extends Control

@onready var rules: MarginContainer = $Rules

func _on_play_pressed() -> void:
	print("PLAY")
	get_tree().change_scene_to_file("res://Scene/Small.tscn")
	
	
func _on_quit_pressed() -> void:
	print("QUIT")
	get_tree().quit()
	


func _on_close_rules_button_pressed() -> void:
	get_node("Rules").hide()
	
func _on_rules_pressed() -> void:
	get_node("Rules").visible=true




func _on_scoring_pressed() -> void:
	get_node("Scoring").visible = true

func _on_close_scoring_button_pressed() -> void:
	get_node("Scoring").hide()
