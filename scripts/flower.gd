class_name PlatformerFlower
extends CharacterBody2D

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerPlayer = preload("res://scripts/player.gd")

signal collected(flower: PlatformerFlower)

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

	var visual := Node2D.new()
	visual.name = "Visual"

	# Grüner Stiel
	var stem := ColorRect.new()
	stem.color = Color("#22c55e")
	stem.size = Vector2(8.0, 14.0)
	stem.position = Vector2(-4.0, 0.0)
	visual.add_child(stem)

	# Oranger Blütenkranz
	var petal := ColorRect.new()
	petal.color = Color("#ea580c")
	petal.size = Vector2(24.0, 20.0)
	petal.position = Vector2(-12.0, -16.0)
	visual.add_child(petal)

	# Gelber Kern
	var core := ColorRect.new()
	core.color = Color("#fef08a")
	core.size = Vector2(12.0, 12.0)
	core.position = Vector2(-6.0, -12.0)
	visual.add_child(core)

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

func update_flower(_delta: float) -> void:
	# Blumen stehen an Ort und Stelle
	pass

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not (body is PlatformerPlayer):
		return

	is_collected = true
	var player := body as PlatformerPlayer
	player.power_up_flower()
	collected.emit(self)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
