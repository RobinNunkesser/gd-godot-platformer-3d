class_name PlatformerEnemy
extends CharacterBody2D

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerPlayer = preload("res://scripts/player.gd")

signal stomped(enemy: PlatformerEnemy)
signal player_hurt(killed: bool)

@export var speed: float = 75.0
var direction: float = -1.0
var is_dead: bool = false

var visual: Node2D
var collision_shape: CollisionShape2D

func _ready() -> void:
	add_to_group("enemies")
	_build_components()

func _build_components() -> void:
	# Collision Shape
	collision_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36.0, 36.0)
	collision_shape.shape = rect
	add_child(collision_shape)

	# Visuals: Archetypischer kleiner Goomba-ähnlicher Gegner
	visual = Node2D.new()
	visual.name = "Visual"

	# Körper (Kastanienbraun / Rotbraun)
	var body_rect := ColorRect.new()
	body_rect.name = "Body"
	body_rect.color = Color("#854d0e") # Warmes Erdbraun
	body_rect.size = Vector2(36.0, 36.0)
	body_rect.position = Vector2(-18.0, -18.0)
	visual.add_child(body_rect)

	# Augen
	var eye_left := ColorRect.new()
	eye_left.color = Color("#ffffff")
	eye_left.size = Vector2(6.0, 10.0)
	eye_left.position = Vector2(-12.0, -10.0)
	visual.add_child(eye_left)

	var pupil_left := ColorRect.new()
	pupil_left.color = Color("#000000")
	pupil_left.size = Vector2(4.0, 6.0)
	pupil_left.position = Vector2(-12.0, -8.0)
	visual.add_child(pupil_left)

	var eye_right := ColorRect.new()
	eye_right.color = Color("#ffffff")
	eye_right.size = Vector2(6.0, 10.0)
	eye_right.position = Vector2(6.0, -10.0)
	visual.add_child(eye_right)

	var pupil_right := ColorRect.new()
	pupil_right.color = Color("#000000")
	pupil_right.size = Vector2(4.0, 6.0)
	pupil_right.position = Vector2(6.0, -8.0)
	visual.add_child(pupil_right)

	# Füße
	var foot := ColorRect.new()
	foot.color = Color("#451a03")
	foot.size = Vector2(32.0, 6.0)
	foot.position = Vector2(-16.0, 12.0)
	visual.add_child(foot)

	add_child(visual)

	# Hitbox / Touch-Erkennung
	var area := Area2D.new()
	area.name = "Hitbox"
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(38.0, 38.0)
	area_shape.shape = area_rect
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_enemy(delta: float, _player: Node2D = null) -> void:
	if is_dead:
		return

	velocity.y += PlatformerConfig.GRAVITY * delta
	velocity.x = speed * direction

	if is_inside_tree() and get_world_2d() and get_world_2d().space.is_valid():
		move_and_slide()
		if is_on_wall():
			direction *= -1.0
	else:
		position += velocity * delta

	if position.y > PlatformerConfig.DEATH_Y:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_dead or not (body is PlatformerPlayer):
		return

	var player := body as PlatformerPlayer

	# Prüfen, ob Spieler von oben draufgesprungen ist (Stomp)
	var player_bottom: float = player.global_position.y + (PlatformerConfig.PLAYER_HEIGHT * 0.4 * player.scale.y)
	var enemy_top: float = global_position.y - 10.0

	if player.velocity.y > 0.0 and player_bottom <= enemy_top + 16.0:
		# Erfolgreicher Stomp!
		is_dead = true
		player.bounce_after_stomp()
		stomped.emit(self)

		# Squish-Animation
		var tween := create_tween()
		tween.tween_property(visual, "scale:y", 0.2, 0.08)
		tween.parallel().tween_property(visual, "position:y", 14.0, 0.08)
		tween.tween_property(visual, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)
	else:
		# Seitlicher / unterer Kontakt -> Schaden am Spieler
		var killed := player.take_damage()
		player_hurt.emit(killed)
