extends MarginContainer

const RULES_SCENE = preload("res://Scene/Rules.tscn")
const SCORING_SCENE = preload("res://Scene/Scoring.tscn")
const STATS_SCENE = preload("res://Scene/Scoring.tscn")

func _on_close_button_pressed() -> void:
	queue_free()
	print("Scene unloaded.")

func _on_stats_button_pressed() -> void:
	var scene = STATS_SCENE.instantiate()
	add_child(scene)

func _on_scoring_button_pressed() -> void:
	var scene = SCORING_SCENE.instantiate()
	add_child(scene)

func _on_rules_button_pressed() -> void:
	var scene = RULES_SCENE.instantiate()
	add_child(scene)

func _on_start_over_button_pressed() -> void:
	pass
