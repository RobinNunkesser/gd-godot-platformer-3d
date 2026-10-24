class_name PlatformerMushroom3D
extends CharacterBody3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")

signal collected(mushroom: PlatformerMushroom3D)

@export var speed: float = 2.0
var direction: float = 1.0
var is_collected: bool = false

func _ready() -> void:
	axis_lock_linear_z = true
	add_to_group("powerups_3d")
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	shape.shape = box
	add_child(shape)

	var visual := Node3D.new()
	visual.name = "Visual"

	var mat_stem := StandardMaterial3D.new()
	mat_stem.albedo_color = Color("#fef3c7")
	mat_stem.roughness = 0.5

	var stem_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.2
	cyl.height = 0.3
	cyl.material = mat_stem
	stem_mesh.mesh = cyl
	stem_mesh.position.y = -0.15
	visual.add_child(stem_mesh)

	var mat_cap := StandardMaterial3D.new()
	mat_cap.albedo_color = Color("#dc2626")
	mat_cap.roughness = 0.4

	var cap_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.4
	sphere.material = mat_cap
	cap_mesh.mesh = sphere
	cap_mesh.position.y = 0.1
	visual.add_child(cap_mesh)

	add_child(visual)

	var area := Area3D.new()
	area.name = "PickupArea3D"
	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(0.7, 0.7, 0.7)
	area_shape.shape = area_box
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_mushroom(delta: float) -> void:
	if is_collected:
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
	if is_collected or not (body is PlatformerPlayer3D):
		return

	is_collected = true
	var player := body as PlatformerPlayer3D
	player.power_up()
	collected.emit(self)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
	tween.tween_callback(queue_free)
