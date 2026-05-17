extends Node

var score := 0
var best_score := 0

const SAVE_PATH := "user://save.dat"
func add_score(value: int):
	score += value


func reset_score():
	score = 0


func load_best_score():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		best_score = file.get_var()
		file.close()


func save_best_score():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(best_score)
	file.close()


func update_best_score():
	if score > best_score:
		best_score = score
		save_best_score()
