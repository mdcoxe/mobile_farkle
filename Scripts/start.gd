extends Control

const RULES_SCENE = preload("res://Scene/Rules.tscn")
const SCORING_SCENE = preload("res://Scene/Scoring.tscn")

func _on_play_pressed() -> void:
	print("PLAY")
	get_tree().change_scene_to_file("res://Scene/Small.tscn")
	
func _on_quit_pressed() -> void:
	print("QUIT")
	get_tree().quit()
	
func _on_rules_pressed() -> void:
	var rules_scene = RULES_SCENE.instantiate()
	add_child(rules_scene)

func _on_scoring_pressed() -> void:
	var scoring_scene = SCORING_SCENE.instantiate()
	add_child(scoring_scene)
