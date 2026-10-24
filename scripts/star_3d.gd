class_name PlatformerStar3D
extends CharacterBody3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")

signal collected(star: PlatformerStar3D)

@export var speed: float = 3.0
@export var bounce_force: float = 8.0
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

	var mat_star := StandardMaterial3D.new()
	mat_star.albedo_color = Color("#facc15")
	mat_star.emission_enabled = true
	mat_star.emission = Color("#facc15")
	mat_star.emission_energy_multiplier = 1.0

	var mesh_inst := MeshInstance3D.new()
	var prism := BoxMesh.new()
	prism.size = Vector3(0.5, 0.5, 0.4)
	prism.material = mat_star
	mesh_inst.mesh = prism
	mesh_inst.rotation.z = PI / 4.0
	visual.add_child(mesh_inst)

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

func update_star(delta: float) -> void:
	if is_collected:
		return

	velocity.y -= PlatformerConfig3D.GRAVITY * 0.9 * delta
	velocity.x = speed * direction
	velocity.z = 0.0

	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()
		if is_on_floor():
			velocity.y = bounce_force
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
	player.power_up_star()
	collected.emit(self)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.8, 1.8, 1.8), 0.1)
	tween.tween_callback(queue_free)
