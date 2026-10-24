class_name PlatformerPiranhaPlant
extends Node2D

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerPlayer = preload("res://scripts/player.gd")

signal stomped(enemy: Node2D)
signal player_hurt(killed: bool)

var base_y: float = 0.0
var extend_height: float = 44.0
var cycle_timer: float = 0.0
var is_emerged: bool = false
var is_dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	base_y = position.y
	_build_components()

func _build_components() -> void:
	var visual := Node2D.new()
	visual.name = "Visual"

	# Grüner Stamm
	var stem := ColorRect.new()
	stem.color = Color("#15803d")
	stem.size = Vector2(12.0, 32.0)
	stem.position = Vector2(-6.0, -12.0)
	visual.add_child(stem)

	# Roter Kopf / Schlund
	var head := ColorRect.new()
	head.color = Color("#dc2626") # Piranha-Rot
	head.size = Vector2(30.0, 26.0)
	head.position = Vector2(-15.0, -38.0)
	visual.add_child(head)

	# Zähne / Maul
	var mouth := ColorRect.new()
	mouth.color = Color("#ffffff")
	mouth.size = Vector2(20.0, 6.0)
	mouth.position = Vector2(-10.0, -28.0)
	visual.add_child(mouth)

	add_child(visual)

	var area := Area2D.new()
	area.name = "Hitbox"
	var area_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28.0, 40.0)
	area_shape.shape = rect
	area_shape.position = Vector2(0.0, -20.0)
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_enemy(delta: float, player: Node2D = null) -> void:
	if is_dead:
		return

	cycle_timer += delta

	# Wenn Spieler direkt über der Röhre steht, bleibt die Pflanze unten
	if player and absf(player.global_position.x - global_position.x) < 32.0:
		position.y = base_y
		return

	# Sinusförmiges Ausfahren aus der Röhre
	var progress := fposmod(cycle_timer, 4.0)
	if progress < 1.0:
		# Ausfahren
		position.y = lerp(base_y, base_y - extend_height, progress)
	elif progress < 2.5:
		# Oben verweilen
		position.y = base_y - extend_height
	elif progress < 3.5:
		# Einfahren
		position.y = lerp(base_y - extend_height, base_y, progress - 2.5)
	else:
		# Unten verweilen
		position.y = base_y

func _on_body_entered(body: Node2D) -> void:
	if is_dead or not (body is PlatformerPlayer):
		return

	var player := body as PlatformerPlayer

	# Starman besiegt Piranha-Pflanze
	if player.is_starman:
		die_from_fireball()
		return

	# Piranha-Pflanzen können NICHT per normalem Sprung plattgedrückt werden!
	var killed := player.take_damage()
	player_hurt.emit(killed)

func take_fireball() -> void:
	die_from_fireball()

func die_from_fireball() -> void:
	if is_dead:
		return
	is_dead = true
	stomped.emit(self)
	if is_inside_tree():
		var tween := create_tween()
		if tween:
			tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
			tween.tween_callback(queue_free)
		else:
			queue_free()
	else:
		queue_free()
