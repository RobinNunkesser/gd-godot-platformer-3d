class_name PlatformerControls
extends RefCounted

## PlatformerControls
## Verwaltet konfigurierbare Steuerungsschemata (Tastatur 1, Tastatur 2, Gamepad, Alle)
## und aktualisiert die Godot InputMap dynamisch.

enum Scheme {
	KEYBOARD_1, # Tastatur 1: WASD + Space/W, Shift/F/J
	KEYBOARD_2, # Tastatur 2: Pfeiltasten + Up/Strg, Enter/Numpad
	GAMEPAD,    # Gamepad: Stick/D-Pad, A zum Springen, X/B zum Schießen
	ALL         # Alle Eingabemethoden aktiv (Kombiniert)
}

const SCHEME_NAMES = {
	Scheme.KEYBOARD_1: "Tastatur 1 (WASD + Space/Shift)",
	Scheme.KEYBOARD_2: "Tastatur 2 (Pfeile + Strg/Enter)",
	Scheme.GAMEPAD: "Gamepad (Stick/D-Pad + A/X)",
	Scheme.ALL: "Alle aktiv (Kombiniert)"
}

const SCHEME_INSTRUCTIONS = {
	Scheme.KEYBOARD_1: "A / D: Laufen  |  Leertaste / W: Springen  |  Shift / F / X: Schießen\nP: Pause  |  R: Reset  |  C: Steuerung  |  K: Level-Satz  |  L: Level",
	Scheme.KEYBOARD_2: "Pfeiltasten ← / →: Laufen  |  Pfeil ↑ / Strg: Springen  |  Enter / 0: Schießen\nP: Pause  |  R: Reset  |  C: Steuerung  |  K: Level-Satz  |  L: Level",
	Scheme.GAMEPAD: "Stick / D-Pad: Laufen  |  Button A: Springen  |  Button X / B / RT: Schießen\nStart: Pause  |  Select: Reset  |  LB: Steuerung  |  K / L: Level",
	Scheme.ALL: "WASD / Pfeile / Stick: Laufen  |  Space / W / ↑ / A: Springen  |  Shift / F / Enter: Schießen\nP: Pause  |  R: Reset  |  C: Steuerung  |  K: Level-Satz  |  L: Level"
}

static var current_scheme: Scheme = Scheme.ALL

static func init_default() -> void:
	apply_scheme(current_scheme)

static func set_scheme(scheme: Scheme) -> void:
	current_scheme = scheme
	apply_scheme(current_scheme)

static func cycle_scheme() -> Scheme:
	match current_scheme:
		Scheme.ALL:
			current_scheme = Scheme.KEYBOARD_1
		Scheme.KEYBOARD_1:
			current_scheme = Scheme.KEYBOARD_2
		Scheme.KEYBOARD_2:
			current_scheme = Scheme.GAMEPAD
		Scheme.GAMEPAD:
			current_scheme = Scheme.ALL
	apply_scheme(current_scheme)
	return current_scheme

static func get_scheme_name(scheme: Scheme = current_scheme) -> String:
	return SCHEME_NAMES.get(scheme, "Unbekannt")

static func get_scheme_instructions(scheme: Scheme = current_scheme) -> String:
	return SCHEME_INSTRUCTIONS.get(scheme, "")

static func _make_key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	return ev

static func _make_joy_button(btn: JoyButton, dev: int = -1) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = btn
	ev.device = dev
	return ev

static func _make_joy_motion(axis: JoyAxis, val: float, dev: int = -1) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = val
	ev.device = dev
	return ev

static func apply_scheme(scheme: Scheme) -> void:
	var actions := ["move_left", "move_right", "jump", "shoot", "pause", "restart", "cycle_controls", "cycle_level_set", "cycle_level"]
	for a in actions:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		InputMap.action_erase_events(a)

	# Taste C / LB wechselt das Schema
	InputMap.action_add_event("cycle_controls", _make_key(KEY_C))
	InputMap.action_add_event("cycle_controls", _make_joy_button(JOY_BUTTON_LEFT_SHOULDER))

	# Tasten K & L für Level-Satz und Level
	InputMap.action_add_event("cycle_level_set", _make_key(KEY_K))
	InputMap.action_add_event("cycle_level", _make_key(KEY_L))

	match scheme:
		Scheme.KEYBOARD_1:
			InputMap.action_add_event("move_left", _make_key(KEY_A))
			InputMap.action_add_event("move_right", _make_key(KEY_D))
			InputMap.action_add_event("jump", _make_key(KEY_SPACE))
			InputMap.action_add_event("jump", _make_key(KEY_W))
			InputMap.action_add_event("shoot", _make_key(KEY_SHIFT))
			InputMap.action_add_event("shoot", _make_key(KEY_F))
			InputMap.action_add_event("shoot", _make_key(KEY_X))
			InputMap.action_add_event("shoot", _make_key(KEY_J))
			InputMap.action_add_event("pause", _make_key(KEY_P))
			InputMap.action_add_event("pause", _make_key(KEY_ESCAPE))
			InputMap.action_add_event("restart", _make_key(KEY_R))

		Scheme.KEYBOARD_2:
			InputMap.action_add_event("move_left", _make_key(KEY_LEFT))
			InputMap.action_add_event("move_right", _make_key(KEY_RIGHT))
			InputMap.action_add_event("jump", _make_key(KEY_UP))
			InputMap.action_add_event("jump", _make_key(KEY_CTRL))
			InputMap.action_add_event("jump", _make_key(KEY_KP_0))
			InputMap.action_add_event("shoot", _make_key(KEY_ENTER))
			InputMap.action_add_event("shoot", _make_key(KEY_KP_ENTER))
			InputMap.action_add_event("shoot", _make_key(KEY_KP_1))
			InputMap.action_add_event("pause", _make_key(KEY_P))
			InputMap.action_add_event("pause", _make_key(KEY_ESCAPE))
			InputMap.action_add_event("restart", _make_key(KEY_R))

		Scheme.GAMEPAD:
			InputMap.action_add_event("move_left", _make_joy_motion(JOY_AXIS_LEFT_X, -1.0))
			InputMap.action_add_event("move_left", _make_joy_button(JOY_BUTTON_DPAD_LEFT))
			InputMap.action_add_event("move_right", _make_joy_motion(JOY_AXIS_LEFT_X, 1.0))
			InputMap.action_add_event("move_right", _make_joy_button(JOY_BUTTON_DPAD_RIGHT))
			InputMap.action_add_event("jump", _make_joy_button(JOY_BUTTON_A))
			InputMap.action_add_event("jump", _make_joy_button(JOY_BUTTON_Y))
			InputMap.action_add_event("shoot", _make_joy_button(JOY_BUTTON_X))
			InputMap.action_add_event("shoot", _make_joy_button(JOY_BUTTON_B))
			InputMap.action_add_event("shoot", _make_joy_motion(JOY_AXIS_TRIGGER_RIGHT, 1.0))
			InputMap.action_add_event("pause", _make_joy_button(JOY_BUTTON_START))
			InputMap.action_add_event("pause", _make_key(KEY_P))
			InputMap.action_add_event("restart", _make_joy_button(JOY_BUTTON_BACK))
			InputMap.action_add_event("restart", _make_key(KEY_R))

		Scheme.ALL:
			# Tastatur 1
			InputMap.action_add_event("move_left", _make_key(KEY_A))
			InputMap.action_add_event("move_right", _make_key(KEY_D))
			InputMap.action_add_event("jump", _make_key(KEY_SPACE))
			InputMap.action_add_event("jump", _make_key(KEY_W))
			InputMap.action_add_event("shoot", _make_key(KEY_SHIFT))
			InputMap.action_add_event("shoot", _make_key(KEY_F))
			InputMap.action_add_event("shoot", _make_key(KEY_X))
			InputMap.action_add_event("shoot", _make_key(KEY_J))
			# Tastatur 2
			InputMap.action_add_event("move_left", _make_key(KEY_LEFT))
			InputMap.action_add_event("move_right", _make_key(KEY_RIGHT))
			InputMap.action_add_event("jump", _make_key(KEY_UP))
			InputMap.action_add_event("jump", _make_key(KEY_CTRL))
			InputMap.action_add_event("shoot", _make_key(KEY_ENTER))
			InputMap.action_add_event("shoot", _make_key(KEY_KP_ENTER))
			# Gamepad
			InputMap.action_add_event("move_left", _make_joy_motion(JOY_AXIS_LEFT_X, -1.0))
			InputMap.action_add_event("move_left", _make_joy_button(JOY_BUTTON_DPAD_LEFT))
			InputMap.action_add_event("move_right", _make_joy_motion(JOY_AXIS_LEFT_X, 1.0))
			InputMap.action_add_event("move_right", _make_joy_button(JOY_BUTTON_DPAD_RIGHT))
			InputMap.action_add_event("jump", _make_joy_button(JOY_BUTTON_A))
			InputMap.action_add_event("jump", _make_joy_button(JOY_BUTTON_Y))
			InputMap.action_add_event("shoot", _make_joy_button(JOY_BUTTON_X))
			InputMap.action_add_event("shoot", _make_joy_button(JOY_BUTTON_B))
			InputMap.action_add_event("shoot", _make_joy_motion(JOY_AXIS_TRIGGER_RIGHT, 1.0))
			InputMap.action_add_event("pause", _make_key(KEY_P))
			InputMap.action_add_event("pause", _make_key(KEY_ESCAPE))
			InputMap.action_add_event("pause", _make_joy_button(JOY_BUTTON_START))
			InputMap.action_add_event("restart", _make_key(KEY_R))
			InputMap.action_add_event("restart", _make_joy_button(JOY_BUTTON_BACK))
