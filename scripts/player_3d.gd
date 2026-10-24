class_name PlatformerPlayer3D
extends CharacterBody3D

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")

enum PowerState { SMALL, BIG, FIRE }
var power_state: PowerState = PowerState.SMALL
var is_fire: bool:
	get: return power_state == PowerState.FIRE

var is_starman: bool = false
var starman_timer: float = 0.0
var star_timer: float:
	get: return starman_timer
	set(v): starman_timer = v
var shoot_cooldown: float = 0.0

signal block_hit_from_below(block: StaticBody3D, is_big: bool)
signal player_jumped
signal powerup_state_changed(is_big: bool)
signal fireball_requested(pos: Vector3, dir: float)

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_facing_right: bool = true

var is_big: bool = false
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0

@onready var visual_mesh: Node3D = get_node_or_null("Visual")
var mat_body: StandardMaterial3D

func _ready() -> void:
	# 2.5D Achsen-Sperre: Keine Bewegung auf Z!
	axis_lock_linear_z = true
	add_to_group("player_3d")
	_setup_materials()
	reset_position()

func _setup_materials() -> void:
	var body_mesh: MeshInstance3D = get_node_or_null("Visual/Body")
	if body_mesh and body_mesh.mesh is BoxMesh:
		mat_body = StandardMaterial3D.new()
		mat_body.albedo_color = Color("#ef4444")
		body_mesh.mesh.material = mat_body

func reset_position(pos: Vector3 = Vector3(PlatformerConfig3D.START_X, PlatformerConfig3D.START_Y, 0.0)) -> void:
	position = pos
	velocity = Vector3.ZERO
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	is_facing_right = true
	power_state = PowerState.SMALL
	is_big = false
	is_starman = false
	starman_timer = 0.0
	shoot_cooldown = 0.0
	is_invulnerable = false
	invulnerability_timer = 0.0
	scale = Vector3.ONE
	_apply_visual_palette()
	_update_rotation()

func power_up() -> void:
	power_up_mushroom()

func power_up_mushroom() -> void:
	if power_state == PowerState.SMALL:
		power_state = PowerState.BIG
		is_big = true
		powerup_state_changed.emit(true)
		if is_inside_tree():
			var tween := create_tween()
			if tween:
				tween.tween_property(self, "scale", Vector3(1.25, 1.25, 1.25), 0.15)
			else:
				scale = Vector3(1.25, 1.25, 1.25)
		else:
			scale = Vector3(1.25, 1.25, 1.25)
	_apply_visual_palette()

func power_up_flower() -> void:
	power_state = PowerState.FIRE
	is_big = true
	powerup_state_changed.emit(true)
	if is_inside_tree():
		var tween := create_tween()
		if tween:
			tween.tween_property(self, "scale", Vector3(1.25, 1.25, 1.25), 0.15)
		else:
			scale = Vector3(1.25, 1.25, 1.25)
	else:
		scale = Vector3(1.25, 1.25, 1.25)
	_apply_visual_palette()

func power_up_star(duration: float = 10.0) -> void:
	is_starman = true
	starman_timer = duration

func shoot() -> void:
	if power_state == PowerState.FIRE and shoot_cooldown <= 0.0:
		shoot_cooldown = 0.22
		var dir := 1.0 if is_facing_right else -1.0
		var spawn_pos := global_position + Vector3(dir * 0.6, 0.1, 0.0)
		fireball_requested.emit(spawn_pos, dir)

func take_damage() -> bool:
	if is_starman:
		return false
	if is_invulnerable:
		return false

	if power_state == PowerState.FIRE:
		power_state = PowerState.BIG
		_apply_visual_palette()
		start_invulnerability(1.5)
		return false
	elif power_state == PowerState.BIG or is_big:
		power_state = PowerState.SMALL
		is_big = false
		powerup_state_changed.emit(false)
		if is_inside_tree():
			var tween := create_tween()
			if tween:
				tween.tween_property(self, "scale", Vector3.ONE, 0.15)
			else:
				scale = Vector3.ONE
		else:
			scale = Vector3.ONE
		_apply_visual_palette()
		start_invulnerability(1.5)
		return false

	return true

func start_invulnerability(duration: float = 1.5) -> void:
	is_invulnerable = true
	invulnerability_timer = duration

func bounce_after_stomp() -> void:
	velocity.y = PlatformerConfig3D.JUMP_FORCE * 0.65

func _apply_visual_palette() -> void:
	if not mat_body:
		return
	match power_state:
		PowerState.FIRE:
			mat_body.albedo_color = Color("#ffffff")
			mat_body.emission_enabled = true
			mat_body.emission = Color("#ea580c")
			mat_body.emission_energy_multiplier = 0.5
		PowerState.BIG, PowerState.SMALL:
			mat_body.albedo_color = Color("#ef4444")
			mat_body.emission_enabled = false

func update_kinematics(delta: float, input_left: bool, input_right: bool, input_jump_pressed: bool, input_jump_held: bool, input_shoot_pressed: bool = false) -> void:
	# 0. Starman & Unverwundbarkeit
	if is_starman:
		starman_timer -= delta
		if mat_body:
			var hue := fposmod(Time.get_ticks_msec() / 250.0, 1.0)
			mat_body.albedo_color = Color.from_hsv(hue, 0.8, 1.0)
			mat_body.emission_enabled = true
			mat_body.emission = Color.from_hsv(hue, 0.8, 1.0)
			mat_body.emission_energy_multiplier = 1.0
		if starman_timer <= 0.0:
			is_starman = false
			_apply_visual_palette()
	elif is_invulnerable:
		invulnerability_timer -= delta
		if visual_mesh:
			visual_mesh.visible = (int(invulnerability_timer * 15.0) % 2 == 0)
		if invulnerability_timer <= 0.0:
			is_invulnerable = false
			if visual_mesh:
				visual_mesh.visible = true
	else:
		if visual_mesh:
			visual_mesh.visible = true

	# Schuss-Cooldown
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta

	if input_shoot_pressed:
		shoot()

	# 1. Timer
	if is_on_floor():
		coyote_timer = PlatformerConfig3D.COYOTE_TIME_SEC
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)

	if input_jump_pressed:
		jump_buffer_timer = PlatformerConfig3D.JUMP_BUFFER_SEC
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	# 2. Horizontale Bewegung & Reibung
	var accel := PlatformerConfig3D.ACCELERATION if is_on_floor() else PlatformerConfig3D.ACCELERATION * PlatformerConfig3D.AIR_CONTROL
	if input_right and not input_left:
		velocity.x = minf(PlatformerConfig3D.MAX_RUN_SPEED, velocity.x + accel * delta)
		is_facing_right = true
		_update_rotation()
	elif input_left and not input_right:
		velocity.x = maxf(-PlatformerConfig3D.MAX_RUN_SPEED, velocity.x - accel * delta)
		is_facing_right = false
		_update_rotation()
	else:
		# Abbremsen
		if velocity.x > 0.0:
			velocity.x = maxf(0.0, velocity.x - PlatformerConfig3D.FRICTION * delta * PlatformerConfig3D.MAX_RUN_SPEED)
		elif velocity.x < 0.0:
			velocity.x = minf(0.0, velocity.x + PlatformerConfig3D.FRICTION * delta * PlatformerConfig3D.MAX_RUN_SPEED)

	# 3. Sprung-Ausführung (+Y ist in 3D oben!)
	var can_jump := is_on_floor() or coyote_timer > 0.0
	if can_jump and jump_buffer_timer > 0.0:
		velocity.y = PlatformerConfig3D.JUMP_FORCE
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		player_jumped.emit()

	# 4. Variable Sprunghöhe
	if not input_jump_held and velocity.y > 0.0:
		velocity.y *= PlatformerConfig3D.VARIABLE_JUMP_CUT

	# 5. Gravitation
	velocity.y -= PlatformerConfig3D.GRAVITY * delta

	# Z strikt auf 0 halten
	velocity.z = 0.0

	# 6. 3D Engine Physics Move
	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()

		# 7. Kopfstoß an Decke
		if is_on_ceiling():
			for i in range(get_slide_collision_count()):
				var collision := get_slide_collision(i)
				var collider := collision.get_collider()
				if collider is StaticBody3D:
					if collider.is_in_group("question_blocks_3d") or collider.is_in_group("brick_blocks_3d"):
						block_hit_from_below.emit(collider, is_big)
	else:
		position += velocity * delta

func _update_rotation() -> void:
	if visual_mesh:
		visual_mesh.rotation.y = 0.0 if is_facing_right else PI
