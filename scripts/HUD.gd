extends CanvasLayer

@onready var heart_row   = $TopBar/HeartRow
@onready var pin_label   = $TopBar/PinCount
@onready var world_label = $TopBar/WorldLabel

var _timer_label  : Label
var _medal_label  : Label
var _boss_bar_bg  : ColorRect
var _boss_bar_fill: ColorRect
var _boss_label   : Label
var _boss_max     : int = 0

var _damage_flash : ColorRect
var _last_hp      : int = 3

var _progress_bar      : ColorRect
var _progress_fill     : ColorRect
var _level_length      : float = 0.0

var _item_notif_label : Label

func _ready() -> void:
	GameManager.health_changed.connect(_update_hearts)
	GameManager.pin_collected.connect(_update_pins)
	_update_hearts(GameManager.nora["health"])
	_update_pins("")
	_build_timer()
	_build_item_notif()
	_build_boss_bar()
	_build_medal_label()
	_build_damage_flash()
	GameManager.health_changed.connect(func(hp):
		if hp < _last_hp:
			_show_damage_flash()
		_last_hp = hp
	)
	_last_hp = GameManager.nora["health"]
	# Conectar jefes al health bar automáticamente
	await get_tree().process_frame
	for boss in get_tree().get_nodes_in_group("boss"):
		_connect_boss(boss)
	get_tree().node_added.connect(func(n):
		if n.is_in_group("boss"): _connect_boss(n)
	)

func _update_hearts(hp: int) -> void:
	for child in heart_row.get_children():
		child.queue_free()
	for i in GameManager.nora["max_health"]:
		var lbl := Label.new()
		lbl.text = "♥" if i < hp else "♡"
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color",
			Color(0.95, 0.2, 0.3) if i < hp else Color(0.5, 0.5, 0.5, 0.6))
		heart_row.add_child(lbl)

func _update_pins(_id: String) -> void:
	pin_label.text = "📍 %d" % GameManager.pins_collected.size()

func set_world_name(name: String) -> void:
	world_label.text = name

# ── TEMPORIZADOR ─────────────────────────────
func _build_timer() -> void:
	_timer_label = Label.new()
	_timer_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_timer_label.offset_right  = -8.0
	_timer_label.offset_top    = 6.0
	_timer_label.offset_left   = -100.0
	_timer_label.offset_bottom = 28.0
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_label.add_theme_font_size_override("font_size", 12)
	_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.7, 0.9))
	_timer_label.visible = false
	add_child(_timer_label)

func set_timer(t: float) -> void:
	if _timer_label == null: return
	_timer_label.visible = true
	var mins := int(t) / 60
	var secs := int(t) % 60
	var ms   := int((t - int(t)) * 100)
	_timer_label.text = "%d:%02d.%02d" % [mins, secs, ms]

# ── MEDALLAS ─────────────────────────────────
func _build_medal_label() -> void:
	_medal_label = Label.new()
	_medal_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_medal_label.offset_top    = 50.0
	_medal_label.offset_bottom = 80.0
	_medal_label.offset_left   = -80.0
	_medal_label.offset_right  = 80.0
	_medal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_medal_label.add_theme_font_size_override("font_size", 20)
	_medal_label.modulate.a = 0.0
	add_child(_medal_label)

func show_medal(tier: String) -> void:
	if _medal_label == null: return
	match tier:
		"gold":
			_medal_label.text = "🥇 ORO"
			_medal_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		"silver":
			_medal_label.text = "🥈 PLATA"
			_medal_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
		"bronze":
			_medal_label.text = "🥉 BRONCE"
			_medal_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
		_:
			return
	var tw := create_tween()
	tw.tween_property(_medal_label, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.0)
	tw.tween_property(_medal_label, "modulate:a", 0.0, 0.5)

# ── BARRA DE JEFE ─────────────────────────────
func _build_boss_bar() -> void:
	_boss_bar_bg = ColorRect.new()
	_boss_bar_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_boss_bar_bg.offset_top    = -26.0
	_boss_bar_bg.offset_bottom = -8.0
	_boss_bar_bg.offset_left   = 60.0
	_boss_bar_bg.offset_right  = -60.0
	_boss_bar_bg.color   = Color(0.15, 0.05, 0.05, 0.85)
	_boss_bar_bg.visible = false
	add_child(_boss_bar_bg)

	_boss_bar_fill = ColorRect.new()
	_boss_bar_fill.color = Color(0.85, 0.15, 0.15)
	_boss_bar_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boss_bar_fill.offset_left  = 2.0
	_boss_bar_fill.offset_right = -2.0
	_boss_bar_fill.offset_top   = 2.0
	_boss_bar_fill.offset_bottom = -2.0
	_boss_bar_bg.add_child(_boss_bar_fill)

	_boss_label = Label.new()
	_boss_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_boss_label.add_theme_font_size_override("font_size", 10)
	_boss_label.add_theme_color_override("font_color", Color.WHITE)
	_boss_bar_bg.add_child(_boss_label)

func _connect_boss(boss: Node) -> void:
	if not boss.has_signal("boss_defeated"): return
	if "max_health" in boss:
		_boss_max    = boss.max_health
		_boss_label.text = "Mundo " + str(boss.get("world_id")) if "world_id" in boss else "JEFE"
		_boss_bar_bg.visible = true
		_update_boss_bar(boss.max_health)
	if boss.has_signal("phase_changed"):
		boss.phase_changed.connect(func(_p): _update_boss_bar_from_boss(boss))
	boss.boss_defeated.connect(func(_id):
		var tw := create_tween()
		tw.tween_property(_boss_bar_bg, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func(): _boss_bar_bg.visible = false)
	)
	# Monitorear health via proceso
	set_process(true)
	set_meta("_boss_ref", boss)

func _update_boss_bar_from_boss(boss: Node) -> void:
	if "health" in boss and _boss_max > 0:
		_update_boss_bar(boss.health)

func _update_boss_bar(current_health: int) -> void:
	if _boss_max <= 0: return
	var pct := float(current_health) / float(_boss_max)
	_boss_bar_fill.anchor_right = pct
	# Color por fase
	if   pct > 0.66: _boss_bar_fill.color = Color(0.85, 0.15, 0.15)
	elif pct > 0.33: _boss_bar_fill.color = Color(0.85, 0.55, 0.10)
	else:            _boss_bar_fill.color = Color(0.90, 0.20, 0.60)

# ── FLASH DE DAÑO ────────────────────────────
func _build_damage_flash() -> void:
	_damage_flash = ColorRect.new()
	_damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_flash.color   = Color(1.0, 0.0, 0.0, 0.0)
	_damage_flash.z_index = 100
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_damage_flash)

func _show_damage_flash() -> void:
	if _damage_flash == null: return
	var tw := create_tween()
	tw.tween_property(_damage_flash, "color:a", 0.35, 0.05)
	tw.tween_property(_damage_flash, "color:a", 0.0, 0.3)

# ── BARRA DE PROGRESO ────────────────────────
func setup_level_progress(length: float) -> void:
	_level_length = length
	if _progress_bar != null: return
	_progress_bar = ColorRect.new()
	_progress_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_progress_bar.offset_top    = 24.0
	_progress_bar.offset_bottom = 27.0
	_progress_bar.offset_left   = 8.0
	_progress_bar.offset_right  = -8.0
	_progress_bar.color = Color(0.2, 0.2, 0.2, 0.6)
	add_child(_progress_bar)
	_progress_fill = ColorRect.new()
	_progress_fill.size     = Vector2(0, 3)
	_progress_fill.color    = Color(1.0, 1.0, 1.0, 0.85)
	_progress_bar.add_child(_progress_fill)

func _update_progress(player_x: float) -> void:
	if _progress_fill == null or _level_length <= 0: return
	var pct := clamp(player_x / _level_length, 0.0, 1.0)
	var bar_w := _progress_bar.size.x
	_progress_fill.size.x = bar_w * pct
	if   pct > 0.8: _progress_fill.color = Color(0.2, 0.9, 0.3, 0.9)
	elif pct > 0.5: _progress_fill.color = Color(1.0, 0.85, 0.0, 0.9)
	else:           _progress_fill.color = Color(1.0, 1.0, 1.0, 0.85)

# ── NOTIFICACIÓN DE ITEM ─────────────────────
func _build_item_notif() -> void:
	_item_notif_label = Label.new()
	_item_notif_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_item_notif_label.offset_right  = -8.0
	_item_notif_label.offset_top    = 34.0
	_item_notif_label.offset_left   = -150.0
	_item_notif_label.offset_bottom = 52.0
	_item_notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_item_notif_label.add_theme_font_size_override("font_size", 10)
	_item_notif_label.modulate.a = 0.0
	add_child(_item_notif_label)

func show_item_pickup(item_type: String) -> void:
	if _item_notif_label == null: _build_item_notif()
	match item_type:
		"health":
			_item_notif_label.text = "+ Salud"
			_item_notif_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.4))
		"speed_boost":
			_item_notif_label.text = "¡Velocidad!"
			_item_notif_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		"shield":
			_item_notif_label.text = "+ Escudo"
			_item_notif_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	var tw := create_tween()
	tw.tween_property(_item_notif_label, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.0)
	tw.tween_property(_item_notif_label, "modulate:a", 0.0, 0.3)

func _process(_delta: float) -> void:
	var boss = get_meta("_boss_ref") if has_meta("_boss_ref") else null
	if boss and is_instance_valid(boss) and "health" in boss:
		_update_boss_bar(boss.health)
	# Actualizar timer
	if _timer_label and _timer_label.visible:
		for node in get_tree().get_nodes_in_group("level"):
			var t := node.get_node_or_null("LevelTimer")
			if t and "elapsed" in t:
				set_timer(t.elapsed)
				break
	# Actualizar barra de progreso
	if _progress_fill != null:
		for node in get_tree().get_nodes_in_group("player"):
			_update_progress(node.global_position.x)
			break
