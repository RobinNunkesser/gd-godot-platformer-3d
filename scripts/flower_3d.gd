class_name PlatformerFlower3D
extends CharacterBody3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")

signal collected(flower: PlatformerFlower3D)

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
	mat_stem.albedo_color = Color("#22c55e")

	var stem := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.08
	cyl.height = 0.3
	cyl.material = mat_stem
	stem.mesh = cyl
	stem.position.y = -0.15
	visual.add_child(stem)

	var mat_petal := StandardMaterial3D.new()
	mat_petal.albedo_color = Color("#ea580c")
	mat_petal.emission_enabled = true
	mat_petal.emission = Color("#ea580c")
	mat_petal.emission_energy_multiplier = 0.6

	var petal := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.35
	sphere.material = mat_petal
	petal.mesh = sphere
	petal.position.y = 0.1
	visual.add_child(petal)

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

func update_flower(_delta: float) -> void:
	pass

func _on_body_entered(body: Node3D) -> void:
	if is_collected or not (body is PlatformerPlayer3D):
		return

	is_collected = true
	var player := body as PlatformerPlayer3D
	player.power_up_flower()
	collected.emit(self)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
	tween.tween_callback(queue_free)
