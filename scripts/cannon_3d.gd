class_name PlatformerCannon3D
extends StaticBody3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerBulletBill3D = preload("res://scripts/bullet_bill_3d.gd")

signal bullet_fired(bullet: PlatformerBulletBill3D)

@export var is_top: bool = true
var fire_timer: float = 2.0
var fire_interval: float = 3.6
var player_ref: Node3D

func _ready() -> void:
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var ts := PlatformerConfig3D.TILE_SIZE
	box.size = Vector3(ts, ts, ts)
	shape.shape = box
	add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(ts, ts, ts)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#1e293b") if is_top else Color("#475569")
	mat.metallic = 0.5
	mat.roughness = 0.5
	box_mesh.material = mat
	mesh_inst.mesh = box_mesh
	add_child(mesh_inst)

func update_cannon(delta: float, player: Node3D = null) -> void:
	if not is_top:
		return

	player_ref = player
	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = fire_interval
		_try_fire()

func _try_fire() -> void:
	if not player_ref:
		return

	var dist := global_position.distance_to(player_ref.global_position)
	if dist > 1.5 and dist < 16.0:
		var dir := -1.0 if player_ref.global_position.x < global_position.x else 1.0
		var bullet := PlatformerBulletBill3D.new()
		bullet.direction = dir
		bullet.position = global_position + Vector3(dir * 0.8, 0.0, 0.0)
		bullet_fired.emit(bullet)
