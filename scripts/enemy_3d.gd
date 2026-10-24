class_name PlatformerEnemy3D
extends CharacterBody3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")

signal stomped(enemy: PlatformerEnemy3D)
signal player_hurt(killed: bool)

@export var speed: float = 1.8
var direction: float = -1.0
var is_dead: bool = false

var visual: Node3D

func _ready() -> void:
	axis_lock_linear_z = true
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

func update_enemy(delta: float) -> void:
	if is_dead:
		return

	velocity.y -= PlatformerConfig3D.GRAVITY * delta
	velocity.x = speed * direction
	velocity.z = 0.0

	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()
		if is_on_wall():
			direction *= -1.0
	else:
		position += velocity * delta

	if position.y < PlatformerConfig3D.DEATH_Y:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if is_dead or not (body is PlatformerPlayer3D):
		return

	var player := body as PlatformerPlayer3D

	# In 3D ist +Y oben, also Sprungabwärts = velocity.y < 0.0
	var player_bottom: float = player.global_position.y - (PlatformerConfig3D.PLAYER_HEIGHT * 0.4 * player.scale.y)
	var enemy_top: float = global_position.y + 0.25

	if player.velocity.y < 0.0 and player_bottom >= enemy_top - 0.3:
		# Stomp Erfolg
		is_dead = true
		player.bounce_after_stomp()
		stomped.emit(self)

		var tween := create_tween()
		tween.tween_property(visual, "scale:y", 0.15, 0.08)
		tween.parallel().tween_property(visual, "position:y", -0.25, 0.08)
		tween.tween_interval(0.1)
		tween.tween_callback(queue_free)
	else:
		var killed := player.take_damage()
		player_hurt.emit(killed)
