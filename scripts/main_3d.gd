class_name MainScene3D
extends Node3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerStateManager = preload("res://scripts/state_manager.gd")
const TileMapLoader3D = preload("res://scripts/tilemap_loader_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")
const PlatformerFireball3D = preload("res://scripts/fireball_3d.gd")
const PlatformerControls = preload("res://scripts/controls.gd")
const PlatformerLevelManager = preload("res://scripts/level_manager.gd")

@onready var tilemap_loader: TileMapLoader3D = $TileMapLoader3D
@onready var player: PlatformerPlayer3D = $Player3D
@onready var camera: Camera3D = $Camera3D

var btn_controls_start: Button
var btn_controls_pause: Button
var btn_set_start: Button
var btn_level_start: Button
var btn_set_pause: Button
var btn_level_pause: Button
var lbl_banner: Label

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
	tilemap_loader.powerup_spawned.connect(_on_powerup_spawned)
	tilemap_loader.brick_shattered.connect(_on_brick_shattered)
	player.block_hit_from_below.connect(_on_block_hit)
	player.fireball_requested.connect(_on_fireball_requested)

	PlatformerLevelManager.init_catalog()
	PlatformerLevelManager.apply_saved_set()

	load_level(0)
	camera.current = true
	camera.make_current()
	_bind_ui_buttons()
	_setup_controls_ui()
	_update_hud()
	_update_level_ui_buttons()
	_show_overlay(overlay_start)

func _setup_controls_ui() -> void:
	PlatformerControls.init_default()

	var start_card: Panel = $CanvasLayer/StartOverlay/Card
	if start_card:
		start_card.offset_top = -225.0
		start_card.offset_bottom = 225.0
		var start_inst: Label = start_card.get_node_or_null("Instructions")
		if start_inst:
			start_inst.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			start_inst.text = PlatformerControls.get_scheme_instructions()
			start_inst.offset_top = -65.0
			start_inst.offset_bottom = 25.0

		btn_set_start = Button.new()
		btn_set_start.name = "LevelSetButton"
		btn_set_start.anchors_preset = Control.PRESET_CENTER_BOTTOM
		btn_set_start.anchor_left = 0.5
		btn_set_start.anchor_top = 1.0
		btn_set_start.anchor_right = 0.5
		btn_set_start.anchor_bottom = 1.0
		btn_set_start.offset_left = -200.0
		btn_set_start.offset_top = -180.0
		btn_set_start.offset_right = 200.0
		btn_set_start.offset_bottom = -148.0
		btn_set_start.pressed.connect(cycle_level_set)
		start_card.add_child(btn_set_start)

		btn_level_start = Button.new()
		btn_level_start.name = "LevelSelectButton"
		btn_level_start.anchors_preset = Control.PRESET_CENTER_BOTTOM
		btn_level_start.anchor_left = 0.5
		btn_level_start.anchor_top = 1.0
		btn_level_start.anchor_right = 0.5
		btn_level_start.anchor_bottom = 1.0
		btn_level_start.offset_left = -200.0
		btn_level_start.offset_top = -142.0
		btn_level_start.offset_right = 200.0
		btn_level_start.offset_bottom = -110.0
		btn_level_start.pressed.connect(cycle_level_select)
		start_card.add_child(btn_level_start)

		btn_controls_start = Button.new()
		btn_controls_start.name = "ControlsButton"
		btn_controls_start.anchors_preset = Control.PRESET_CENTER_BOTTOM
		btn_controls_start.anchor_left = 0.5
		btn_controls_start.anchor_top = 1.0
		btn_controls_start.anchor_right = 0.5
		btn_controls_start.anchor_bottom = 1.0
		btn_controls_start.offset_left = -200.0
		btn_controls_start.offset_top = -104.0
		btn_controls_start.offset_right = 200.0
		btn_controls_start.offset_bottom = -72.0
		btn_controls_start.text = "🎮 " + PlatformerControls.get_scheme_name()
		btn_controls_start.pressed.connect(cycle_controls)
		start_card.add_child(btn_controls_start)

		var start_btn: Button = start_card.get_node_or_null("StartButton")
		if start_btn:
			start_btn.offset_top = -64.0
			start_btn.offset_bottom = -20.0

	var pause_card: Panel = $CanvasLayer/PauseOverlay/Card
	if pause_card:
		pause_card.offset_top = -180.0
		pause_card.offset_bottom = 180.0

		btn_set_pause = Button.new()
		btn_set_pause.name = "LevelSetButton"
		btn_set_pause.anchors_preset = Control.PRESET_CENTER_BOTTOM
		btn_set_pause.anchor_left = 0.5
		btn_set_pause.anchor_top = 1.0
		btn_set_pause.anchor_right = 0.5
		btn_set_pause.anchor_bottom = 1.0
		btn_set_pause.offset_left = -170.0
		btn_set_pause.offset_top = -170.0
		btn_set_pause.offset_right = 170.0
		btn_set_pause.offset_bottom = -140.0
		btn_set_pause.pressed.connect(cycle_level_set)
		pause_card.add_child(btn_set_pause)

		btn_level_pause = Button.new()
		btn_level_pause.name = "LevelSelectButton"
		btn_level_pause.anchors_preset = Control.PRESET_CENTER_BOTTOM
		btn_level_pause.anchor_left = 0.5
		btn_level_pause.anchor_top = 1.0
		btn_level_pause.anchor_right = 0.5
		btn_level_pause.anchor_bottom = 1.0
		btn_level_pause.offset_left = -170.0
		btn_level_pause.offset_top = -134.0
		btn_level_pause.offset_right = 170.0
		btn_level_pause.offset_bottom = -104.0
		btn_level_pause.pressed.connect(cycle_level_select)
		pause_card.add_child(btn_level_pause)

		btn_controls_pause = Button.new()
		btn_controls_pause.name = "ControlsButton"
		btn_controls_pause.anchors_preset = Control.PRESET_CENTER_BOTTOM
		btn_controls_pause.anchor_left = 0.5
		btn_controls_pause.anchor_top = 1.0
		btn_controls_pause.anchor_right = 0.5
		btn_controls_pause.anchor_bottom = 1.0
		btn_controls_pause.offset_left = -170.0
		btn_controls_pause.offset_top = -98.0
		btn_controls_pause.offset_right = 170.0
		btn_controls_pause.offset_bottom = -68.0
		btn_controls_pause.text = "🎮 " + PlatformerControls.get_scheme_name()
		btn_controls_pause.pressed.connect(cycle_controls)
		pause_card.add_child(btn_controls_pause)

	lbl_banner = Label.new()
	lbl_banner.name = "ControlsBanner"
	lbl_banner.anchors_preset = Control.PRESET_CENTER_TOP
	lbl_banner.anchor_left = 0.5
	lbl_banner.anchor_right = 0.5
	lbl_banner.offset_left = -260.0
	lbl_banner.offset_top = 65.0
	lbl_banner.offset_right = 260.0
	lbl_banner.offset_bottom = 105.0
	lbl_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_banner.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.1, 0.16, 0.92)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	lbl_banner.add_theme_stylebox_override("panel", sb)
	lbl_banner.add_theme_font_size_override("font_size", 16)
	lbl_banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	$CanvasLayer.add_child(lbl_banner)

func cycle_controls() -> void:
	var new_scheme := PlatformerControls.cycle_scheme()
	var txt := "🎮 " + PlatformerControls.get_scheme_name(new_scheme)
	if btn_controls_start:
		btn_controls_start.text = txt
	if btn_controls_pause:
		btn_controls_pause.text = txt
	var start_inst: Label = $CanvasLayer/StartOverlay/Card.get_node_or_null("Instructions")
	if start_inst:
		start_inst.text = PlatformerControls.get_scheme_instructions(new_scheme)
	_show_banner("STEUERUNG: " + PlatformerControls.get_scheme_name(new_scheme))

func cycle_level_set() -> void:
	var new_set := PlatformerLevelManager.cycle_set()
	current_level_index = 0
	load_level(current_level_index)
	_update_level_ui_buttons()
	_show_banner("LEVEL-SATZ: " + new_set.get("name", ""))

func cycle_level_select() -> void:
	current_level_index = PlatformerLevelManager.cycle_level(current_level_index)
	load_level(current_level_index)
	_update_level_ui_buttons()
	_show_banner("LEVEL: " + PlatformerLevelManager.get_level_display_name(current_level_index))

func _show_banner(text: String) -> void:
	if lbl_banner and is_inside_tree():
		lbl_banner.visible = true
		lbl_banner.text = text
		var tw := create_tween()
		if tw:
			tw.tween_interval(1.5)
			tw.tween_callback(func():
				if is_instance_valid(lbl_banner):
					lbl_banner.visible = false
			)

func _update_level_ui_buttons() -> void:
	var set_txt := "📦 Satz: " + PlatformerLevelManager.get_current_set_name()
	var lvl_txt := "🗺️ Level: " + PlatformerLevelManager.get_level_display_name(current_level_index)
	if btn_set_start:
		btn_set_start.text = set_txt
	if btn_set_pause:
		btn_set_pause.text = set_txt
	if btn_level_start:
		btn_level_start.text = lvl_txt
	if btn_level_pause:
		btn_level_pause.text = lvl_txt

func load_level(index: int) -> void:
	var count := PlatformerLevelManager.get_level_count()
	if count <= 0:
		count = LEVELS.size()
	current_level_index = clampi(index, 0, count - 1)
	var path: String = PlatformerLevelManager.get_level_path(current_level_index)
	if path.is_empty() and current_level_index < LEVELS.size():
		path = LEVELS[current_level_index]
	tilemap_loader.load_level_from_file(path)
	player.reset_position()
	camera.position.x = PlatformerConfig3D.START_X + 4.0
	camera.position.y = PlatformerConfig3D.CAMERA_HEIGHT_OFFSET

	# 3D Kanonen verbinden
	for cannon in tilemap_loader.cannons:
		if not cannon.bullet_fired.is_connected(_on_cannon_bullet_fired):
			cannon.bullet_fired.connect(_on_cannon_bullet_fired)

	_update_hud()
	_update_level_ui_buttons()

func _bind_ui_buttons() -> void:
	$CanvasLayer/StartOverlay/Card/StartButton.pressed.connect(start_game)
	$CanvasLayer/PauseOverlay/Card/ResumeButton.pressed.connect(toggle_pause)
	$CanvasLayer/GameOverOverlay/Card/RestartButton.pressed.connect(restart_game)
	victory_btn.pressed.connect(on_victory_action)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("cycle_controls"):
		cycle_controls()
	if Input.is_action_just_pressed("cycle_level_set"):
		cycle_level_set()
	if Input.is_action_just_pressed("cycle_level"):
		cycle_level_select()

	if state_manager.current_state == PlatformerStateManager.State.READY:
		if Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_ENTER):
			start_game()

	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	if Input.is_action_just_pressed("restart"):
		restart_game()

	if state_manager.current_state == PlatformerStateManager.State.PLAYING:
		var in_left := Input.is_action_pressed("move_left")
		var in_right := Input.is_action_pressed("move_right")
		var in_jump_pressed := Input.is_action_just_pressed("jump")
		var in_jump_held := Input.is_action_pressed("jump")
		var in_shoot := Input.is_action_just_pressed("shoot")

		player.update_kinematics(delta, in_left, in_right, in_jump_pressed, in_jump_held, in_shoot)

		# Kanonen aktualisieren
		for cannon in tilemap_loader.cannons:
			if is_instance_valid(cannon):
				cannon.update_cannon(delta, player)

		# 3D Gegner aktualisieren
		for enemy in tilemap_loader.enemies:
			if is_instance_valid(enemy):
				if enemy.has_method("update_enemy"):
					enemy.update_enemy(delta, player)

		# 3D Feuerbälle aktualisieren
		for fb in get_tree().get_nodes_in_group("fireballs_3d"):
			if is_instance_valid(fb) and fb.has_method("update_fireball"):
				fb.update_fireball(delta)

		# 3D Power-Ups aktualisieren
		for powerup in tilemap_loader.powerups:
			if is_instance_valid(powerup):
				if powerup.has_method("update_mushroom"):
					powerup.update_mushroom(delta)
				elif powerup.has_method("update_star"):
					powerup.update_star(delta)

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
	var count := PlatformerLevelManager.get_level_count()
	if count <= 0:
		count = LEVELS.size()
	if current_level_index < count - 1:
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

func _on_powerup_spawned(powerup: Node) -> void:
	if powerup.has_signal("collected"):
		powerup.connect("collected", func(_p): state_manager.add_score(1000))

func _on_fireball_requested(pos: Vector3, dir: float) -> void:
	var fb := PlatformerFireball3D.new()
	fb.position = pos
	fb.direction = dir
	fb.hit_enemy.connect(func(_e): state_manager.add_score(200))
	tilemap_loader.add_child(fb)

func _on_cannon_bullet_fired(bullet: Node3D) -> void:
	tilemap_loader.enemies.append(bullet)
	tilemap_loader.add_child(bullet)
	_on_enemy_spawned(bullet)

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
			var count := PlatformerLevelManager.get_level_count()
			if count <= 0:
				count = LEVELS.size()
			if current_level_index < count - 1:
				if victory_title:
					victory_title.text = "%s GESCHAFFT!" % PlatformerLevelManager.get_level_display_name(current_level_index).to_upper()
				if victory_score:
					victory_score.text = "SCORE: " + str(state_manager.score)
				if victory_btn:
					victory_btn.text = "NÄCHSTES LEVEL (%d/%d)" % [current_level_index + 2, count]
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
		lbl_world.text = "%s (3D)" % PlatformerLevelManager.get_level_display_name(current_level_index)

func _hide_all_overlays() -> void:
	overlay_start.visible = false
	overlay_pause.visible = false
	overlay_gameover.visible = false
	overlay_victory.visible = false

func _show_overlay(overlay: Control) -> void:
	_hide_all_overlays()
	overlay.visible = true
