extends MarginContainer

func _on_close_button_pressed() -> void:
	queue_free()
	print("Scene unloaded.")
