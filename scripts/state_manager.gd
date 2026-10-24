class_name PlatformerStateManager
extends RefCounted

signal state_changed(new_state: String)
signal score_changed(new_score: int)
signal coins_changed(new_coins: int)

enum State { READY, PLAYING, PAUSED, FALLEN, VICTORY }

var current_state: State = State.READY
var score: int = 0
var coins: int = 0
var highscore: int = 0

const SAVE_PATH: String = "user://platformer_score.save"

func _init() -> void:
	load_highscore()

func get_state_string() -> String:
	match current_state:
		State.READY: return "READY"
		State.PLAYING: return "PLAYING"
		State.PAUSED: return "PAUSED"
		State.FALLEN: return "FALLEN"
		State.VICTORY: return "VICTORY"
		_: return "UNKNOWN"

func start() -> void:
	if current_state == State.READY or current_state == State.FALLEN or current_state == State.VICTORY:
		current_state = State.PLAYING
		state_changed.emit("PLAYING")

func pause() -> void:
	if current_state == State.PLAYING:
		current_state = State.PAUSED
		state_changed.emit("PAUSED")

func resume() -> void:
	if current_state == State.PAUSED:
		current_state = State.PLAYING
		state_changed.emit("PLAYING")

func toggle_pause() -> void:
	if current_state == State.PLAYING:
		pause()
	elif current_state == State.PAUSED:
		resume()

func fall() -> void:
	if current_state == State.PLAYING:
		current_state = State.FALLEN
		save_highscore()
		state_changed.emit("FALLEN")

func win() -> void:
	if current_state == State.PLAYING:
		current_state = State.VICTORY
		score += 1000
		save_highscore()
		score_changed.emit(score)
		state_changed.emit("VICTORY")

func add_coin() -> void:
	coins += 1
	score += 100
	if score > highscore:
		highscore = score
	coins_changed.emit(coins)
	score_changed.emit(score)

func add_score(amount: int) -> void:
	score += amount
	if score > highscore:
		highscore = score
	score_changed.emit(score)

func add_progress_distance(dist_score: int) -> void:
	if current_state == State.PLAYING:
		if dist_score > score:
			score = dist_score
			if score > highscore:
				highscore = score
			score_changed.emit(score)

func reset() -> void:
	current_state = State.READY
	score = 0
	coins = 0
	score_changed.emit(score)
	coins_changed.emit(coins)
	state_changed.emit("READY")

func load_highscore() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			highscore = file.get_32()
			file.close()

func save_highscore() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(highscore)
		file.close()
