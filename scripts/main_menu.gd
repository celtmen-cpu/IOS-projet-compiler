extends Control
@onready var jeu = preload("res://scenes/jeu.tscn")
@onready var options = preload("res://scenes/Option.tscn")

func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_packed(jeu)


func _on_button_option_pressed() -> void:
	get_tree().change_scene_to_packed(options)


func _on_button_quit_pressed() -> void:
	get_tree().quit()
