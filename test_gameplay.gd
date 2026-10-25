extends SceneTree

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerStateManager = preload("res://scripts/state_manager.gd")
const TileMapLoader = preload("res://scripts/tilemap_loader.gd")
const PlatformerPlayer = preload("res://scripts/player.gd")

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const TileMapLoader3D = preload("res://scripts/tilemap_loader_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")

const PlatformerEnemy = preload("res://scripts/enemy.gd")
const PlatformerKoopa = preload("res://scripts/enemy_koopa.gd")
const PlatformerBulletBill = preload("res://scripts/bullet_bill.gd")
const PlatformerCannon = preload("res://scripts/cannon.gd")
const PlatformerPiranhaPlant = preload("res://scripts/piranha_plant.gd")
const PlatformerFireball = preload("res://scripts/fireball.gd")

const PlatformerEnemy3D = preload("res://scripts/enemy_3d.gd")
const PlatformerKoopa3D = preload("res://scripts/enemy_koopa_3d.gd")
const PlatformerBulletBill3D = preload("res://scripts/bullet_bill_3d.gd")
const PlatformerCannon3D = preload("res://scripts/cannon_3d.gd")
const PlatformerPiranhaPlant3D = preload("res://scripts/piranha_plant_3d.gd")
const PlatformerFireball3D = preload("res://scripts/fireball_3d.gd")
const PlatformerControls = preload("res://scripts/controls.gd")

func _init() -> void:
	print("--- Running Headless Godot 4 Unit & Gameplay Tests (2D & 3D) ---")
	var success := true

	# Test 1: PlatformerConfig
	print("[1/7] Testing PlatformerConfig (2D & 3D)...")
	if PlatformerConfig.TILE_SIZE <= 0 or PlatformerConfig.GRAVITY <= 0 or PlatformerConfig.JUMP_FORCE >= 0:
		push_error("2D Config constants invalid!")
		success = false
	if PlatformerConfig3D.TILE_SIZE <= 0 or PlatformerConfig3D.GRAVITY <= 0 or PlatformerConfig3D.JUMP_FORCE <= 0:
		push_error("3D Config constants invalid!")
		success = false
	if success:
		print("  -> Config constants OK.")

	# Test 2: PlatformerStateManager
	print("[2/7] Testing PlatformerStateManager...")
	var sm = PlatformerStateManager.new()
	sm.reset()
	if sm.get_state_string() != "READY":
		push_error("StateManager did not start in READY!")
		success = false
	sm.start()
	if sm.get_state_string() != "PLAYING":
		push_error("StateManager did not transition to PLAYING!")
		success = false
	sm.add_coin()
	if sm.coins != 1 or sm.score != 100:
		push_error("add_coin failed to update stats!")
		success = false
	sm.win()
	if sm.get_state_string() != "VICTORY":
		push_error("StateManager did not transition to VICTORY!")
		success = false
	print("  -> StateManager OK.")

	# Test 3: TileMapLoader 2D (All 5 Curated Levels)
	print("[3/7] Testing TileMapLoader (2D) on all 5 curated levels...")
	var loader = TileMapLoader.new()
	root.add_child(loader)
	for i in range(1, 6):
		var path := "res://levels/level-%d.txt" % i
		var loaded: bool = loader.load_level_from_file(path)
		if not loaded or loader.level_height_rows != 14 or loader.level_width_cols < 100:
			push_error("2D Loader failed on " + path)
			success = false
		else:
			print("  -> Level %d parsed: %d rows x %d cols (%d enemies) OK." % [i, loader.level_height_rows, loader.level_width_cols, loader.enemies.size()])
	loader.queue_free()

	# Test 4: Player 2D Kinematics
	print("[4/7] Testing Player 2D Kinematics...")
	var player_scene = preload("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	player.reset_position(Vector2(100.0, 500.0))
	for i in range(5):
		player.update_kinematics(0.016, false, true, false, false)
	player.coyote_timer = PlatformerConfig.COYOTE_TIME_SEC
	player.update_kinematics(0.016, false, false, true, true)
	if player.velocity.y >= 0:
		push_error("Player 2D jump failed!")
		success = false
	else:
		print("  -> Player 2D kinematics OK.")
	player.queue_free()

	# Test 5: TileMapLoader 3D & Player 3D (All 5 Curated Levels)
	print("[5/7] Testing 3D Pipeline (TileMapLoader3D & Player3D on 5 levels)...")
	var loader3d = TileMapLoader3D.new()
	root.add_child(loader3d)
	for i in range(1, 6):
		var path := "res://levels/level-%d.txt" % i
		var loaded3d: bool = loader3d.load_level_from_file(path)
		if not loaded3d or loader3d.level_height_rows != 14 or loader3d.level_width_cols < 100:
			push_error("3D Loader failed on " + path)
			success = false
		else:
			print("  -> Level %d 3D parsed: %d rows x %d cols (%d question blocks, %d enemies) OK." % [
				i,
				loader3d.level_height_rows,
				loader3d.level_width_cols,
				loader3d.question_blocks.size(),
				loader3d.enemies.size()
			])
	loader3d.queue_free()

	var player3d_scene = preload("res://scenes/player_3d.tscn")
	var player3d = player3d_scene.instantiate()
	root.add_child(player3d)
	player3d.reset_position(Vector3(2.5, 1.5, 0.0))
	for i in range(5):
		player3d.update_kinematics(0.016, false, true, false, false)
	player3d.coyote_timer = PlatformerConfig3D.COYOTE_TIME_SEC
	player3d.update_kinematics(0.016, false, false, true, true)
	if player3d.velocity.y <= 0:
		push_error("Player 3D jump failed! velocity.y = " + str(player3d.velocity.y))
		success = false
	else:
		print("  -> Player 3D kinematics OK (velocity.y = %f)." % player3d.velocity.y)

	# Test 6: Enemies & Power-Ups (2D & 3D)
	print("[6/7] Testing Enemies & Power-Ups (2D & 3D)...")
	var player2d_inst = player_scene.instantiate()
	root.add_child(player2d_inst)
	player2d_inst.reset_position()

	# Test 6a: Power-Up
	player2d_inst.power_up()
	if not player2d_inst.is_big:
		push_error("Player did not grow big after power_up()!")
		success = false
	else:
		print("  -> 2D Power-up growth OK.")

	# Test 6b: Taking damage when big
	var killed = player2d_inst.take_damage()
	if killed or player2d_inst.is_big or not player2d_inst.is_invulnerable:
		push_error("Taking damage when big should shrink player and grant invulnerability without dying!")
		success = false
	else:
		print("  -> 2D Big Player armor/shrink on damage OK.")

	# Test 6c: Taking damage when small
	player2d_inst.is_invulnerable = false
	var small_killed = player2d_inst.take_damage()
	if not small_killed:
		push_error("Small player should be killed on damage!")
		success = false
	else:
		print("  -> 2D Small Player death on damage OK.")

	# Test 6d: Enemy Stomp Bounce
	player2d_inst.bounce_after_stomp()
	if player2d_inst.velocity.y >= 0:
		push_error("bounce_after_stomp failed to apply upward velocity!")
		success = false
	else:
		print("  -> 2D Stomp bounce impulse OK.")

	# Test 6e: 3D Power-Up & Damage
	player3d.power_up()
	if not player3d.is_big:
		push_error("Player 3D did not grow big!")
		success = false
	var p3d_killed = player3d.take_damage()
	if p3d_killed or player3d.is_big:
		push_error("Player 3D armor failed!")
		success = false
	else:
		print("  -> 3D Power-up and armor OK.")

	# Test 6f: Fire Flower Power-up & Fireball Shooting (2D)
	player2d_inst.power_up_flower()
	if not player2d_inst.is_fire or not player2d_inst.is_big:
		push_error("Player did not become FIRE state after power_up_flower()!")
		success = false
	var shot_fired := [false]
	var fireball_cb = func(_pos: Vector2, _dir: float):
		shot_fired[0] = true
	player2d_inst.fireball_requested.connect(fireball_cb)
	player2d_inst.shoot()
	if not shot_fired[0]:
		push_error("Player 2D shoot() failed to emit fireball_requested!")
		success = false
	else:
		print("  -> 2D Fire Flower & Fireball shooting OK.")

	# Test 6g: Super Star (Starman) Invincibility (2D)
	player2d_inst.power_up_star(10.0)
	if not player2d_inst.is_starman or player2d_inst.star_timer <= 0:
		push_error("Player 2D did not enter Starman mode!")
		success = false
	var dmg_blocked = player2d_inst.take_damage()
	if dmg_blocked or not player2d_inst.is_fire:
		push_error("Starman should be impervious to damage without losing Fire state!")
		success = false
	else:
		print("  -> 2D Super Star invincibility OK.")

	# Test 6h: Koopa Troopa Stomp & Shell Kick (2D)
	var koopa = PlatformerKoopa.new()
	root.add_child(koopa)
	if koopa.current_state != PlatformerKoopa.State.WALKING:
		push_error("Koopa did not start in WALKING state!")
		success = false
	koopa.take_stomp(player2d_inst)
	if koopa.current_state != PlatformerKoopa.State.SHELL_IDLE:
		push_error("Koopa stomp failed to enter SHELL_IDLE state!")
		success = false
	koopa.kick_shell(player2d_inst)
	if koopa.current_state != PlatformerKoopa.State.SHELL_SLIDING:
		push_error("Koopa kick failed to enter SHELL_SLIDING state!")
		success = false
	else:
		print("  -> 2D Koopa Troopa stomp & shell sliding OK.")
	koopa.queue_free()

	# Test 6i: Cannon & Bullet Bill Launch & Stomp (2D)
	var cannon = PlatformerCannon.new()
	cannon.is_top = true
	cannon.position = Vector2(200.0, 500.0)
	player2d_inst.position = Vector2(350.0, 500.0)
	root.add_child(cannon)
	cannon.fire_timer = 0.05
	var bb_fired := [false]
	cannon.bullet_fired.connect(func(_bb): bb_fired[0] = true)
	cannon.update_cannon(0.1, player2d_inst)
	if not bb_fired[0]:
		push_error("PlatformerCannon failed to fire Bullet Bill!")
		success = false
	var bullet = PlatformerBulletBill.new()
	root.add_child(bullet)
	bullet.take_stomp(player2d_inst)
	if not bullet.is_dead:
		push_error("Bullet Bill stomp failed to defeat bullet!")
		success = false
	else:
		print("  -> 2D Cannon & Bullet Bill mechanics OK.")
	cannon.queue_free()
	bullet.queue_free()

	# Test 6j: Piranha Plant Defeat (2D)
	var piranha = PlatformerPiranhaPlant.new()
	root.add_child(piranha)
	piranha.take_fireball()
	if not piranha.is_dead:
		push_error("Piranha plant failed to die from fireball!")
		success = false
	else:
		print("  -> 2D Piranha Plant mechanics OK.")
	piranha.queue_free()

	# Test 6k: 3D Fire Flower, Starman & Koopa 3D
	player3d.power_up_flower()
	if not player3d.is_fire or not player3d.is_big:
		push_error("Player 3D did not become FIRE state!")
		success = false
	player3d.power_up_star(10.0)
	if not player3d.is_starman:
		push_error("Player 3D Starman failed!")
		success = false
	var koopa3d = PlatformerKoopa3D.new()
	root.add_child(koopa3d)
	koopa3d.take_stomp(player3d)
	if koopa3d.current_state != PlatformerKoopa3D.State.SHELL_IDLE:
		push_error("Koopa 3D stomp failed to enter SHELL_IDLE!")
		success = false
	else:
		print("  -> 3D Fire Flower, Starman, and Koopa 3D OK.")
	# Test 6l: update_enemy with player parameter across all 2D & 3D enemies
	var g2d = PlatformerEnemy.new()
	root.add_child(g2d)
	g2d.update_enemy(0.016, player2d_inst)
	g2d.queue_free()

	var k2d = PlatformerKoopa.new()
	root.add_child(k2d)
	k2d.update_enemy(0.016, player2d_inst)
	k2d.queue_free()

	var b2d = PlatformerBulletBill.new()
	root.add_child(b2d)
	b2d.update_enemy(0.016, player2d_inst)
	b2d.queue_free()

	var p2d = PlatformerPiranhaPlant.new()
	root.add_child(p2d)
	p2d.update_enemy(0.016, player2d_inst)
	p2d.queue_free()

	var g3d = PlatformerEnemy3D.new()
	root.add_child(g3d)
	g3d.update_enemy(0.016, player3d)
	g3d.queue_free()

	var k3d = PlatformerKoopa3D.new()
	root.add_child(k3d)
	k3d.update_enemy(0.016, player3d)
	k3d.queue_free()

	var b3d = PlatformerBulletBill3D.new()
	root.add_child(b3d)
	b3d.update_enemy(0.016, player3d)
	b3d.queue_free()

	var p3d = PlatformerPiranhaPlant3D.new()
	root.add_child(p3d)
	p3d.update_enemy(0.016, player3d)
	p3d.queue_free()

	print("  -> update_enemy(delta, player) across all 2D & 3D enemies OK.")

	player2d_inst.queue_free()
	player3d.queue_free()

	# Test 7: PlatformerControls Schemes
	print("[7/7] Testing PlatformerControls schemes & dynamic switching...")
	PlatformerControls.set_scheme(PlatformerControls.Scheme.KEYBOARD_1)
	if PlatformerControls.current_scheme != PlatformerControls.Scheme.KEYBOARD_1:
		push_error("Failed to set KEYBOARD_1 scheme!")
		success = false
	if not InputMap.has_action("move_left") or not InputMap.has_action("jump") or not InputMap.has_action("shoot"):
		push_error("InputMap missing actions after applying KEYBOARD_1!")
		success = false

	var s2 = PlatformerControls.cycle_scheme()
	if s2 != PlatformerControls.Scheme.KEYBOARD_2:
		push_error("Cycle scheme did not advance to KEYBOARD_2!")
		success = false

	var s3 = PlatformerControls.cycle_scheme()
	if s3 != PlatformerControls.Scheme.GAMEPAD:
		push_error("Cycle scheme did not advance to GAMEPAD!")
		success = false

	var s4 = PlatformerControls.cycle_scheme()
	if s4 != PlatformerControls.Scheme.ALL:
		push_error("Cycle scheme did not advance to ALL!")
		success = false

	var s1 = PlatformerControls.cycle_scheme()
	if s1 != PlatformerControls.Scheme.KEYBOARD_1:
		push_error("Cycle scheme did not cycle back to KEYBOARD_1!")
		success = false
	print("  -> PlatformerControls scheme cycling & InputMap OK.")

	if success:
		print("=== ALL GODOT 4 TESTS (2D & 3D) PASSED SUCCESSFULLY! ===")
		quit(0)
	else:
		push_error("=== TESTS FAILED! ===")
		quit(1)
