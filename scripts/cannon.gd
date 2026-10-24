class_name PlatformerCannon
extends StaticBody2D

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerBulletBill = preload("res://scripts/bullet_bill.gd")

signal bullet_fired(bullet: PlatformerBulletBill)

@export var is_top: bool = true
var fire_timer: float = 2.0
var fire_interval: float = 3.6
var player_ref: Node2D

func _ready() -> void:
	_build_components()

func _build_components() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var ts := PlatformerConfig.TILE_SIZE
	rect.size = Vector2(ts, ts)
	shape.shape = rect
	add_child(shape)

	var visual := ColorRect.new()
	visual.size = Vector2(ts - 1.0, ts - 1.0)
	visual.position = Vector2(-ts / 2.0, -ts / 2.0)

	if is_top:
		visual.color = Color("#1e293b") # Kanonenlauf
		# Mündungsöffnung
		var muzzle := ColorRect.new()
		muzzle.color = Color("#0f172a")
		muzzle.size = Vector2(10.0, 16.0)
		muzzle.position = Vector2(-ts / 2.0, -8.0)
		visual.add_child(muzzle)
	else:
		visual.color = Color("#475569") # Sockel / Standfuß

	add_child(visual)

func update_cannon(delta: float, player: Node2D = null) -> void:
	if not is_top:
		return

	player_ref = player
	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = fire_interval
		_try_fire()

func _try_fire() -> void:
	if not player_ref:
		return

	var dist := global_position.distance_to(player_ref.global_position)
	# Nur feuern, wenn der Spieler im Sichtbereich (aber nicht direkt auf der Kanone) ist:
	if dist > 60.0 and dist < 700.0:
		var dir := -1.0 if player_ref.global_position.x < global_position.x else 1.0
		var bullet := PlatformerBulletBill.new()
		bullet.direction = dir
		bullet.position = global_position + Vector2(dir * (PlatformerConfig.TILE_SIZE * 0.7), 0.0)
		bullet_fired.emit(bullet)
