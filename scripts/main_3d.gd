class_name MainScene3D
extends Node3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerStateManager = preload("res://scripts/state_manager.gd")
const TileMapLoader3D = preload("res://scripts/tilemap_loader_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")

@onready var tilemap_loader: TileMapLoader3D = $TileMapLoader3D
@onready var player: PlatformerPlayer3D = $Player3D
@onready var camera: Camera3D = $Camera3D

# UI
@onready var lbl_score: Label = $CanvasLayer/HUD/ScoreContainer/ScoreValue
@onready var lbl_coins: Label = $CanvasLayer/HUD/CoinsContainer/CoinsValue
@onready var lbl_highscore: Label = $CanvasLayer/HUD/TopContainer/TopValue

@onready var overlay_start: Control = $CanvasLayer/StartOverlay
@onready var overlay_pause: Control = $CanvasLayer/PauseOverlay
@onready var overlay_gameover: Control = $CanvasLayer/GameOverOverlay
@onready var overlay_victory: Control = $CanvasLayer/VictoryOverlay

@onready var gameover_score: Label = $CanvasLayer/GameOverOverlay/Card/ScoreLabel
@onready var lbl_world: Label = $CanvasLayer/HUD/WorldContainer/Label2
@onready var victory_title: Label = $CanvasLayer/VictoryOverlay/Card/Title
@onready var victory_btn: Button = $CanvasLayer/VictoryOverlay/Card/RestartButton

const LEVELS: Array[String] = [
	"res://levels/level-1.txt",
	"res://levels/level-2.txt",
	"res://levels/level-3.txt",
	"res://levels/level-4.txt",
	"res://levels/level-5.txt",
]
var current_level_index: int = 0

var state_manager: PlatformerStateManager

func _ready() -> void:
	state_manager = PlatformerStateManager.new()
	state_manager.score_changed.connect(_on_score_changed)
	state_manager.coins_changed.connect(_on_coins_changed)
	state_manager.state_changed.connect(_on_state_changed)

	tilemap_loader.coin_collected.connect(_on_coin_collected)
	tilemap_loader.goal_reached.connect(_on_goal_reached)
	tilemap_loader.enemy_spawned.connect(_on_enemy_spawned)
	tilemap_loader.mushroom_spawned.connect(_on_mushroom_spawned)
	tilemap_loader.brick_shattered.connect(_on_brick_shattered)
	player.block_hit_from_below.connect(_on_block_hit)

	load_level(0)
	_bind_ui_buttons()
	_update_hud()
	_show_overlay(overlay_start)

func load_level(index: int) -> void:
	current_level_index = clamp(index, 0, LEVELS.size() - 1)
	var path: String = LEVELS[current_level_index]
	tilemap_loader.load_level_from_file(path)
	player.reset_position()
	camera.position.x = PlatformerConfig3D.START_X + 4.0
	camera.position.y = PlatformerConfig3D.CAMERA_HEIGHT_OFFSET
	_update_hud()

func _bind_ui_buttons() -> void:
	$CanvasLayer/StartOverlay/Card/StartButton.pressed.connect(start_game)
	$CanvasLayer/PauseOverlay/Card/ResumeButton.pressed.connect(toggle_pause)
	$CanvasLayer/GameOverOverlay/Card/RestartButton.pressed.connect(restart_game)
	victory_btn.pressed.connect(on_victory_action)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	if Input.is_action_just_pressed("restart"):
		restart_game()

	if state_manager.current_state == PlatformerStateManager.State.PLAYING:
		var in_left := Input.is_action_pressed("move_left")
		var in_right := Input.is_action_pressed("move_right")
		var in_jump_pressed := Input.is_action_just_pressed("jump")
		var in_jump_held := Input.is_action_pressed("jump")

		player.update_kinematics(delta, in_left, in_right, in_jump_pressed, in_jump_held)

		# 3D Gegner & Pilze aktualisieren
		for enemy in tilemap_loader.enemies:
			if is_instance_valid(enemy):
				enemy.update_enemy(delta)

		for powerup in tilemap_loader.powerups:
			if is_instance_valid(powerup):
				powerup.update_mushroom(delta)

		# Fortschrittspunkte (Distanz nach rechts)
		var dist_score := int(player.position.x * 10.0)
		state_manager.add_progress_distance(dist_score)

		# Absturz in Abgrund
		if player.position.y < PlatformerConfig3D.DEATH_Y:
			state_manager.fall()

		# Frontale 3D-Kamera mit X- und sanfter Y-Verfolgung
		var target_x: float = player.position.x + 1.5
		var ideal_y: float = maxf(PlatformerConfig3D.CAMERA_HEIGHT_OFFSET, player.position.y * 0.4 + PlatformerConfig3D.CAMERA_HEIGHT_OFFSET)
		camera.position.x = lerp(camera.position.x, target_x, PlatformerConfig3D.CAMERA_LERP_SPEED * delta)
		camera.position.y = lerp(camera.position.y, ideal_y, PlatformerConfig3D.CAMERA_LERP_SPEED * 0.5 * delta)

func start_game() -> void:
	_hide_all_overlays()
	state_manager.start()

func toggle_pause() -> void:
	state_manager.toggle_pause()

func restart_game() -> void:
	_hide_all_overlays()
	load_level(current_level_index)
	state_manager.reset()
	state_manager.start()

func on_victory_action() -> void:
	if current_level_index < LEVELS.size() - 1:
		current_level_index += 1
		load_level(current_level_index)
		_hide_all_overlays()
		state_manager.start()
	else:
		current_level_index = 0
		load_level(current_level_index)
		restart_game()

func _on_enemy_spawned(enemy: Node) -> void:
	if enemy.has_signal("stomped"):
		enemy.connect("stomped", func(_e): state_manager.add_score(200))
	if enemy.has_signal("player_hurt"):
		enemy.connect("player_hurt", func(killed: bool): if killed: state_manager.fall())

func _on_mushroom_spawned(mushroom: Node) -> void:
	if mushroom.has_signal("collected"):
		mushroom.connect("collected", func(_m): state_manager.add_score(1000))

func _on_brick_shattered(_pos: Vector3) -> void:
	state_manager.add_score(50)

func _on_block_hit(block: StaticBody3D, is_big: bool = false) -> void:
	tilemap_loader.hit_block(block, is_big)

func _on_coin_collected(_col: int, _row: int) -> void:
	state_manager.add_coin()

func _on_goal_reached() -> void:
	state_manager.win()

func _on_score_changed(_score: int) -> void:
	_update_hud()

func _on_coins_changed(_coins: int) -> void:
	_update_hud()

func _on_state_changed(new_state: String) -> void:
	match new_state:
		"PLAYING":
			_hide_all_overlays()
		"PAUSED":
			_show_overlay(overlay_pause)
		"FALLEN":
			gameover_score.text = "SCORE: " + str(state_manager.score)
			_show_overlay(overlay_gameover)
		"VICTORY":
			var victory_score: Label = $CanvasLayer/VictoryOverlay/Card/ScoreLabel
			if current_level_index < LEVELS.size() - 1:
				if victory_title:
					victory_title.text = "LEVEL %d GESCHAFFT!" % (current_level_index + 1)
				if victory_score:
					victory_score.text = "SCORE: " + str(state_manager.score)
				if victory_btn:
					victory_btn.text = "NÄCHSTES LEVEL (%d/%d)" % [current_level_index + 2, LEVELS.size()]
			else:
				if victory_title:
					victory_title.text = "KAMPAGNE GEMEISTERT!"
				if victory_score:
					victory_score.text = "GESAMTERGEBNIS: " + str(state_manager.score)
				if victory_btn:
					victory_btn.text = "KAMPAGNE NEUSTARTEN"
			_show_overlay(overlay_victory)
		"READY":
			_show_overlay(overlay_start)

func _update_hud() -> void:
	if lbl_score:
		lbl_score.text = "%06d" % state_manager.score
	if lbl_coins:
		lbl_coins.text = "×%02d" % state_manager.coins
	if lbl_highscore:
		lbl_highscore.text = "%06d" % state_manager.highscore
	if lbl_world:
		lbl_world.text = "1-%d (3D)" % (current_level_index + 1)

func _hide_all_overlays() -> void:
	overlay_start.visible = false
	overlay_pause.visible = false
	overlay_gameover.visible = false
	overlay_victory.visible = false

func _show_overlay(overlay: Control) -> void:
	_hide_all_overlays()
	overlay.visible = true
