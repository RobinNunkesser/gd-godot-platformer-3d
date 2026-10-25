class_name PlatformerEnemy3D
extends CharacterBody3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")
const RAT_SCENE: PackedScene = preload("res://assets/models/enemies/Rat.fbx")

signal stomped(enemy: PlatformerEnemy3D)
signal player_hurt(killed: bool)

@export var speed: float = 1.8
var direction: float = -1.0
var is_dead: bool = false

var visual: Node3D
var rat_model: Node3D
var anim_player: AnimationPlayer

func _ready() -> void:
	axis_lock_linear_z = true
	floor_snap_length = 0.25
	floor_constant_speed = true
	add_to_group("enemies_3d")
	_build_components()

func _build_components() -> void:
	# Kollisionsbox
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.75, 0.7, 0.75)
	col_shape.shape = box
	add_child(col_shape)

	# Visuals
	visual = Node3D.new()
	visual.name = "Visual"

	var mat_body := StandardMaterial3D.new()
	mat_body.albedo_color = Color("#854d0e")
	mat_body.roughness = 0.6

	var body_mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.75, 0.7, 0.75)
	box_mesh.material = mat_body
	body_mesh.mesh = box_mesh
	visual.add_child(body_mesh)

	# Augen
	var mat_white := StandardMaterial3D.new()
	mat_white.albedo_color = Color("#ffffff")

	var eye_left := MeshInstance3D.new()
	var eye_mesh := BoxMesh.new()
	eye_mesh.size = Vector3(0.12, 0.2, 0.05)
	eye_mesh.material = mat_white
	eye_left.mesh = eye_mesh
	eye_left.position = Vector3(-0.2, 0.1, 0.38)
	visual.add_child(eye_left)

	var eye_right := MeshInstance3D.new()
	eye_right.mesh = eye_mesh
	eye_right.position = Vector3(0.2, 0.1, 0.38)
	visual.add_child(eye_right)

	if RAT_SCENE:
		body_mesh.visible = false
		eye_left.visible = false
		eye_right.visible = false
		rat_model = RAT_SCENE.instantiate()
		rat_model.name = "RatModel"
		rat_model.scale = Vector3(0.24, 0.24, 0.24)
		rat_model.position = Vector3(0.0, -0.25, 0.0)
		visual.add_child(rat_model)
		anim_player = rat_model.find_child("AnimationPlayer") as AnimationPlayer
		if anim_player and anim_player.has_animation("RatArmature|Rat_Run"):
			anim_player.play("RatArmature|Rat_Run")

	add_child(visual)

	# Area3D für Trefferkontakt
	var area := Area3D.new()
	area.name = "Hitbox3D"
	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(0.8, 0.75, 0.8)
	area_shape.shape = area_box
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_enemy(delta: float, _player: Node3D = null) -> void:
	if is_dead:
		return

	velocity.y -= PlatformerConfig3D.GRAVITY * delta
	velocity.x = speed * direction
	velocity.z = 0.0

	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()
		if is_on_wall():
			var wall_normal := get_wall_normal()
			if absf(wall_normal.x) > 0.6 and absf(wall_normal.y) < 0.4:
				direction = -signf(wall_normal.x)
	else:
		position += velocity * delta

	if visual:
		visual.rotation.y = (PI / 2.0) if direction > 0.0 else (-PI / 2.0)

	if position.y < PlatformerConfig3D.DEATH_Y:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if is_dead or not (body is PlatformerPlayer3D):
		return

	var player := body as PlatformerPlayer3D
	if player.is_starman:
		die_from_fireball()
		return

	# Großzügige Stomp-Erkennung:
	# Spieler ist über dem Gegnerzentrum oder fällt in ihn hinein
	var player_y: float = player.global_position.y if player.is_inside_tree() else player.position.y
	var enemy_y: float = global_position.y if is_inside_tree() else position.y
	var is_stomp: bool = (player_y > enemy_y + 0.12) or (player.velocity.y < -0.1 and player_y > enemy_y - 0.05)

	if is_stomp:
		take_stomp(player)
	else:
		var killed := player.take_damage()
		player_hurt.emit(killed)

func take_stomp(player: PlatformerPlayer3D) -> void:
	if is_dead:
		return
	is_dead = true
	if anim_player and anim_player.has_animation("RatArmature|Rat_Death"):
		anim_player.play("RatArmature|Rat_Death")
	player.bounce_after_stomp()
	stomped.emit(self)

	if is_inside_tree() and visual:
		var tween := create_tween()
		if tween:
			tween.tween_property(visual, "scale:y", 0.15, 0.08)
			tween.parallel().tween_property(visual, "position:y", -0.25, 0.08)
			tween.tween_interval(0.12)
			tween.tween_callback(queue_free)
		else:
			queue_free()
	else:
		queue_free()

func die_from_fireball() -> void:
	if is_dead:
		return
	is_dead = true
	stomped.emit(self)
	if anim_player and anim_player.has_animation("RatArmature|Rat_Death"):
		anim_player.play("RatArmature|Rat_Death")
	if is_inside_tree() and visual:
		var tween := create_tween()
		if tween:
			tween.tween_property(visual, "scale", Vector3.ZERO, 0.1)
			tween.tween_callback(queue_free)
		else:
			queue_free()
	else:
		queue_free()
