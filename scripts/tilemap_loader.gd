class_name TileMapLoader
extends Node2D

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerEnemy = preload("res://scripts/enemy.gd")
const PlatformerKoopa = preload("res://scripts/enemy_koopa.gd")
const PlatformerBulletBill = preload("res://scripts/bullet_bill.gd")
const PlatformerCannon = preload("res://scripts/cannon.gd")
const PlatformerPiranhaPlant = preload("res://scripts/piranha_plant.gd")

const PlatformerMushroom = preload("res://scripts/mushroom.gd")
const PlatformerFlower = preload("res://scripts/flower.gd")
const PlatformerStar = preload("res://scripts/star.gd")

signal coin_collected(col: int, row: int)
signal goal_reached
signal enemy_spawned(enemy: Node2D)
signal powerup_spawned(powerup: Node2D)
signal mushroom_spawned(mushroom: PlatformerMushroom)
signal brick_shattered(pos: Vector2)

var level_width_cols: int = 0
var level_height_rows: int = 0
var flagpole_col: int = 198
var question_blocks: Dictionary = {}
var enemies: Array[Node2D] = []
var powerups: Array[Node2D] = []
var cannons: Array[PlatformerCannon] = []

func clear() -> void:
	for child in get_children():
		child.queue_free()
	question_blocks.clear()
	enemies.clear()
	powerups.clear()
	cannons.clear()
	level_width_cols = 0
	level_height_rows = 0


func load_level_from_file(path: String) -> bool:
	clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Could not open level file: " + path)
		return false

	var content := file.get_as_text()
	file.close()

	var raw_lines := content.strip_edges().split("\n")
	var lines: Array[String] = []
	for l in raw_lines:
		var trimmed := l.strip_edges()
		if trimmed.length() > 0:
			lines.append(trimmed)

	level_height_rows = lines.size()
	level_width_cols = 0
	for l in lines:
		if l.length() > level_width_cols:
			level_width_cols = l.length()

	var ts := PlatformerConfig.TILE_SIZE
	var has_flagpole: bool = false

	for row in range(level_height_rows):
		var line := lines[row]
		for col in range(line.length()):
			var char := line[col]
			if char == "F" or char == "|":
				has_flagpole = true
			var pos := Vector2(col * ts, row * ts)
			_create_tile(char, col, row, pos, ts)

	if not has_flagpole and level_width_cols > 0:
		var goal_col: int = maxi(5, level_width_cols - 4)
		flagpole_col = goal_col
		var pos_x := float(goal_col) * ts
		for h in range(5, 14):
			var pos_y := float(h) * ts
			_create_flagpole(Vector2(pos_x, pos_y), ts)

	return true

func _create_tile(char: String, col: int, row: int, pos: Vector2, ts: float) -> void:
	match char:
		"X", "x":
			_create_solid_block(pos, ts, Color("#d97334"), "Ground")
		"S", "s":
			_create_brick_block(pos, ts, col, row)
		"?", "Q", "q":
			_create_question_block(pos, ts, col, row)
		"<", ">", "[", "]":
			_create_solid_block(pos, ts, Color("#10b981"), "Pipe")
		"E", "e":
			_create_enemy(pos, ts)
		"K", "k":
			_create_koopa(pos, ts)
		"B":
			_create_cannon(pos, ts, true)
		"b":
			_create_cannon(pos, ts, false)
		"P", "p", "y":
			_create_piranha(pos, ts)
		"M", "m":
			_create_mushroom(pos, ts)
		"f":
			_create_flower(pos, ts)
		"*":
			_create_star(pos, ts)
		"o", "O":
			_create_coin(pos, ts, col, row)
		"F", "|":
			flagpole_col = col
			_create_flagpole(pos, ts)

func _create_solid_block(pos: Vector2, ts: float, color: Color, name_prefix: String) -> void:
	var body := StaticBody2D.new()
	body.name = name_prefix + "_" + str(pos.x) + "_" + str(pos.y)
	body.position = pos + Vector2(ts / 2.0, ts / 2.0)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ts, ts)
	shape.shape = rect
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.color = color
	visual.size = Vector2(ts - 1.0, ts - 1.0)
	visual.position = Vector2(-ts / 2.0, -ts / 2.0)
	body.add_child(visual)

	add_child(body)

func _create_brick_block(pos: Vector2, ts: float, col: int, row: int) -> void:
	var body := StaticBody2D.new()
	body.name = "Brick_" + str(col) + "_" + str(row)
	body.position = pos + Vector2(ts / 2.0, ts / 2.0)
	body.add_to_group("brick_blocks")
	body.set_meta("col", col)
	body.set_meta("row", row)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ts, ts)
	shape.shape = rect
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.color = Color("#bf4026")
	visual.size = Vector2(ts - 1.0, ts - 1.0)
	visual.position = Vector2(-ts / 2.0, -ts / 2.0)
	body.add_child(visual)

	add_child(body)

func _create_question_block(pos: Vector2, ts: float, col: int, row: int) -> void:
	var body := StaticBody2D.new()
	body.name = "QuestionBlock_" + str(col) + "_" + str(row)
	body.position = pos + Vector2(ts / 2.0, ts / 2.0)
	body.add_to_group("question_blocks")
	body.set_meta("col", col)
	body.set_meta("row", row)
	body.set_meta("hit", false)
	# Erste Fragezeichenkachel oder jede 4. hat einen Pilz
	var has_mushroom: bool = (question_blocks.is_empty() or col % 4 == 0)
	body.set_meta("has_mushroom", has_mushroom)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ts, ts)
	shape.shape = rect
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.color = Color("#f59e0b") # Gold
	visual.size = Vector2(ts - 1.0, ts - 1.0)
	visual.position = Vector2(-ts / 2.0, -ts / 2.0)
	body.add_child(visual)

	question_blocks[Vector2i(col, row)] = body
	add_child(body)


func _create_enemy(pos: Vector2, ts: float) -> void:
	var enemy := PlatformerEnemy.new()
	enemy.position = pos + Vector2(ts / 2.0, ts / 2.0)
	enemies.append(enemy)
	add_child(enemy)
	enemy_spawned.emit(enemy)

func _create_koopa(pos: Vector2, ts: float) -> void:
	var koopa := PlatformerKoopa.new()
	koopa.position = pos + Vector2(ts / 2.0, ts / 2.0)
	enemies.append(koopa)
	add_child(koopa)
	enemy_spawned.emit(koopa)

func _create_cannon(pos: Vector2, ts: float, is_top: bool) -> void:
	var cannon := PlatformerCannon.new()
	cannon.is_top = is_top
	cannon.position = pos + Vector2(ts / 2.0, ts / 2.0)
	cannons.append(cannon)
	add_child(cannon)

func _create_piranha(pos: Vector2, ts: float) -> void:
	var piranha := PlatformerPiranhaPlant.new()
	piranha.position = pos + Vector2(ts / 2.0, ts)
	enemies.append(piranha)
	add_child(piranha)
	enemy_spawned.emit(piranha)

func _create_mushroom(pos: Vector2, ts: float) -> void:
	var mushroom := PlatformerMushroom.new()
	mushroom.position = pos + Vector2(ts / 2.0, ts / 2.0)
	powerups.append(mushroom)
	add_child(mushroom)
	powerup_spawned.emit(mushroom)

func _create_flower(pos: Vector2, ts: float) -> void:
	var flower := PlatformerFlower.new()
	flower.position = pos + Vector2(ts / 2.0, ts / 2.0)
	powerups.append(flower)
	add_child(flower)
	powerup_spawned.emit(flower)

func _create_star(pos: Vector2, ts: float) -> void:
	var star := PlatformerStar.new()
	star.position = pos + Vector2(ts / 2.0, ts / 2.0)
	powerups.append(star)
	add_child(star)
	powerup_spawned.emit(star)

func _create_coin(pos: Vector2, ts: float, col: int, row: int) -> void:
	var area := Area2D.new()
	area.name = "Coin_%d_%d" % [col, row]
	area.position = pos + Vector2(ts / 2.0, ts / 2.0)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = ts * 0.3
	shape.shape = circle
	area.add_child(shape)

	var visual := ColorRect.new()
	visual.color = Color("#fbbf24") # Warmes Gold
	visual.size = Vector2(ts * 0.45, ts * 0.6)
	visual.position = Vector2(-ts * 0.225, -ts * 0.3)
	area.add_child(visual)

	area.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"):
			coin_collected.emit(col, row)
			area.queue_free()
	)
	add_child(area)

func _create_flagpole(pos: Vector2, ts: float) -> void:
	var area := Area2D.new()
	area.name = "GoalFlag"
	area.position = pos + Vector2(ts / 2.0, ts / 2.0)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ts * 0.4, ts)
	shape.shape = rect
	area.add_child(shape)

	var visual := ColorRect.new()
	visual.color = Color("#fef08a")
	visual.size = Vector2(ts * 0.3, ts)
	visual.position = Vector2(-ts * 0.15, -ts / 2.0)
	area.add_child(visual)

	area.body_entered.connect(_on_flag_body_entered)
	add_child(area)

func _on_flag_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		goal_reached.emit()

func hit_block(block: StaticBody2D, is_big: bool = false) -> void:
	if not block:
		return

	if block.is_in_group("brick_blocks"):
		if is_big:
			# Ziegel zerbricht!
			brick_shattered.emit(block.position)
			var tween := create_tween()
			tween.tween_property(block, "scale", Vector2.ZERO, 0.08)
			tween.tween_callback(block.queue_free)
		else:
			# Bouncen ohne Bruch
			var tween := create_tween()
			var orig_y := block.position.y
			tween.tween_property(block, "position:y", orig_y - 8.0, 0.06)
			tween.tween_property(block, "position:y", orig_y, 0.06)
		return

	if not block.is_in_group("question_blocks") or block.get_meta("hit", false):
		return

	block.set_meta("hit", true)
	var col: int = block.get_meta("col", -1)
	var row: int = block.get_meta("row", -1)

	var visual: ColorRect = block.get_node_or_null("Visual")
	if visual:
		visual.color = Color("#64748b") # Spent block slate-gray

	# Sanfte Bounce-Animation
	var tween := create_tween()
	var orig_y := block.position.y
	tween.tween_property(block, "position:y", orig_y - 10.0, 0.08)
	tween.tween_property(block, "position:y", orig_y, 0.08)

	var has_powerup: bool = (question_blocks.size() == 1 or col % 4 == 0)
	if has_powerup:
		if col % 8 == 0:
			# Super-Stern
			var star := PlatformerStar.new()
			star.position = block.position - Vector2(0.0, PlatformerConfig.TILE_SIZE * 0.8)
			powerups.append(star)
			add_child(star)
			powerup_spawned.emit(star)
		elif is_big:
			# Feuerblume
			var flower := PlatformerFlower.new()
			flower.position = block.position - Vector2(0.0, PlatformerConfig.TILE_SIZE * 0.8)
			powerups.append(flower)
			add_child(flower)
			powerup_spawned.emit(flower)
		else:
			# Super-Pilz
			var mushroom := PlatformerMushroom.new()
			mushroom.position = block.position - Vector2(0.0, PlatformerConfig.TILE_SIZE * 0.8)
			powerups.append(mushroom)
			add_child(mushroom)
			powerup_spawned.emit(mushroom)
	else:
		coin_collected.emit(col, row)
