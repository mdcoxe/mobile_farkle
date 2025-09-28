extends MarginContainer

const RULES_SCENE = preload("res://Scene/Rules.tscn")
const SCORING_SCENE = preload("res://Scene/Scoring.tscn")
const STATS_SCENE = preload("res://Scene/Scoring.tscn")
@onready var start_over_dialog: MarginContainer = $ColorRect/StartOverDialog
@onready var margin_container: MarginContainer = $ColorRect/MarginContainer

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
	margin_container.hide()
	start_over_dialog.visible = true

func _on_start_over_dialog_confirmed() -> void:
	get_tree().change_scene_to_file("res://Scene/Start.tscn")

func _on_start_over_dialog_canceled() -> void:
	margin_container.visible = true
	start_over_dialog.hide()
