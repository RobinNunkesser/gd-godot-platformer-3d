class_name PlatformerMushroom
extends CharacterBody2D

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerPlayer = preload("res://scripts/player.gd")

signal collected(mushroom: PlatformerMushroom)

@export var speed: float = 90.0
var direction: float = 1.0
var is_collected: bool = false

func _ready() -> void:
	add_to_group("powerups")
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30.0, 30.0)
	shape.shape = rect
	add_child(shape)

	# Visual: Pilz (roter Hut mit weißen Punkten, heller Stiel)
	var visual := Node2D.new()
	visual.name = "Visual"

	# Stiel (Creme / Beige)
	var stem := ColorRect.new()
	stem.color = Color("#fef3c7")
	stem.size = Vector2(16.0, 14.0)
	stem.position = Vector2(-8.0, 0.0)
	visual.add_child(stem)

	# Hut (Rot)
	var cap := ColorRect.new()
	cap.color = Color("#dc2626") # Super Mario Pilz-Rot
	cap.size = Vector2(28.0, 16.0)
	cap.position = Vector2(-14.0, -14.0)
	visual.add_child(cap)

	# Weiße Punkte
	var spot_mid := ColorRect.new()
	spot_mid.color = Color("#ffffff")
	spot_mid.size = Vector2(8.0, 8.0)
	spot_mid.position = Vector2(-4.0, -12.0)
	visual.add_child(spot_mid)

	add_child(visual)

	# Area2D zum Einsammeln
	var area := Area2D.new()
	area.name = "PickupArea"
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(32.0, 32.0)
	area_shape.shape = area_rect
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_mushroom(delta: float) -> void:
	if is_collected:
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
	if is_collected or not (body is PlatformerPlayer):
		return

	is_collected = true
	var player := body as PlatformerPlayer
	player.power_up()
	collected.emit(self)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
