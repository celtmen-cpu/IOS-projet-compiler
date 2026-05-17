extends TextureButton

@export var player: CharacterBody2D

func _button_down():
	player.button_hold = true
	player.jump()

func _button_up():
	player.button_hold = false
