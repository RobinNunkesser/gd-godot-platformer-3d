class_name PlatformerLevelManager
extends RefCounted

## PlatformerLevelManager
## Verwaltet Level-Sätze (Curated, Original SMB, Externe/Eigene Levels).
## Erstellt beim ersten Start automatisch den kanonischen Benutzerordner
## ~/Documents/Platformer3D/levels mit Dokumentation und Beispielen.

const SETTINGS_PATH := "user://settings.cfg"
const ENV_LEVELS_DIR := "PLATFORMER_LEVELS_DIR"

static var available_sets: Array[Dictionary] = []
static var current_set_index: int = 0
static var external_levels_dir: String = ""
static var _initialized: bool = false

# --- Pfad- und Verzeichnisverwaltung ---

static func canonical_documents_levels_dir() -> String:
	var doc_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if doc_dir.is_empty():
		return ""
	return doc_dir.path_join("Platformer3D/levels")

static func canonical_appdata_levels_dir() -> String:
	return OS.get_user_data_dir().path_join("levels")

static func ensure_default_levels_dir(custom_dir: String = "") -> String:
	var trimmed := custom_dir.strip_edges()
	if not trimmed.is_empty() and DirAccess.dir_exists_absolute(trimmed):
		return trimmed

	# 1. Umgebungsvariable (CI / Tests / Entwicklung)
	var env_dir := OS.get_environment(ENV_LEVELS_DIR).strip_edges()
	if not env_dir.is_empty():
		if DirAccess.dir_exists_absolute(env_dir):
			return env_dir

	# 2. Prüfen, ob Documents/Platformer3D/levels bereits existiert
	var docs_dir := canonical_documents_levels_dir()
	if not docs_dir.is_empty() and DirAccess.dir_exists_absolute(docs_dir):
		_ensure_readme(docs_dir)
		return docs_dir

	# 3. Documents/Platformer3D/levels anlegen
	if not docs_dir.is_empty():
		var err := DirAccess.make_dir_recursive_absolute(docs_dir)
		if err == OK or DirAccess.dir_exists_absolute(docs_dir):
			_ensure_readme(docs_dir)
			_ensure_sample_levels(docs_dir)
			return docs_dir

	# 4. Fallback: user://levels anlegen
	var user_dir := "user://levels"
	if not DirAccess.dir_exists_absolute(user_dir):
		DirAccess.make_dir_recursive_absolute(user_dir)
	_ensure_readme(user_dir)
	return user_dir

static func _ensure_readme(dir_path: String) -> void:
	var readme_file := dir_path.path_join("README.txt")
	if FileAccess.file_exists(readme_file):
		return

	var file := FileAccess.open(readme_file, FileAccess.WRITE)
	if not file:
		return

	var text := """=== Platformer 3D / 2D - Externe Level und Level-Sätze ===

Hier können Sie eigene Level und ganze Level-Sätze im ASCII-Format (VGLC-Standard) ablegen!

1. LEVEL-FORMAT (ASCII, 14 Zeilen hoch):
--------------------------------------------------------------------------------
X, x     = Fester Boden / Rumpfplatte
S, s     = Zerstörbarer Block / Frachtkiste
?, Q, q  = Fragezeichenblock (Holo-Würfel) mit Münze/Power-Up
<, >, [, ] = Röhren / Warp-Leitungen
E, e     = Gegner: Ratte / Goomba
K, k     = Gegner: Frosch / Koopa Troopa
B, b     = Gegner: Kanone / Bullet-Bill-Abschussbasis
P, p, y  = Gegner: Schlange / Piranha-Pflanze in Röhren
M, m     = Super-Pilz
f        = Feuerblume
*        = Super-Stern (Unverwundbarkeit)
o, O     = Goldmünze
F, |     = Ziel-Warpbake / Flaggenmast (optional; wird sonst automatisch ans Ende gesetzt)
-        = Leerer Raum / Luft
--------------------------------------------------------------------------------

2. LEVEL-SÄTZE (ORDNERSTRUKTUR):
- Einzelne .txt-Dateien direkt in diesem Ordner erscheinen als Satz 'Eigene Levels'.
- Jeder Unterordner (z. B. 'Welt 1', 'Hardcore Pack') wird automatisch als eigener
  Level-Satz erkannt und im Spielmenü zur Auswahl angeboten!

3. STEUERUNG IM SPIEL:
- Taste [K]: Nächsten Level-Satz wählen
- Taste [L]: Nächstes Level im aktuellen Satz wählen
- Im Start- und Pausemenü stehen Direktwahltasten bereit.
"""
	file.store_string(text)
	file.close()

static func _ensure_sample_levels(dir_path: String) -> void:
	var sample_path := dir_path.path_join("beispiel_level.txt")
	if FileAccess.file_exists(sample_path):
		return

	# Kopiere das erste kuratierte Level als bearbeitbare Vorlage
	if FileAccess.file_exists("res://levels/curated/level-1.txt"):
		var src := FileAccess.open("res://levels/curated/level-1.txt", FileAccess.READ)
		if src:
			var content := src.get_as_text()
			src.close()
			var dst := FileAccess.open(sample_path, FileAccess.WRITE)
			if dst:
				dst.store_string(content)
				dst.close()

# --- Level-Katalog und Scanning ---

static func init_catalog() -> void:
	load_settings()
	external_levels_dir = ensure_default_levels_dir(external_levels_dir)
	refresh_sets()

static func refresh_sets() -> void:
	available_sets.clear()

	# 1. Satz: Curated (5 Levels)
	var curated_levels := _scan_levels_in_dir("res://levels/curated", "Level ")
	if curated_levels.is_empty():
		curated_levels = _scan_levels_in_dir("res://levels", "Level ")
	if not curated_levels.is_empty():
		available_sets.append({
			"id": "curated",
			"name": "Standard / Curated (%d)" % curated_levels.size(),
			"dir_path": "res://levels/curated",
			"is_external": false,
			"levels": curated_levels
		})

	# 2. Satz: Original SMB (15 Levels)
	var original_levels := _scan_levels_in_dir("res://levels/original", "Welt ")
	if not original_levels.is_empty():
		available_sets.append({
			"id": "original",
			"name": "Original SMB (%d)" % original_levels.size(),
			"dir_path": "res://levels/original",
			"is_external": false,
			"levels": original_levels
		})

	# 3. Externe Level-Sätze scannen
	if not external_levels_dir.is_empty() and DirAccess.dir_exists_absolute(external_levels_dir):
		# 3a. Unterordner als eigenständige Level-Packs
		var dir := DirAccess.open(external_levels_dir)
		if dir:
			dir.list_dir_begin()
			var file_name := dir.get_next()
			while file_name != "":
				if dir.current_is_dir() and not file_name.begins_with("."):
					var sub_path := external_levels_dir.path_join(file_name)
					var sub_levels := _scan_levels_in_dir(sub_path)
					if not sub_levels.is_empty():
						available_sets.append({
							"id": "ext_" + file_name.to_lower().replace(" ", "_"),
							"name": "📁 %s (%d)" % [file_name, sub_levels.size()],
							"dir_path": sub_path,
							"is_external": true,
							"levels": sub_levels
						})
				file_name = dir.get_next()
			dir.list_dir_end()

		# 3b. Lose Leveldateien im Root-Ordner
		var root_levels := _scan_levels_in_dir(external_levels_dir)
		if not root_levels.is_empty():
			available_sets.append({
				"id": "external_root",
				"name": "📁 Eigene Levels (%d)" % root_levels.size(),
				"dir_path": external_levels_dir,
				"is_external": true,
				"levels": root_levels
			})

	# Validierung des aktuellen Index
	if current_set_index >= available_sets.size():
		current_set_index = 0
	_initialized = true

static func _scan_levels_in_dir(dir_path: String, prefix_label: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dir := DirAccess.open(dir_path)
	if not dir:
		return result

	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".txt") and not file_name.begins_with("README"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Natürliche Sortierung (z.B. level-1, level-2 ... bzw. mario-1-1, mario-1-2)
	files.sort_custom(func(a: String, b: String) -> bool:
		return _natural_compare(a, b)
	)

	for fname in files:
		var full_path := dir_path.path_join(fname)
		var base_name := fname.get_basename()
		var display := _format_display_name(base_name, prefix_label)
		result.append({
			"name": base_name,
			"display_name": display,
			"path": full_path
		})

	return result

static func _format_display_name(base_name: String, prefix_label: String) -> String:
	if base_name.begins_with("mario-"):
		var part := base_name.substr(6)
		return "Welt " + part
	if base_name.begins_with("level-"):
		var part := base_name.substr(6)
		return "Level " + part
	if not prefix_label.is_empty():
		return prefix_label + base_name.capitalize()
	return base_name.capitalize()

static func _natural_compare(a: String, b: String) -> bool:
	return a.naturalnocasecmp_to(b) < 0

# --- Navigation & Auswahl ---

static func get_available_sets() -> Array[Dictionary]:
	if not _initialized or available_sets.is_empty():
		init_catalog()
	return available_sets

static func get_current_set() -> Dictionary:
	var sets := get_available_sets()
	if sets.is_empty():
		return {}
	current_set_index = clampi(current_set_index, 0, sets.size() - 1)
	return sets[current_set_index]

static func get_current_set_name() -> String:
	var s := get_current_set()
	return str(s.get("name", "Kein Satz"))

static func get_current_levels() -> Array[Dictionary]:
	var s := get_current_set()
	var levels_arr: Array[Dictionary] = []
	for item in s.get("levels", []):
		levels_arr.append(item as Dictionary)
	return levels_arr

static func get_level_count() -> int:
	return get_current_levels().size()

static func get_level_path(idx: int) -> String:
	var levels := get_current_levels()
	if levels.is_empty():
		return "res://levels/level-1.txt"
	var clamped: int = clampi(idx, 0, levels.size() - 1)
	return str(levels[clamped].get("path", ""))

static func get_level_display_name(idx: int) -> String:
	var levels := get_current_levels()
	if levels.is_empty():
		return "Level 1"
	var clamped: int = clampi(idx, 0, levels.size() - 1)
	return str(levels[clamped].get("display_name", levels[clamped].get("name", "Level %d" % (idx + 1))))

static func cycle_set() -> Dictionary:
	var sets := get_available_sets()
	if sets.is_empty():
		return {}
	current_set_index = (current_set_index + 1) % sets.size()
	save_settings()
	return get_current_set()

static func select_set_by_id(set_id: String) -> bool:
	var sets := get_available_sets()
	for i in range(sets.size()):
		if sets[i].get("id") == set_id:
			current_set_index = i
			save_settings()
			return true
	return false

static func cycle_level(current_idx: int) -> int:
	var count := get_level_count()
	if count <= 0:
		return 0
	return (current_idx + 1) % count

# --- Einstellungen & Persistenz ---

static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	var current := get_current_set()
	cfg.set_value("levels", "set_id", current.get("id", "curated"))
	cfg.set_value("levels", "external_dir", external_levels_dir)
	cfg.save(SETTINGS_PATH)

static func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err == OK:
		var saved_dir: String = str(cfg.get_value("levels", "external_dir", ""))
		if not saved_dir.is_empty():
			external_levels_dir = saved_dir
		var saved_set: String = str(cfg.get_value("levels", "set_id", "curated"))
		_saved_set_id = saved_set

static var _saved_set_id: String = ""

static func apply_saved_set() -> void:
	if not _saved_set_id.is_empty():
		select_set_by_id(_saved_set_id)
