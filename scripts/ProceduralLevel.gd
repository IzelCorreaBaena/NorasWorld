extends Node2D
# Nodo raíz de todos los niveles normales (W1_L1 a W5_L5).
# Lee un LevelData resource y construye el nivel en _ready().
# La geometría de plataformas está en el .tscn hijo "Platforms".

const PIN_SCENE      := preload("res://scenes/Pin.tscn")
const ENEMY_SCENE    := preload("res://scenes/Enemy.tscn")
const DIALOG_SCENE   := preload("res://scenes/DialogSystem.tscn")
const YELI_SCENE     := preload("res://scenes/Yeli.tscn")
const PLAYER_SCENE   := preload("res://scenes/Player.tscn")
const HUD_SCENE      := preload("res://scenes/HUD.tscn")
const HAZARD_SCENE   := preload("res://scenes/Hazard.tscn")
const ITEM_SCENE     := preload("res://scenes/Item.tscn")
const NPC_SCENE      := preload("res://scenes/NPCAlly.tscn")

@export var data : LevelData

# ── COLORES POR TEMA ──────────────────────────
const THEME_COLORS := {
	"beach"  : {"bg": Color(0.38, 0.72, 0.92), "floor": Color(0.82, 0.72, 0.50), "plat": Color(0.70, 0.58, 0.36)},
	"city"   : {"bg": Color(0.07, 0.07, 0.12), "floor": Color(0.18, 0.18, 0.20), "plat": Color(0.26, 0.26, 0.30)},
	"tribe"  : {"bg": Color(0.22, 0.08, 0.35), "floor": Color(0.35, 0.14, 0.22), "plat": Color(0.48, 0.20, 0.30)},
	"studio" : {"bg": Color(0.06, 0.04, 0.12), "floor": Color(0.20, 0.10, 0.35), "plat": Color(0.35, 0.15, 0.55)},
	"secret" : {"bg": Color(0.02, 0.02, 0.08), "floor": Color(0.10, 0.05, 0.20), "plat": Color(0.20, 0.10, 0.40)},
}

var _player    : Node2D
var _hud       : Node
var _timer_node: Node
var _level_finished := false
var _no_damage      := true
var _health_before  : int
var _checkpoint_pos : Vector2
var _yeli       : Node2D

func _ready() -> void:
	add_to_group("level")
	if data == null:
		push_error("ProceduralLevel: falta LevelData resource")
		return

	# Verificar outfit requerido
	if data.requires_outfit != "" and GameManager.current_outfit != data.requires_outfit:
		_show_outfit_required()
		return

	GameManager.current_level = get_tree().current_scene.scene_file_path

	_apply_theme()
	_spawn_player()
	_spawn_hud()
	_spawn_enemies()
	_spawn_pins()
	_spawn_zones()
	_spawn_platforms()
	_spawn_crouch_barriers()
	_spawn_hazards()
	_spawn_items()
	_spawn_npcs()
	_spawn_level_end()
	_spawn_dialog()
	_spawn_yeli()
	_spawn_timer()

	_health_before  = GameManager.nora["health"]
	_checkpoint_pos = _player.global_position

	# Restaurar checkpoint
	if GameManager.checkpoint_pos != Vector2.ZERO:
		_player.global_position = GameManager.checkpoint_pos
		_checkpoint_pos         = GameManager.checkpoint_pos

	# Conectar daño para no-damage tracking
	GameManager.health_changed.connect(func(hp):
		if hp < _health_before:
			_no_damage = false
	)

	# Pausa (ESC funciona vía PauseMenu._input)
	var pause_menu = load("res://scenes/PauseMenu.tscn").instantiate()
	add_child(pause_menu)

	# NG+
	await get_tree().process_frame
	NGPlusManager.apply_to_scene(self)

func _process(_delta: float) -> void:
	if _player == null or _level_finished:
		return
	# Muerte por caída
	if _player.global_position.y > 420:
		_player.die()
	# Checkpoints
	if not data.checkpoint_xs.is_empty():
		for x in data.checkpoint_xs:
			if _player.global_position.x > x and _checkpoint_pos.x < x:
				_checkpoint_pos = Vector2(x, _player.global_position.y)
				GameManager.set_checkpoint(GameManager.current_level, _checkpoint_pos)
				if _yeli: _yeli.show_secret_nearby()
	# Detectar fin de nivel (respaldo por posición si el Area2D falla)
	if not _level_finished and _player.global_position.x > data.level_end_x - 30:
		_finish()

# ── CONSTRUCCIÓN ─────────────────────────────
func _apply_theme() -> void:
	var theme := data.bg_theme if data.bg_theme != "" else "beach"
	var c     = THEME_COLORS.get(theme, THEME_COLORS["beach"])
	var bg    := ColorRect.new()
	bg.offset_left   = -500.0
	bg.offset_top    = -600.0
	bg.offset_right  = data.level_length + 500.0
	bg.offset_bottom = 1000.0
	bg.color   = c["bg"]
	bg.z_index = -10
	add_child(bg)
	# Actualizar colores del suelo si existe
	var floor_vis := get_node_or_null("Floor/FloorVisual")
	if floor_vis: floor_vis.color = c["floor"]
	# Plataformas (manuales con nodo "Vis" y procedurales con ColorRect)
	var plat_root := get_node_or_null("Platforms")
	if plat_root:
		for plat in plat_root.get_children():
			var vis := plat.get_node_or_null("Vis")
			if vis and vis is ColorRect:
				vis.color = c["plat"]
			else:
				# Plataformas procedurales: buscar ColorRect hijo directo
				for child in plat.get_children():
					if child is ColorRect:
						child.color = c["plat"]

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector2(80, 258)
	add_child(_player)
	_player.player_died.connect(_on_player_died)
	_player.collectible_found.connect(func(id): GameManager.collect_pin(id))

func _spawn_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.set_world_name(data.level_name)
	_hud.setup_level_progress(data.level_length)

func _spawn_enemies() -> void:
	for i in data.enemy_positions.size():
		var type := data.enemy_types[i] if i < data.enemy_types.size() else "patrol"
		var scene_path := "res://scenes/Enemy.tscn"
		if type == "flying":
			scene_path = "res://scenes/EnemyFlying.tscn"
		elif type == "jumper":
			scene_path = "res://scenes/EnemyJumper.tscn"

		var e_scene := load(scene_path)
		if e_scene == null:
			scene_path = "res://scenes/Enemy.tscn"
			e_scene = load(scene_path)

		if e_scene == null:
			push_error("ProceduralLevel: no se pudo cargar escena de enemigo: %s" % scene_path)
			continue

		var e = e_scene.instantiate()
		e.position = data.enemy_positions[i]
		if i < data.enemy_speeds.size():
			if "speed" in e:
				e.speed = data.enemy_speeds[i]
		add_child(e)

func _spawn_pins() -> void:
	for i in data.pin_positions.size():
		var pin := PIN_SCENE.instantiate()
		pin.position  = data.pin_positions[i]
		pin.pin_id    = data.pin_ids[i] if i < data.pin_ids.size() else "pin_%s_%02d" % [data.level_key, i + 1]
		pin.pin_color = data.pin_colors[i] if i < data.pin_colors.size() else Color.GOLD
		add_child(pin)

func _spawn_zones() -> void:
	for rect in data.water_rects:
		var z := _make_zone(rect, Color(0.1, 0.4, 0.75, 0.35), "water_zone")
		add_child(z)
	for rect in data.light_rects:
		var z := _make_zone(rect, Color(1.0, 0.95, 0.5, 0.18), "light_zone")
		add_child(z)

func _make_zone(rect: Rect2, color: Color, group: String) -> Area2D:
	var z   := Area2D.new()
	z.add_to_group(group)
	z.position = rect.position
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape  = shape
	z.add_child(col)
	var vis := ColorRect.new()
	vis.size     = rect.size
	vis.position = -rect.size * 0.5
	vis.color    = color
	vis.z_index  = -5
	z.add_child(vis)
	return z

func _spawn_platforms() -> void:
	var theme := data.bg_theme if data.bg_theme != "" else "beach"
	var c     = THEME_COLORS.get(theme, THEME_COLORS["beach"])
	var plat_root := get_node_or_null("Platforms")

	# Suelo sólido visible que recorre todo el nivel
	var ground_w := data.level_length + 400.0
	var ground   := StaticBody2D.new()
	ground.position = Vector2(data.level_length * 0.5, 279.0)
	var gc   := CollisionShape2D.new()
	var gs   := RectangleShape2D.new()
	gs.size  = Vector2(ground_w, 24.0)
	gc.shape = gs
	ground.add_child(gc)
	var gv      := ColorRect.new()
	gv.size     = gs.size
	gv.position = -gs.size * 0.5
	gv.color    = c["floor"]
	ground.add_child(gv)
	add_child(ground)

	for rect in data.platform_rects:
		var body := StaticBody2D.new()
		body.position = rect.position + rect.size * 0.5

		var col   := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		col.shape  = shape
		body.add_child(col)

		var vis := ColorRect.new()
		vis.size     = rect.size
		vis.position = -rect.size * 0.5
		vis.color    = c["plat"]
		body.add_child(vis)

		if plat_root:
			plat_root.add_child(body)
		else:
			add_child(body)

func _spawn_crouch_barriers() -> void:
	for rect in data.crouch_barrier_rects:
		var barrier := StaticBody2D.new()
		barrier.position = rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.5)
		var col   := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		col.shape  = shape
		barrier.add_child(col)
		var vis := ColorRect.new()
		vis.size     = rect.size
		vis.position = -rect.size * 0.5
		vis.color    = Color(0.32, 0.22, 0.14)
		vis.z_index  = 1
		barrier.add_child(vis)
		# Diagonal stripes overlay
		for i in int(rect.size.x / 16):
			var stripe := ColorRect.new()
			stripe.size     = Vector2(4, rect.size.y)
			stripe.position = Vector2(-rect.size.x * 0.5 + i * 16 + 6, -rect.size.y * 0.5)
			stripe.color    = Color(0.22, 0.14, 0.08, 0.6)
			vis.add_child(stripe)
		add_child(barrier)

func _spawn_hazards() -> void:
	for rect in data.hazard_rects:
		var h := HAZARD_SCENE.instantiate()
		h.hazard_size = rect.size
		h.position = rect.position + rect.size * 0.5
		add_child(h)

func _spawn_items() -> void:
	for i in data.item_positions.size():
		var item := ITEM_SCENE.instantiate()
		item.position = data.item_positions[i]
		if i < data.item_types.size() and data.item_types[i] != "":
			item.item_type = data.item_types[i]
		add_child(item)
		item.item_collected.connect(func(type):
			if _hud and _hud.has_method("show_item_pickup"):
				_hud.show_item_pickup(type)
		)

func _spawn_npcs() -> void:
	for i in data.npc_positions.size():
		var npc := NPC_SCENE.instantiate()
		npc.position = data.npc_positions[i]
		if i < data.npc_names.size() and data.npc_names[i] != "":
			npc.npc_name = data.npc_names[i]
		if i < data.npc_dialogs.size() and data.npc_dialogs[i] != "":
			npc.dialog_text = data.npc_dialogs[i]
		if i < data.npc_colors.size():
			npc.npc_color = data.npc_colors[i]
		add_child(npc)

func _spawn_level_end() -> void:
	var end  := Area2D.new()
	end.name = "LevelEnd"
	end.position = Vector2(data.level_end_x, 220)
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60, 80)
	col.shape  = shape
	end.add_child(col)
	end.body_entered.connect(func(body):
		if body.is_in_group("player"):
			_finish()
	)
	add_child(end)

func _spawn_dialog() -> void:
	add_child(DIALOG_SCENE.instantiate())

func _spawn_yeli() -> void:
	_yeli = YELI_SCENE.instantiate()
	add_child(_yeli)

func _spawn_timer() -> void:
	if data.level_key == "":
		return
	_timer_node = LevelTimer.new()
	_timer_node.name = "LevelTimer"
	add_child(_timer_node)
	_timer_node.start(data.level_key, data.time_par)
	_timer_node.medal_earned.connect(func(tier):
		if _hud and _hud.has_method("show_medal"):
			_hud.show_medal(tier)
	)


# ── FIN DE NIVEL ─────────────────────────────
func _finish() -> void:
	if _level_finished: return
	_level_finished = true
	GameManager.clear_checkpoint()
	if _timer_node:
		_timer_node.stop()
	if _no_damage:
		GameManager.set_no_damage(data.level_key)
	GameManager.complete_level(data.level_key)
	# Si el nivel es el último antes del jefe, complete_world se llama desde el boss
	SceneTransition.go_to(data.next_scene)

func _on_player_died() -> void:
	pass  # Player.die() navega a GameOver

func _show_outfit_required() -> void:
	var d := DIALOG_SCENE.instantiate()
	add_child(d)
	await get_tree().process_frame
	d.show_message("Necesitas el outfit '%s' para este nivel." % data.requires_outfit,
		Color(1.0, 0.5, 0.2), 3.5)
	get_tree().create_timer(3.6).timeout.connect(func():
		SceneTransition.go_to("res://scenes/WorldMap.tscn")
	)
