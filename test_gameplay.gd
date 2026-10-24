extends SceneTree

const PlatformerConfig = preload("res://scripts/config.gd")
const PlatformerStateManager = preload("res://scripts/state_manager.gd")
const TileMapLoader = preload("res://scripts/tilemap_loader.gd")
const PlatformerPlayer = preload("res://scripts/player.gd")

const PlatformerConfig3D = preload("res://scripts/config_3d.gd")
const TileMapLoader3D = preload("res://scripts/tilemap_loader_3d.gd")
const PlatformerPlayer3D = preload("res://scripts/player_3d.gd")

func _init() -> void:
	print("--- Running Headless Godot 4 Unit & Gameplay Tests (2D & 3D) ---")
	var success := true

	# Test 1: PlatformerConfig
	print("[1/6] Testing PlatformerConfig (2D & 3D)...")
	if PlatformerConfig.TILE_SIZE <= 0 or PlatformerConfig.GRAVITY <= 0 or PlatformerConfig.JUMP_FORCE >= 0:
		push_error("2D Config constants invalid!")
		success = false
	if PlatformerConfig3D.TILE_SIZE <= 0 or PlatformerConfig3D.GRAVITY <= 0 or PlatformerConfig3D.JUMP_FORCE <= 0:
		push_error("3D Config constants invalid!")
		success = false
	if success:
		print("  -> Config constants OK.")

	# Test 2: PlatformerStateManager
	print("[2/6] Testing PlatformerStateManager...")
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
	print("[3/6] Testing TileMapLoader (2D) on all 5 curated levels...")
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
	print("[4/6] Testing Player 2D Kinematics...")
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
	print("[5/6] Testing 3D Pipeline (TileMapLoader3D & Player3D on 5 levels)...")
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
	print("[6/6] Testing Enemies & Power-Ups (2D & 3D)...")
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

	player2d_inst.queue_free()
	player3d.queue_free()

	if success:
		print("=== ALL GODOT 4 TESTS (2D & 3D) PASSED SUCCESSFULLY! ===")
		quit(0)
	else:
		push_error("=== TESTS FAILED! ===")
		quit(1)
