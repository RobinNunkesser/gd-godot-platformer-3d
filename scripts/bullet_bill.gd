class_name PlatformerBulletBill
extends CharacterBody2D

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerPlayer = preload("res://scripts/player.gd")

signal stomped(enemy: Node2D)
signal player_hurt(killed: bool)

@export var speed: float = 240.0
var direction: float = -1.0
var lifetime: float = 6.0

func _ready() -> void:
	add_to_group("enemies")
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40.0, 26.0)
	shape.shape = rect
	add_child(shape)

	var visual := Node2D.new()
	visual.name = "Visual"

	# Scharzer Geschosskörper
	var body_rect := ColorRect.new()
	body_rect.color = Color("#0f172a") # Tiefschwarz / Kanonenmetall
	body_rect.size = Vector2(38.0, 24.0)
	body_rect.position = Vector2(-19.0, -12.0)
	visual.add_child(body_rect)

	# Geschossspitze (abgerundet / Kontrast)
	var nose := ColorRect.new()
	nose.color = Color("#334155")
	nose.size = Vector2(8.0, 16.0)
	nose.position = Vector2(-19.0 if direction < 0 else 11.0, -8.0)
	visual.add_child(nose)

	# Auge
	var eye := ColorRect.new()
	eye.color = Color("#ffffff")
	eye.size = Vector2(8.0, 8.0)
	eye.position = Vector2(-10.0 if direction < 0 else 2.0, -6.0)
	visual.add_child(eye)

	var pupil := ColorRect.new()
	pupil.color = Color("#000000")
	pupil.size = Vector2(4.0, 6.0)
	pupil.position = Vector2(-10.0 if direction < 0 else 4.0, -5.0)
	visual.add_child(pupil)

	add_child(visual)

	var area := Area2D.new()
	area.name = "Hitbox"
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(42.0, 28.0)
	area_shape.shape = area_rect
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_enemy(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or position.y > PlatformerConfig.DEATH_Y:
		queue_free()
		return

	velocity.x = speed * direction
	velocity.y = 0.0 # Fliegt horizontal ohne Schwerkraft
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if not (body is PlatformerPlayer):
		return

	var player := body as PlatformerPlayer

	if player.is_starman:
		die_from_fireball()
		return

	var is_falling_on_top: bool = player.velocity.y > 0.0 and player.global_position.y < global_position.y - 4.0

	if is_falling_on_top:
		player.bounce_after_stomp()
		die_from_fireball()
	else:
		var killed := player.take_damage()
		player_hurt.emit(killed)

var is_dead: bool = false

func take_stomp(player: PlatformerPlayer) -> void:
	is_dead = true
	player.bounce_after_stomp()
	die_from_fireball()

func die_from_fireball() -> void:
	is_dead = true
	stomped.emit(self)
	if is_inside_tree():
		var tween := create_tween()
		if tween:
			tween.tween_property(self, "scale", Vector2.ZERO, 0.08)
			tween.tween_callback(queue_free)
		else:
			queue_free()
	else:
		queue_free()
