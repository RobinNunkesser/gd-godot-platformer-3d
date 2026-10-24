class_name PlatformerFireball
extends CharacterBody2D

const PlatformerConfig = preload("res://scripts/config.gd")

signal hit_enemy(enemy: Node2D)

@export var speed: float = 480.0
@export var bounce_force: float = -280.0
var direction: float = 1.0
var lifetime: float = 2.5

func _ready() -> void:
	add_to_group("fireballs")
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)

	var visual := Node2D.new()
	visual.name = "Visual"

	var outer := ColorRect.new()
	outer.color = Color("#f97316") # Lebendiges Feuer-Orange
	outer.size = Vector2(16.0, 16.0)
	outer.position = Vector2(-8.0, -8.0)
	visual.add_child(outer)

	var inner := ColorRect.new()
	inner.color = Color("#fef08a") # Heißer gelber Kern
	inner.size = Vector2(8.0, 8.0)
	inner.position = Vector2(-4.0, -4.0)
	visual.add_child(inner)

	add_child(visual)

	var area := Area2D.new()
	area.name = "DamageArea"
	var area_shape := CollisionShape2D.new()
	var area_circle := CircleShape2D.new()
	area_circle.radius = 10.0
	area_shape.shape = area_circle
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_fireball(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or position.y > PlatformerConfig.DEATH_Y:
		explode()
		return

	velocity.y += PlatformerConfig.GRAVITY * 0.9 * delta
	velocity.x = speed * direction

	if is_inside_tree() and get_world_2d() and get_world_2d().space.is_valid():
		move_and_slide()
		if is_on_floor():
			velocity.y = bounce_force
		if is_on_wall():
			explode()
	else:
		position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
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
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.06)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.06)
	tween.tween_callback(queue_free)
