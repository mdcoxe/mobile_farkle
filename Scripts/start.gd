extends Control

func _on_play_pressed() -> void:
	print("PLAY")
	get_tree().change_scene_to_file("res://Game.tscn")
	

func _on_quit_pressed() -> void:
	print("QUIT")
	get_tree().quit()
	
