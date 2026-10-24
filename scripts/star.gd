class_name PlatformerStar
extends CharacterBody2D

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerPlayer = preload("res://scripts/player.gd")

signal collected(star: PlatformerStar)

@export var speed: float = 120.0
@export var bounce_force: float = -380.0
var direction: float = 1.0
var is_collected: bool = false

func _ready() -> void:
	add_to_group("powerups")
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28.0, 28.0)
	shape.shape = rect
	add_child(shape)

	var visual := Node2D.new()
	visual.name = "Visual"

	# Goldener Sternkörper
	var diamond := ColorRect.new()
	diamond.color = Color("#facc15") # Leuchtendes Stern-Gold
	diamond.size = Vector2(22.0, 22.0)
	diamond.position = Vector2(-11.0, -11.0)
	diamond.rotation = PI / 4.0
	visual.add_child(diamond)

	# Augen
	var eye_left := ColorRect.new()
	eye_left.color = Color("#000000")
	eye_left.size = Vector2(3.0, 8.0)
	eye_left.position = Vector2(-5.0, -4.0)
	visual.add_child(eye_left)

	var eye_right := ColorRect.new()
	eye_right.color = Color("#000000")
	eye_right.size = Vector2(3.0, 8.0)
	eye_right.position = Vector2(3.0, -4.0)
	visual.add_child(eye_right)

	add_child(visual)

	var area := Area2D.new()
	area.name = "PickupArea"
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(32.0, 32.0)
	area_shape.shape = area_rect
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_star(delta: float) -> void:
	if is_collected:
		return

	velocity.y += PlatformerConfig.GRAVITY * 0.9 * delta
	velocity.x = speed * direction

	if is_inside_tree() and get_world_2d() and get_world_2d().space.is_valid():
		move_and_slide()
		if is_on_floor():
			velocity.y = bounce_force
		if is_on_wall():
			direction *= -1.0
	else:
		position += velocity * delta

	if position.y > PlatformerConfig.DEATH_Y:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not (body is PlatformerPlayer):
		return

	is_collected = true
	var player := body as PlatformerPlayer
	player.power_up_star()
	collected.emit(self)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.1)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
