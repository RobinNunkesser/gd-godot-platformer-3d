class_name TileMapLoader3D
extends Node3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")

const PlatformerEnemy3D = preload("res://scripts/enemy_3d.gd")
const PlatformerKoopa3D = preload("res://scripts/enemy_koopa_3d.gd")
const PlatformerBulletBill3D = preload("res://scripts/bullet_bill_3d.gd")
const PlatformerCannon3D = preload("res://scripts/cannon_3d.gd")
const PlatformerPiranhaPlant3D = preload("res://scripts/piranha_plant_3d.gd")

const PlatformerMushroom3D = preload("res://scripts/mushroom_3d.gd")
const PlatformerFlower3D = preload("res://scripts/flower_3d.gd")
const PlatformerStar3D = preload("res://scripts/star_3d.gd")

const TEX_HULL: Texture2D = preload("res://assets/textures/scifi/scifi_hull_plating.jpg")
const TEX_BRICK: Texture2D = preload("res://assets/textures/scifi/scifi_cargo_brick.jpg")
const TEX_QUESTION: Texture2D = preload("res://assets/textures/scifi/scifi_holo_cube.jpg")
const TEX_PIPE: Texture2D = preload("res://assets/textures/scifi/scifi_pipe_conduit.jpg")

signal coin_collected(col: int, row: int)
signal goal_reached
signal enemy_spawned(enemy: Node3D)
signal powerup_spawned(powerup: Node3D)
signal mushroom_spawned(mushroom: PlatformerMushroom3D)
signal brick_shattered(pos: Vector3)

var level_width_cols: int = 0
var level_height_rows: int = 0
var flagpole_col: int = 198
var question_blocks: Dictionary = {}
var enemies: Array[Node3D] = []
var powerups: Array[Node3D] = []
var cannons: Array[PlatformerCannon3D] = []

var mat_ground: StandardMaterial3D
var mat_brick: StandardMaterial3D
var mat_question: StandardMaterial3D
var mat_spent: StandardMaterial3D
var mat_pipe: StandardMaterial3D
var mat_flag: StandardMaterial3D
var mat_coin: StandardMaterial3D

func _init() -> void:
	_setup_materials()

func _setup_materials() -> void:
	mat_ground = StandardMaterial3D.new()
	mat_ground.albedo_texture = TEX_HULL
	mat_ground.albedo_color = Color("#ffffff")
	mat_ground.roughness = 0.35
	mat_ground.metallic = 0.65
	mat_ground.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	mat_brick = StandardMaterial3D.new()
	mat_brick.albedo_texture = TEX_BRICK
	mat_brick.albedo_color = Color("#ffffff")
	mat_brick.roughness = 0.4
	mat_brick.metallic = 0.4
	mat_brick.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	mat_question = StandardMaterial3D.new()
	mat_question.albedo_texture = TEX_QUESTION
	mat_question.albedo_color = Color("#ffffff")
	mat_question.emission_enabled = true
	mat_question.emission_texture = TEX_QUESTION
	mat_question.emission = Color("#f59e0b")
	mat_question.emission_energy_multiplier = 0.7
	mat_question.metallic = 0.5
	mat_question.roughness = 0.3
	mat_question.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	mat_spent = StandardMaterial3D.new()
	mat_spent.albedo_texture = TEX_BRICK
	mat_spent.albedo_color = Color("#475569")
	mat_spent.roughness = 0.8
	mat_spent.metallic = 0.6
	mat_spent.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	mat_pipe = StandardMaterial3D.new()
	mat_pipe.albedo_texture = TEX_PIPE
	mat_pipe.albedo_color = Color("#ffffff")
	mat_pipe.roughness = 0.3
	mat_pipe.metallic = 0.6
	mat_pipe.emission_enabled = true
	mat_pipe.emission_texture = TEX_PIPE
	mat_pipe.emission = Color("#22c55e")
	mat_pipe.emission_energy_multiplier = 0.35
	mat_pipe.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	mat_flag = StandardMaterial3D.new()
	mat_flag.albedo_color = Color("#38bdf8")
	mat_flag.emission_enabled = true
	mat_flag.emission = Color("#0ea5e9")
	mat_flag.emission_energy_multiplier = 0.8

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

	var ts := PlatformerConfig3D.TILE_SIZE
	var has_flagpole: bool = false

	for row in range(level_height_rows):
		var line := lines[row]
		for col in range(line.length()):
			var char := line[col]
			if char == "F" or char == "|":
				has_flagpole = true
			# In 3D: worldY = 0 ist Zeile 13 (unterster Boden)
			var world_y := float(level_height_rows - 1 - row) * ts
			var world_x := float(col) * ts
			var pos := Vector3(world_x, world_y, 0.0)
			_create_tile_3d(char, col, row, pos, ts)

	# Falls kein Zielmast im Level definiert war (z. B. viele VGLC-Rohdateien),
	# platziere automatisch eine Ziel-Warpbake kurz vor dem Levelende
	if not has_flagpole and level_width_cols > 0:
		var goal_col: int = maxi(5, level_width_cols - 4)
		flagpole_col = goal_col
		var world_x := float(goal_col) * ts
		for h in range(1, 9):
			var world_y := float(h) * ts
			_create_flagpole_3d(Vector3(world_x, world_y, 0.0), ts)

	_create_parallax_background_3d(level_width_cols * ts)
	return true

func _create_tile_3d(char: String, col: int, row: int, pos: Vector3, ts: float) -> void:
	match char:
		"X", "x":
			_create_solid_cube_3d(pos, ts, mat_ground, "Ground")
		"S", "s":
			_create_brick_cube_3d(pos, ts, col, row)
		"?", "Q", "q":
			_create_question_cube_3d(pos, ts, col, row)
		"<", ">", "[", "]":
			_create_solid_cube_3d(pos, ts, mat_pipe, "Pipe", 1.2)
		"E", "e":
			_create_enemy_3d(pos, ts)
		"K", "k":
			_create_koopa_3d(pos, ts)
		"B":
			_create_cannon_3d(pos, ts, true)
		"b":
			_create_cannon_3d(pos, ts, false)
		"P", "p", "y":
			_create_piranha_3d(pos, ts)
		"M", "m":
			_create_mushroom_3d(pos, ts)
		"f":
			_create_flower_3d(pos, ts)
		"*":
			_create_star_3d(pos, ts)
		"o", "O":
			_create_coin_3d(pos, ts, col, row)
		"F", "|":
			flagpole_col = col
			_create_flagpole_3d(pos, ts)

func _create_solid_cube_3d(pos: Vector3, ts: float, mat: StandardMaterial3D, name_prefix: String, depth_mult: float = 1.0) -> void:
	var body := StaticBody3D.new()
	body.name = "%s_%d_%d" % [name_prefix, int(pos.x), int(pos.y)]
	body.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ts, ts, ts * depth_mult)
	shape.shape = box
	body.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(ts, ts, ts * depth_mult)
	box_mesh.material = mat
	mesh_inst.mesh = box_mesh
	body.add_child(mesh_inst)

	add_child(body)

func _create_brick_cube_3d(pos: Vector3, ts: float, col: int, row: int) -> void:
	var body := StaticBody3D.new()
	body.name = "Brick3D_%d_%d" % [col, row]
	body.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)
	body.add_to_group("brick_blocks_3d")
	body.set_meta("col", col)
	body.set_meta("row", row)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ts, ts, ts)
	shape.shape = box
	body.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(ts, ts, ts)
	box_mesh.material = mat_brick
	mesh_inst.mesh = box_mesh
	body.add_child(mesh_inst)

	add_child(body)

func _create_question_cube_3d(pos: Vector3, ts: float, col: int, row: int) -> void:
	var body := StaticBody3D.new()
	body.name = "QuestionBlock3D_%d_%d" % [col, row]
	body.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)
	body.add_to_group("question_blocks_3d")
	body.set_meta("col", col)
	body.set_meta("row", row)
	body.set_meta("hit", false)
	var has_mushroom: bool = (question_blocks.is_empty() or col % 4 == 0)
	body.set_meta("has_mushroom", has_mushroom)
	body.set_meta("hit", false)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ts, ts, ts)
	shape.shape = box
	body.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(ts, ts, ts)
	box_mesh.material = mat_question
	mesh_inst.mesh = box_mesh
	body.add_child(mesh_inst)

	question_blocks[Vector2i(col, row)] = body
	add_child(body)

func _create_enemy_3d(pos: Vector3, ts: float) -> void:
	var enemy := PlatformerEnemy3D.new()
	enemy.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)
	enemies.append(enemy)
	add_child(enemy)
	enemy_spawned.emit(enemy)

func _create_koopa_3d(pos: Vector3, ts: float) -> void:
	var koopa := PlatformerKoopa3D.new()
	koopa.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)
	enemies.append(koopa)
	add_child(koopa)
	enemy_spawned.emit(koopa)

func _create_cannon_3d(pos: Vector3, ts: float, is_top: bool) -> void:
	var cannon := PlatformerCannon3D.new()
	cannon.is_top = is_top
	cannon.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)
	cannons.append(cannon)
	add_child(cannon)

func _create_piranha_3d(pos: Vector3, ts: float) -> void:
	var piranha := PlatformerPiranhaPlant3D.new()
	piranha.position = pos + Vector3(ts / 2.0, 0.0, 0.0)
	enemies.append(piranha)
	add_child(piranha)
	enemy_spawned.emit(piranha)

func _create_mushroom_3d(pos: Vector3, ts: float) -> void:
	var mushroom := PlatformerMushroom3D.new()
	mushroom.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)
	powerups.append(mushroom)
	add_child(mushroom)
	powerup_spawned.emit(mushroom)

func _create_flower_3d(pos: Vector3, ts: float) -> void:
	var flower := PlatformerFlower3D.new()
	flower.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)
	powerups.append(flower)
	add_child(flower)
	powerup_spawned.emit(flower)

func _create_star_3d(pos: Vector3, ts: float) -> void:
	var star := PlatformerStar3D.new()
	star.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)
	powerups.append(star)
	add_child(star)
	powerup_spawned.emit(star)

func _create_coin_3d(pos: Vector3, ts: float, col: int, row: int) -> void:
	var area := Area3D.new()
	area.name = "Coin3D_%d_%d" % [col, row]
	area.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = ts * 0.3
	shape.shape = sphere
	area.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = ts * 0.3
	cyl.bottom_radius = ts * 0.3
	cyl.height = 0.1
	cyl.radial_segments = 16

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#fbbf24")
	mat.metallic = 0.7
	mat.roughness = 0.3
	cyl.material = mat
	mesh_inst.mesh = cyl
	mesh_inst.rotation.x = PI / 2.0
	area.add_child(mesh_inst)

	area.body_entered.connect(func(body: Node3D):
		if body.is_in_group("player_3d"):
			coin_collected.emit(col, row)
			area.queue_free()
	)
	add_child(area)

func _create_flagpole_3d(pos: Vector3, ts: float) -> void:
	var area := Area3D.new()
	area.name = "GoalFlag3D"
	area.position = pos + Vector3(ts / 2.0, ts / 2.0, 0.0)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ts * 0.4, ts, ts)
	shape.shape = box
	area.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = ts * 0.1
	cyl.bottom_radius = ts * 0.1
	cyl.height = ts
	cyl.material = mat_flag
	mesh_inst.mesh = cyl
	area.add_child(mesh_inst)

	area.body_entered.connect(_on_flag_body_entered)
	add_child(area)

func _on_flag_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		goal_reached.emit()

func hit_block(block: StaticBody3D, is_big: bool = false) -> void:
	if not block:
		return

	if block.is_in_group("brick_blocks_3d"):
		if is_big:
			brick_shattered.emit(block.position)
			var tween := create_tween()
			tween.tween_property(block, "scale", Vector3.ZERO, 0.08)
			tween.tween_callback(block.queue_free)
		else:
			var tween := create_tween()
			var orig_y := block.position.y
			tween.tween_property(block, "position:y", orig_y + 0.2, 0.06)
			tween.tween_property(block, "position:y", orig_y, 0.06)
		return

	if not block.is_in_group("question_blocks_3d") or block.get_meta("hit", false):
		return

	block.set_meta("hit", true)
	var col: int = block.get_meta("col", -1)
	var row: int = block.get_meta("row", -1)

	var mesh_inst: MeshInstance3D = block.get_node_or_null("Mesh")
	if mesh_inst and mesh_inst.mesh is BoxMesh:
		mesh_inst.mesh.material = mat_spent

	var tween := create_tween()
	var orig_y := block.position.y
	tween.tween_property(block, "position:y", orig_y + 0.35, 0.08)
	tween.tween_property(block, "position:y", orig_y, 0.08)

	var has_powerup: bool = (question_blocks.size() == 1 or col % 4 == 0)
	if has_powerup:
		if col % 8 == 0:
			var star := PlatformerStar3D.new()
			star.position = block.position + Vector3(0.0, PlatformerConfig3D.TILE_SIZE * 0.8, 0.0)
			powerups.append(star)
			add_child(star)
			powerup_spawned.emit(star)
		elif is_big:
			var flower := PlatformerFlower3D.new()
			flower.position = block.position + Vector3(0.0, PlatformerConfig3D.TILE_SIZE * 0.8, 0.0)
			powerups.append(flower)
			add_child(flower)
			powerup_spawned.emit(flower)
		else:
			var mushroom := PlatformerMushroom3D.new()
			mushroom.position = block.position + Vector3(0.0, PlatformerConfig3D.TILE_SIZE * 0.8, 0.0)
			powerups.append(mushroom)
			add_child(mushroom)
			powerup_spawned.emit(mushroom)
	else:
		coin_collected.emit(col, row)

func _create_parallax_background_3d(level_length: float) -> void:
	# Raumschiff-Aufbauten / Flottengürtel im Hintergrund (Tiefenparallaxe durch 3D-Kamera)
	var mat_station := StandardMaterial3D.new()
	mat_station.albedo_color = Color("#0f172a") # Dark navy hull
	mat_station.metallic = 0.8
	mat_station.roughness = 0.4
	mat_station.emission_enabled = true
	mat_station.emission = Color("#06b6d4") # Cyan sensor array glow
	mat_station.emission_energy_multiplier = 0.2

	var mat_beacon := StandardMaterial3D.new()
	mat_beacon.albedo_color = Color("#38bdf8")
	mat_beacon.emission_enabled = true
	mat_beacon.emission = Color("#38bdf8")
	mat_beacon.emission_energy_multiplier = 1.0

	for x in range(0, int(level_length + 60), 16):
		var tower := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(4.0 + float(x % 5), 14.0 + float(x % 6), 3.0)
		box.material = mat_station
		tower.mesh = box
		tower.position = Vector3(float(x), 5.0 + float(x % 3), -16.0)
		add_child(tower)

		# Signalleuchten auf den Raumschiff-Aufbauten
		var beacon := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.25
		sph.height = 0.5
		sph.material = mat_beacon
		beacon.mesh = sph
		beacon.position = Vector3(float(x), 12.5 + float(x % 6) * 0.5, -14.5)
		add_child(beacon)

	# Schwebende Solarmodule & Kommunikations-Arrays bei Z = -24.0
	var mat_array := StandardMaterial3D.new()
	mat_array.albedo_color = Color("#1e293b")
	mat_array.metallic = 0.9
	mat_array.roughness = 0.2
	mat_array.emission_enabled = true
	mat_array.emission = Color("#6366f1")
	mat_array.emission_energy_multiplier = 0.3

	for x in range(8, int(level_length + 50), 24):
		var panel := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(8.0, 1.2, 0.4)
		box.material = mat_array
		panel.mesh = box
		panel.position = Vector3(float(x), 11.0 + float(x % 4), -24.0)
		panel.rotation.z = deg_to_rad(15.0 if (x % 2 == 0) else -15.0)
		add_child(panel)
