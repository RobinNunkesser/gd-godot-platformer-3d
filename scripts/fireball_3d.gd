class_name PlatformerFireball3D
extends CharacterBody3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")

signal hit_enemy(enemy: Node3D)

@export var speed: float = 12.0
@export var bounce_force: float = 6.0
var direction: float = 1.0
var lifetime: float = 2.5

func _ready() -> void:
	axis_lock_linear_z = true
	add_to_group("fireballs_3d")
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.2
	shape.shape = sphere
	add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var s_mesh := SphereMesh.new()
	s_mesh.radius = 0.2
	s_mesh.height = 0.4

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#f97316")
	mat.emission_enabled = true
	mat.emission = Color("#f97316")
	mat.emission_energy_multiplier = 2.0
	s_mesh.material = mat
	mesh_inst.mesh = s_mesh
	add_child(mesh_inst)

	var area := Area3D.new()
	area.name = "DamageArea3D"
	var area_shape := CollisionShape3D.new()
	var area_sphere := SphereShape3D.new()
	area_sphere.radius = 0.25
	area_shape.shape = area_sphere
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_fireball(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or position.y < PlatformerConfig3D.DEATH_Y:
		explode()
		return

	velocity.y -= PlatformerConfig3D.GRAVITY * 0.9 * delta
	velocity.x = speed * direction
	velocity.z = 0.0

	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()
		if is_on_floor():
			velocity.y = bounce_force
		if is_on_wall():
			explode()
	else:
		position += velocity * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemies_3d"):
		if body.has_method("die_from_fireball"):
			body.die_from_fireball()
		elif body.has_signal("stomped"):
			body.stomped.emit(body)
			body.queue_free()
		hit_enemy.emit(body)
		explode()

func explode() -> void:
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.8, 1.8, 1.8), 0.06)
	tween.tween_callback(queue_free)
