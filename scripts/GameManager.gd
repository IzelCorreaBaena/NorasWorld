extends Node

# ── ESTADO DEL JUEGO ─────────────────────────
var current_level    : String  = "res://scenes/levels/W1_L1.tscn"
var checkpoint_pos   : Vector2 = Vector2.ZERO
var pins_collected   : Array[String] = []
var outfits_unlocked : Array[String] = ["default"]
var current_outfit   : String  = "default"
var worlds_completed : Array[int]    = []

# ── PROGRESO POR NIVEL ────────────────────────
var levels_completed  : Array[String] = []   # "W1_L1", "W1_L2"...
var best_times        : Dictionary    = {}   # {"W1_L1": 83.2}
var no_damage_levels  : Array[String] = []
var ng_plus_active    : bool          = false
var ng_plus_run       : int           = 0
var boss_rush_record  : int           = 0    # bosses derrotados en un run
var daily_score       : int           = 0
var daily_date        : String        = ""

var nora := {
	"health"         : 3,
	"max_health"     : 3,
	"has_double_jump": false,
	"has_dash"       : false,
	"has_wall_jump"  : false,
}

# ── SIGNALS ──────────────────────────────────
signal health_changed(new_health: int)
signal pin_collected(pin_id: String)
signal outfit_unlocked(outfit_id: String)
signal outfit_changed(outfit_id: String)
signal world_completed(world_id: int)
signal level_completed(level_key: String)
signal game_over

const SAVE_PATH := "user://noras_world.cfg"

func _ready() -> void:
	load_game()

# ── SALUD ────────────────────────────────────
func take_damage(amount: int = 1) -> void:
	nora["health"] = max(0, nora["health"] - amount)
	emit_signal("health_changed", nora["health"])
	if nora["health"] <= 0:
		emit_signal("game_over")

func heal(amount: int = 1) -> void:
	nora["health"] = min(nora["max_health"], nora["health"] + amount)
	emit_signal("health_changed", nora["health"])

func restore_full_health() -> void:
	nora["health"] = nora["max_health"]
	emit_signal("health_changed", nora["health"])

func set_checkpoint(scene_path: String, pos: Vector2) -> void:
	current_level  = scene_path
	checkpoint_pos = pos

func clear_checkpoint() -> void:
	checkpoint_pos = Vector2.ZERO

# ── PINES ────────────────────────────────────
func collect_pin(pin_id: String) -> void:
	if pin_id not in pins_collected:
		pins_collected.append(pin_id)
		emit_signal("pin_collected", pin_id)
		save_game()

func has_pin(pin_id: String) -> bool:
	return pin_id in pins_collected

func pins_in_world(world_id: int) -> int:
	# Cuenta pines del formato antiguo (pin_worldN_XX) y nuevo (pin_WN_LM_XX)
	var old_prefix := "pin_world%d_" % world_id
	var new_prefix := "pin_W%d_" % world_id
	var count := 0
	for p in pins_collected:
		if p.begins_with(old_prefix) or p.begins_with(new_prefix):
			count += 1
	return count

func total_pins_in_world(world_id: int) -> int:
	# 5 niveles × 5 pines = 25 + boss pin ya incluido en normal = 25 total
	# (nivel 1-4: 4 pines en escena + 1 del boss; nivel 5: boss da el pin)
	# Simplificado: 25 pines por mundo
	return 25

# ── MUNDOS ───────────────────────────────────
func complete_world(world_id: int) -> void:
	if world_id not in worlds_completed:
		worlds_completed.append(world_id)
		emit_signal("world_completed", world_id)
		_grant_world_rewards(world_id)
		save_game()

func is_world_unlocked(world_id: int) -> bool:
	if world_id == 1:
		return true
	if world_id == 5:
		# Mundo secreto: 2 mundos normales al 100% (todos los pines)
		var full := 0
		for w in range(1, 5):
			if pins_in_world(w) >= total_pins_in_world(w):
				full += 1
		return full >= 2
	return (world_id - 1) in worlds_completed

func _grant_world_rewards(world_id: int) -> void:
	match world_id:
		1:
			nora["has_double_jump"] = true
			unlock_outfit("surfera")
		2:
			nora["has_dash"] = true
			unlock_outfit("fashion_week")
		3:
			nora["has_wall_jump"] = true
			unlock_outfit("tribal")
		4:
			unlock_outfit("estilista_pro")

# ── NIVELES ───────────────────────────────────
func complete_level(level_key: String) -> void:
	if level_key != "" and level_key not in levels_completed:
		levels_completed.append(level_key)
		emit_signal("level_completed", level_key)
		save_game()

func has_level_completed(level_key: String) -> bool:
	return level_key in levels_completed

func is_level_unlocked(world_id: int, level_num: int) -> bool:
	if level_num == 1:
		return is_world_unlocked(world_id)
	var prev_key := "W%d_L%d" % [world_id, level_num - 1]
	return has_level_completed(prev_key)

func set_best_time(level_key: String, t: float) -> void:
	if not level_key in best_times or t < best_times[level_key]:
		best_times[level_key] = t
		save_game()

func get_best_time(level_key: String) -> float:
	return best_times.get(level_key, 0.0)

func set_no_damage(level_key: String) -> void:
	if level_key not in no_damage_levels:
		no_damage_levels.append(level_key)
		save_game()

func has_no_damage(level_key: String) -> bool:
	return level_key in no_damage_levels

# ── OUTFITS ──────────────────────────────────
func unlock_outfit(outfit_id: String) -> void:
	if outfit_id not in outfits_unlocked:
		outfits_unlocked.append(outfit_id)
		emit_signal("outfit_unlocked", outfit_id)
		save_game()

func set_outfit(outfit_id: String) -> void:
	if outfit_id in outfits_unlocked:
		current_outfit = outfit_id
		emit_signal("outfit_changed", outfit_id)
		save_game()

# ── HABILIDADES ──────────────────────────────
func unlock_double_jump() -> void: nora["has_double_jump"] = true
func unlock_dash()        -> void: nora["has_dash"]        = true
func unlock_wall_jump()   -> void: nora["has_wall_jump"]   = true

# ── GUARDAR / CARGAR ─────────────────────────
func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "pins",             pins_collected)
	cfg.set_value("progress", "outfits",          outfits_unlocked)
	cfg.set_value("progress", "outfit",           current_outfit)
	cfg.set_value("progress", "worlds",           worlds_completed)
	cfg.set_value("progress", "double_jump",      nora["has_double_jump"])
	cfg.set_value("progress", "dash",             nora["has_dash"])
	cfg.set_value("progress", "wall_jump",        nora["has_wall_jump"])
	cfg.set_value("progress", "levels",           levels_completed)
	cfg.set_value("progress", "best_times",       best_times)
	cfg.set_value("progress", "no_damage",        no_damage_levels)
	cfg.set_value("progress", "ng_plus",          ng_plus_active)
	cfg.set_value("progress", "ng_plus_run",      ng_plus_run)
	cfg.set_value("progress", "boss_rush_record", boss_rush_record)
	cfg.save(SAVE_PATH)

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	pins_collected          = cfg.get_value("progress", "pins",             [])
	outfits_unlocked        = cfg.get_value("progress", "outfits",          ["default"])
	current_outfit          = cfg.get_value("progress", "outfit",           "default")
	worlds_completed        = cfg.get_value("progress", "worlds",           [])
	nora["has_double_jump"] = cfg.get_value("progress", "double_jump",      false)
	nora["has_dash"]        = cfg.get_value("progress", "dash",             false)
	nora["has_wall_jump"]   = cfg.get_value("progress", "wall_jump",        false)
	levels_completed        = cfg.get_value("progress", "levels",           [])
	best_times              = cfg.get_value("progress", "best_times",       {})
	no_damage_levels        = cfg.get_value("progress", "no_damage",        [])
	ng_plus_active          = cfg.get_value("progress", "ng_plus",          false)
	ng_plus_run             = cfg.get_value("progress", "ng_plus_run",      0)
	boss_rush_record        = cfg.get_value("progress", "boss_rush_record", 0)

func reset() -> void:
	pins_collected   = []
	outfits_unlocked = ["default"]
	current_outfit   = "default"
	worlds_completed = []
	levels_completed = []
	best_times       = {}
	no_damage_levels = []
	ng_plus_active   = false
	ng_plus_run      = 0
	boss_rush_record = 0
	nora["health"]          = nora["max_health"]
	nora["has_double_jump"] = false
	nora["has_dash"]        = false
	nora["has_wall_jump"]   = false
	emit_signal("health_changed", nora["health"])
	save_game()
