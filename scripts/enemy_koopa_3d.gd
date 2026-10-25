class_name PlatformerKoopa3D
extends CharacterBody3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")
const FROG_SCENE: PackedScene = preload("res://assets/models/enemies/Frog.fbx")

signal stomped(enemy: Node3D)
signal player_hurt(killed: bool)

enum State { WALKING, SHELL_IDLE, SHELL_SLIDING }
var current_state: State = State.WALKING

@export var walk_speed: float = 1.6
@export var slide_speed: float = 11.0
var direction: float = -1.0

var visual: Node3D
var visual_head: MeshInstance3D
var visual_shell: MeshInstance3D
var frog_model: Node3D
var anim_player: AnimationPlayer

func _ready() -> void:
	axis_lock_linear_z = true
	floor_snap_length = 0.25
	floor_constant_speed = true
	add_to_group("enemies_3d")
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.75, 0.85, 0.75)
	shape.shape = box
	add_child(shape)

	visual = Node3D.new()
	visual.name = "Visual"

	var mat_shell := StandardMaterial3D.new()
	mat_shell.albedo_color = Color("#16a34a")
	mat_shell.roughness = 0.5

	visual_shell = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.38
	sphere.height = 0.6
	sphere.material = mat_shell
	visual_shell.mesh = sphere
	visual.add_child(visual_shell)

	var mat_head := StandardMaterial3D.new()
	mat_head.albedo_color = Color("#84cc16")

	visual_head = MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.18
	head_sphere.height = 0.3
	head_sphere.material = mat_head
	visual_head.mesh = head_sphere
	visual_head.position = Vector3(0.0, 0.35, 0.2)
	visual.add_child(visual_head)

	if FROG_SCENE:
		visual_shell.visible = false
		visual_head.visible = false
		frog_model = FROG_SCENE.instantiate()
		frog_model.name = "FrogModel"
		frog_model.scale = Vector3(0.20, 0.20, 0.20)
		frog_model.position = Vector3(0.0, -0.35, 0.0)
		visual.add_child(frog_model)
		anim_player = frog_model.find_child("AnimationPlayer") as AnimationPlayer
		if anim_player and anim_player.has_animation("FrogArmature|Frog_Jump"):
			anim_player.play("FrogArmature|Frog_Jump")

	add_child(visual)

	var area := Area3D.new()
	area.name = "Hitbox3D"
	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(0.85, 0.9, 0.85)
	area_shape.shape = area_box
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_enemy(delta: float, _player: Node3D = null) -> void:
	velocity.y -= PlatformerConfig3D.GRAVITY * delta
	velocity.z = 0.0

	match current_state:
		State.WALKING:
			velocity.x = walk_speed * direction
		State.SHELL_IDLE:
			velocity.x = 0.0
		State.SHELL_SLIDING:
			velocity.x = slide_speed * direction

	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()
		if is_on_wall():
			var wall_normal := get_wall_normal()
			if absf(wall_normal.x) > 0.6 and absf(wall_normal.y) < 0.4:
				direction = -signf(wall_normal.x)
	else:
		position += velocity * delta

	if visual:
		if current_state == State.SHELL_SLIDING:
			visual.rotation.z += delta * 18.0 * (-direction)
		else:
			visual.rotation.z = 0.0
			visual.rotation.y = (PI / 2.0) if direction > 0.0 else (-PI / 2.0)

	if position.y < PlatformerConfig3D.DEATH_Y:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if not is_instance_valid(body):
		return

	if current_state == State.SHELL_SLIDING and body.is_in_group("enemies_3d") and body != self:
		if body.has_method("die_from_fireball"):
			body.die_from_fireball()
		elif body.has_signal("stomped"):
			body.stomped.emit(body)
			body.queue_free()
		return

	if not (body is PlatformerPlayer3D):
		return

	var player := body as PlatformerPlayer3D

	if player.is_starman:
		die_from_fireball()
		return

	# Großzügige Stomp-Erkennung:
	# Spieler ist über dem Gegnerzentrum oder fällt in ihn hinein
	var player_y: float = player.global_position.y if player.is_inside_tree() else player.position.y
	var enemy_y: float = global_position.y if is_inside_tree() else position.y
	var is_falling_on_top: bool = (player_y > enemy_y + 0.12) or (player.velocity.y < -0.1 and player_y > enemy_y - 0.05)

	match current_state:
		State.WALKING:
			if is_falling_on_top:
				take_stomp(player)
			else:
				var killed := player.take_damage()
				player_hurt.emit(killed)

		State.SHELL_IDLE:
			kick_shell(player)
			if is_falling_on_top:
				player.bounce_after_stomp()

		State.SHELL_SLIDING:
			if is_falling_on_top:
				take_stomp(player)
			else:
				var killed := player.take_damage()
				player_hurt.emit(killed)

func kick_shell(player: PlatformerPlayer3D) -> void:
	current_state = State.SHELL_SLIDING
	direction = 1.0 if player.global_position.x < global_position.x else -1.0
	position.x += direction * 0.25

func die_from_fireball() -> void:
	stomped.emit(self)
	var tween := create_tween()
	if tween:
		tween.tween_property(self, "scale:y", 0.1, 0.08)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func take_stomp(player: PlatformerPlayer3D) -> void:
	match current_state:
		State.WALKING:
			current_state = State.SHELL_IDLE
			if visual_head:
				visual_head.visible = false
			player.bounce_after_stomp()
			stomped.emit(self)
		State.SHELL_IDLE:
			kick_shell(player)
			player.bounce_after_stomp()
		State.SHELL_SLIDING:
			current_state = State.SHELL_IDLE
			player.bounce_after_stomp()
