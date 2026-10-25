class_name PlatformerBulletBill3D
extends CharacterBody3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")
const WASP_SCENE: PackedScene = preload("res://assets/models/enemies/Wasp.fbx")

signal stomped(enemy: Node3D)
signal player_hurt(killed: bool)

@export var speed: float = 6.0
var direction: float = -1.0
var lifetime: float = 6.0

var visual: Node3D
var wasp_model: Node3D
var anim_player: AnimationPlayer

func _ready() -> void:
	axis_lock_linear_z = true
	add_to_group("enemies_3d")
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.5, 0.5)
	shape.shape = box
	add_child(shape)

	visual = Node3D.new()
	visual.name = "Visual"

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#0f172a")
	mat.metallic = 0.8
	mat.roughness = 0.3

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.25
	cyl.height = 0.9
	cyl.material = mat
	mesh_inst.mesh = cyl
	mesh_inst.rotation.z = PI / 2.0
	visual.add_child(mesh_inst)

	if WASP_SCENE:
		mesh_inst.visible = false
		wasp_model = WASP_SCENE.instantiate()
		wasp_model.name = "WaspModel"
		wasp_model.scale = Vector3(0.18, 0.18, 0.18)
		wasp_model.position = Vector3(0.0, -0.15, 0.0)
		visual.add_child(wasp_model)
		anim_player = wasp_model.find_child("AnimationPlayer") as AnimationPlayer
		if anim_player and anim_player.has_animation("WaspArmature|Wasp_Flying"):
			anim_player.play("WaspArmature|Wasp_Flying")

	add_child(visual)

	var area := Area3D.new()
	area.name = "Hitbox3D"
	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(0.85, 0.55, 0.55)
	area_shape.shape = area_box
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_enemy(delta: float, _player: Node3D = null) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or position.y < PlatformerConfig3D.DEATH_Y:
		queue_free()
		return

	velocity.x = speed * direction
	velocity.y = 0.0
	velocity.z = 0.0
	position += velocity * delta

	if visual:
		visual.rotation.y = (PI / 2.0) if direction > 0.0 else (-PI / 2.0)

func _on_body_entered(body: Node3D) -> void:
	if not (body is PlatformerPlayer3D):
		return

	var player := body as PlatformerPlayer3D

	if player.is_starman:
		die_from_fireball()
		return

	var player_y: float = player.global_position.y if player.is_inside_tree() else player.position.y
	var enemy_y: float = global_position.y if is_inside_tree() else position.y
	var is_falling_on_top: bool = (player_y > enemy_y + 0.1) or (player.velocity.y < -0.1 and player_y > enemy_y - 0.05)

	if is_falling_on_top:
		take_stomp(player)
	else:
		var killed := player.take_damage()
		player_hurt.emit(killed)

var is_dead: bool = false

func take_stomp(player: PlatformerPlayer3D) -> void:
	is_dead = true
	player.bounce_after_stomp()
	die_from_fireball()

func die_from_fireball() -> void:
	is_dead = true
	stomped.emit(self)
	if is_inside_tree():
		var tween := create_tween()
		if tween:
			tween.tween_property(self, "scale", Vector3.ZERO, 0.08)
			tween.tween_callback(queue_free)
		else:
			queue_free()
	else:
		queue_free()
