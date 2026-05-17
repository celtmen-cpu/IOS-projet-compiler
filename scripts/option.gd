extends Control

@onready var jeu = preload("res://scenes/jeu.tscn")

func _on_button_jeu_pressed() -> void:
	get_tree().change_scene_to_packed(jeu)


func _on_button_main_menu_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
