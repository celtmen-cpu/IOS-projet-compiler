extends Node2D

@export var chunk_scene: PackedScene
@export var obstacle_scene: PackedScene
@export var player: CharacterBody2D

@export var spawn_ahead := 1920
@export var speed_increase := 20.0
@export var obstacle_chance := 0.3

@onready var score_label = get_node("UI/HUD/VBoxContainer/ScoreLabel")
@onready var best_score_label = get_node("UI/HUD/VBoxContainer/BestScoreLabel")

var next_position := Vector2.ZERO
var run_speed := 200.0

func _ready():
	randomize()

	for i in range(10):
		spawn_chunk()

func _process(delta):
	if player == null:
		return

	# vitesse progressive
	run_speed += speed_increase * delta

	# déplacement joueur (runner)
	player.velocity.x = run_speed
	player.move_and_slide()

	# spawn infini
	if player.global_position.x + spawn_ahead > next_position.x:
		spawn_chunk()
		
	GameState.score = int(player.global_position.x / 10)
	score_label.text = "Score : " + str(GameState.score)
	
	best_score_label.text = "Record : " + str(GameState.best_score)

func spawn_chunk():
	var use_obstacle = randf() < obstacle_chance

	var chunk: Node2D

	if use_obstacle and obstacle_scene != null:
		chunk = obstacle_scene.instantiate()
	else:
		chunk = chunk_scene.instantiate()

	add_child(chunk)

	chunk.global_position = next_position

	var end = chunk.get_node("EndPoint")
	next_position = end.global_position

func _on_button_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
