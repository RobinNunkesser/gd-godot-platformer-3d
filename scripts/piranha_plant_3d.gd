class_name PlatformerPiranhaPlant3D
extends Node3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")

signal stomped(enemy: Node3D)
signal player_hurt(killed: bool)

var base_y: float = 0.0
var extend_height: float = 0.95
var cycle_timer: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	add_to_group("enemies_3d")
	base_y = position.y
	_build_components()

func _build_components() -> void:
	var visual := Node3D.new()
	visual.name = "Visual"

	var mat_stem := StandardMaterial3D.new()
	mat_stem.albedo_color = Color("#15803d")

	var stem := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.12
	cyl.height = 0.6
	cyl.material = mat_stem
	stem.mesh = cyl
	stem.position.y = 0.3
	visual.add_child(stem)

	var mat_head := StandardMaterial3D.new()
	mat_head.albedo_color = Color("#dc2626")

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.5
	sphere.material = mat_head
	head.mesh = sphere
	head.position.y = 0.7
	visual.add_child(head)

	add_child(visual)

	var area := Area3D.new()
	area.name = "Hitbox3D"
	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(0.7, 0.9, 0.7)
	area_shape.shape = area_box
	area_shape.position = Vector3(0.0, 0.45, 0.0)
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_enemy(delta: float, player: Node3D = null) -> void:
	if is_dead:
		return

	cycle_timer += delta

	# In 3D ist Y nach oben positiv!
	if player and is_inside_tree() and player.is_inside_tree() and absf(player.global_position.x - global_position.x) < 0.8:
		position.y = base_y
		return

	var progress := fposmod(cycle_timer, 4.0)
	if progress < 1.0:
		position.y = lerp(base_y, base_y + extend_height, progress)
	elif progress < 2.5:
		position.y = base_y + extend_height
	elif progress < 3.5:
		position.y = lerp(base_y + extend_height, base_y, progress - 2.5)
	else:
		position.y = base_y

func _on_body_entered(body: Node3D) -> void:
	if is_dead or not (body is PlatformerPlayer3D):
		return

	var player := body as PlatformerPlayer3D

	if player.is_starman:
		die_from_fireball()
		return

	var killed := player.take_damage()
	player_hurt.emit(killed)

func take_fireball() -> void:
	die_from_fireball()

func die_from_fireball() -> void:
	if is_dead:
		return
	is_dead = true
	stomped.emit(self)
	if is_inside_tree():
		var tween := create_tween()
		if tween:
			tween.tween_property(self, "scale", Vector3.ZERO, 0.1)
			tween.tween_callback(queue_free)
		else:
			queue_free()
	else:
		queue_free()
