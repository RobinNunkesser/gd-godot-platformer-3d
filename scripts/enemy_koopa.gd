class_name PlatformerKoopa
extends CharacterBody2D

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerPlayer = preload("res://scripts/player.gd")

signal stomped(enemy: Node2D)
signal player_hurt(killed: bool)

enum State { WALKING, SHELL_IDLE, SHELL_SLIDING }
var current_state: State = State.WALKING

@export var walk_speed: float = 65.0
@export var slide_speed: float = 440.0
var direction: float = -1.0

var visual_head: ColorRect
var visual_shell: ColorRect

func _ready() -> void:
	add_to_group("enemies")
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36.0, 42.0)
	shape.shape = rect
	add_child(shape)

	var visual := Node2D.new()
	visual.name = "Visual"

	# Kopf
	visual_head = ColorRect.new()
	visual_head.color = Color("#84cc16") # Frisches Echsen-Grün
	visual_head.size = Vector2(16.0, 16.0)
	visual_head.position = Vector2(-8.0, -21.0)
	visual.add_child(visual_head)

	# Panzer
	visual_shell = ColorRect.new()
	visual_shell.color = Color("#16a34a") # Dunkelgrüner Schildkrötenpanzer
	visual_shell.size = Vector2(36.0, 30.0)
	visual_shell.position = Vector2(-18.0, -6.0)
	visual.add_child(visual_shell)

	# Rand
	var rim := ColorRect.new()
	rim.color = Color("#fef08a") # Gelber Panzer-Rand
	rim.size = Vector2(36.0, 6.0)
	rim.position = Vector2(-18.0, 18.0)
	visual.add_child(rim)

	add_child(visual)

	var area := Area2D.new()
	area.name = "Hitbox"
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(40.0, 44.0)
	area_shape.shape = area_rect
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func update_enemy(delta: float) -> void:
	velocity.y += PlatformerConfig.GRAVITY * delta

	match current_state:
		State.WALKING:
			velocity.x = walk_speed * direction
		State.SHELL_IDLE:
			velocity.x = 0.0
		State.SHELL_SLIDING:
			velocity.x = slide_speed * direction

	if is_inside_tree() and get_world_2d() and get_world_2d().space.is_valid():
		move_and_slide()
		if is_on_wall():
			direction *= -1.0
	else:
		position += velocity * delta

	if position.y > PlatformerConfig.DEATH_Y:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body):
		return

	# Wenn der Panzer schlittert und einen anderen Gegner rammt:
	if current_state == State.SHELL_SLIDING and body.is_in_group("enemies") and body != self:
		if body.has_method("die_from_fireball"):
			body.die_from_fireball()
		elif body.has_signal("stomped"):
			body.stomped.emit(body)
			body.queue_free()
		return

	if not (body is PlatformerPlayer):
		return

	var player := body as PlatformerPlayer

	# Starman vaporisiert Koopa sofort
	if player.is_starman:
		die_from_fireball()
		return

	var is_falling_on_top: bool = player.velocity.y > 0.0 and player.global_position.y < global_position.y - 6.0

	match current_state:
		State.WALKING:
			if is_falling_on_top:
				# 1. Stomp: Zieht sich in Panzer zurück
				current_state = State.SHELL_IDLE
				visual_head.visible = false
				player.bounce_after_stomp()
				stomped.emit(self)
			else:
				var killed := player.take_damage()
				player_hurt.emit(killed)

		State.SHELL_IDLE:
			if is_falling_on_top:
				# Draufspringen kickt den Panzer
				kick_shell(player)
				player.bounce_after_stomp()
			else:
				# Seitlicher Kontakt kickt den Panzer ebenfalls
				kick_shell(player)

		State.SHELL_SLIDING:
			if is_falling_on_top:
				# Stoppt den schliddernden Panzer
				current_state = State.SHELL_IDLE
				player.bounce_after_stomp()
			else:
				var killed := player.take_damage()
				player_hurt.emit(killed)

func kick_shell(player: PlatformerPlayer) -> void:
	current_state = State.SHELL_SLIDING
	direction = 1.0 if player.global_position.x < global_position.x else -1.0
	# Kleiner Sicherheitsversatz, damit der Spieler nicht direkt wieder kollidiert
	position.x += direction * 8.0

func die_from_fireball() -> void:
	stomped.emit(self)
	var tween := create_tween()
	if tween:
		tween.tween_property(self, "scale:y", 0.1, 0.08)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func take_stomp(player: PlatformerPlayer) -> void:
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
