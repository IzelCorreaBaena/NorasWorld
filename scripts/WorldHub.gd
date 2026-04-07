extends Node2D

@export var world_id   : int    = 1
@export var world_name : String = "Ola Grande"
@export var theme_color: Color  = Color(0.0, 0.60, 0.85)

const LEVEL_SCENES := {
	1: ["res://scenes/levels/W1_L1.tscn", "res://scenes/levels/W1_L2.tscn",
		"res://scenes/levels/W1_L3.tscn", "res://scenes/levels/W1_L4.tscn",
		"res://scenes/levels/W1_Boss.tscn"],
	2: ["res://scenes/levels/W2_L1.tscn", "res://scenes/levels/W2_L2.tscn",
		"res://scenes/levels/W2_L3.tscn", "res://scenes/levels/W2_L4.tscn",
		"res://scenes/levels/W2_Boss.tscn"],
	3: ["res://scenes/levels/W3_L1.tscn", "res://scenes/levels/W3_L2.tscn",
		"res://scenes/levels/W3_L3.tscn", "res://scenes/levels/W3_L4.tscn",
		"res://scenes/levels/W3_Boss.tscn"],
	4: ["res://scenes/levels/W4_L1.tscn", "res://scenes/levels/W4_L2.tscn",
		"res://scenes/levels/W4_L3.tscn", "res://scenes/levels/W4_L4.tscn",
		"res://scenes/levels/W4_Boss.tscn"],
	5: ["res://scenes/levels/W5_L1.tscn", "res://scenes/levels/W5_L2.tscn",
		"res://scenes/levels/W5_L3.tscn", "res://scenes/levels/W5_L4.tscn",
		"res://scenes/levels/W5_Boss.tscn"],
}

const LEVEL_NAMES := {
	1: ["La Orilla", "Marea Baja", "El Arrecife", "La Tormenta", "La Ola Perfecta"],
	2: ["El Backstage", "Tejados", "La Pasarela", "Noche de Moda", "El Maniqui"],
	3: ["La Fogata", "Bosque Tribal", "Las Ruinas", "El Ritual", "La Sombra"],
	4: ["El Taller", "Sueno de Diseno", "El Espejo", "La Coleccion Final", "El Espejo Roto"],
	5: ["El Umbral", "Vacio", "Recuerdos", "El Nucleo", "La Nora Perdida"],
}

const LEVEL_KEYS := {
	1: ["W1_L1", "W1_L2", "W1_L3", "W1_L4", "W1_Boss"],
	2: ["W2_L1", "W2_L2", "W2_L3", "W2_L4", "W2_Boss"],
	3: ["W3_L1", "W3_L2", "W3_L3", "W3_L4", "W3_Boss"],
	4: ["W4_L1", "W4_L2", "W4_L3", "W4_L4", "W4_Boss"],
	5: ["W5_L1", "W5_L2", "W5_L3", "W5_L4", "W5_Boss"],
}

# Conteo de pines por nivel (5 pines por nivel normal, 5 en boss)
const PINS_PER_LEVEL := 5

func _ready() -> void:
	_build_background()
	_build_header()
	_build_level_list()

# ── FONDO ─────────────────────────────────────
func _build_background() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = theme_color.darkened(0.55)
	add_child(bg)

	# Gradiente decorativo superior
	var accent := ColorRect.new()
	accent.name = "Accent"
	var vp := get_viewport_rect().size
	accent.position = Vector2(0, 0)
	accent.size     = Vector2(vp.x, 60)
	accent.color    = theme_color.darkened(0.30)
	add_child(accent)

	# Círculo decorativo de fondo
	var deco := _DecoCircle.new()
	deco.name        = "DecoCircle"
	deco.world_color = theme_color
	deco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(deco)

# ── CABECERA ──────────────────────────────────
func _build_header() -> void:
	var vp := get_viewport_rect().size

	# Título del mundo
	var title := Label.new()
	title.name = "WorldTitle"
	title.text = "MUNDO %d: %s" % [world_id, world_name.to_upper()]
	title.position = Vector2(0, 12)
	title.size     = Vector2(vp.x - 80, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.50))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	# Botón volver
	var btn_back := Button.new()
	btn_back.name = "BtnBack"
	btn_back.text = "< Mapa"
	btn_back.position = Vector2(6, 8)
	btn_back.size     = Vector2(62, 24)
	btn_back.add_theme_font_size_override("font_size", 11)
	btn_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style_back := StyleBoxFlat.new()
	style_back.bg_color = Color(0, 0, 0, 0.40)
	style_back.corner_radius_top_left     = 6
	style_back.corner_radius_top_right    = 6
	style_back.corner_radius_bottom_left  = 6
	style_back.corner_radius_bottom_right = 6
	style_back.content_margin_left   = 8.0
	style_back.content_margin_right  = 8.0
	style_back.content_margin_top    = 4.0
	style_back.content_margin_bottom = 4.0
	btn_back.add_theme_stylebox_override("normal", style_back)
	btn_back.add_theme_color_override("font_color", Color.WHITE)
	btn_back.pressed.connect(func():
		SceneTransition.go_to("res://scenes/WorldMap.tscn")
	)
	add_child(btn_back)

# ── LISTA DE NIVELES ──────────────────────────
func _build_level_list() -> void:
	var vp      := get_viewport_rect().size
	var scenes  = LEVEL_SCENES.get(world_id, [])
	var names   = LEVEL_NAMES.get(world_id, [])
	var keys    = LEVEL_KEYS.get(world_id, [])

	if scenes.is_empty():
		push_error("WorldHub: world_id=%d no tiene escenas definidas" % world_id)
		return

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.position = Vector2(20, 50)
	scroll.size     = Vector2(vp.x - 40, vp.y - 60)
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.name = "LevelList"
	vbox.custom_minimum_size = Vector2(vp.x - 40, 0)
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	for i in scenes.size():
		var key: String = keys[i]   if i < keys.size()   else ""
		var level_name  : String = names[i]  if i < names.size()  else "Nivel %d" % (i + 1)
		var scene_path  : String = scenes[i]
		var is_boss     : bool = (i == 4)

		var unlocked  : bool = _is_level_unlocked(i)
		var completed := GameManager.has_level_completed(key)
		var no_dmg    := GameManager.has_no_damage(key)
		var best_t    := GameManager.get_best_time(key)
		var pins      := _count_level_pins(world_id, i + 1, is_boss)

		var btn := _make_level_button(
			i, level_name, key, is_boss,
			unlocked, completed, no_dmg, best_t, pins,
			scene_path
		)
		vbox.add_child(btn)

func _make_level_button(
		idx: int, level_name: String, key: String, is_boss: bool,
		unlocked: bool, completed: bool, no_dmg: bool,
		best_t: float, pins: int,
		scene_path: String
) -> Button:
	var btn := Button.new()
	btn.name          = "Level%d" % (idx + 1)
	btn.disabled      = not unlocked
	btn.flat          = false
	btn.alignment     = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 32)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW

	# Construir texto del botón
	var label_parts := PackedStringArray()

	if not unlocked:
		label_parts.append("[bloq]")
	elif is_boss:
		label_parts.append("[BOSS]")
	else:
		label_parts.append("[%d]" % (idx + 1))

	label_parts.append(level_name)

	if completed:
		label_parts.append("  *")
		if no_dmg:
			label_parts.append("(perfecto)")
		if best_t > 0.0:
			label_parts.append(" %s" % _format_time(best_t))

	label_parts.append("  [pins %d/%d]" % [pins, PINS_PER_LEVEL])

	btn.text = "  ".join(label_parts)
	btn.add_theme_font_size_override("font_size", 12)

	# Estilo visual por estado
	var style := StyleBoxFlat.new()
	if not unlocked:
		style.bg_color = Color(0.15, 0.15, 0.15, 0.55)
	elif completed:
		style.bg_color = theme_color.darkened(0.15)
		style.border_color = Color(1.0, 0.90, 0.20, 0.85)
		style.set_border_width_all(2)
	elif is_boss:
		style.bg_color = Color(0.55, 0.05, 0.05, 0.85)
		style.border_color = Color(1.0, 0.30, 0.30, 0.70)
		style.set_border_width_all(2)
	else:
		style.bg_color = theme_color.darkened(0.30)

	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left   = 10.0
	style.content_margin_right  = 10.0
	style.content_margin_top    = 6.0
	style.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("normal",   style)
	btn.add_theme_stylebox_override("disabled", style)

	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = style.bg_color.lightened(0.18)
	btn.add_theme_stylebox_override("hover", style_hover)

	var font_color := Color.WHITE if unlocked else Color(0.60, 0.60, 0.60)
	btn.add_theme_color_override("font_color",          font_color)
	btn.add_theme_color_override("font_disabled_color", Color(0.50, 0.50, 0.50))

	if unlocked:
		btn.pressed.connect(func():
			if ResourceLoader.exists(scene_path):
				SceneTransition.go_to(scene_path)
			else:
				push_warning("WorldHub: escena no encontrada: %s" % scene_path)
		)

	return btn

# ── HELPERS ───────────────────────────────────
func _is_level_unlocked(level_idx: int) -> bool:
	# level_idx 0 = L1, 1 = L2, ..., 4 = Boss
	if level_idx == 0:
		return GameManager.is_world_unlocked(world_id)
	var keys : Array = LEVEL_KEYS.get(world_id, [])
	if level_idx - 1 >= keys.size():
		return false
	var prev_key = keys[level_idx - 1]
	return GameManager.has_level_completed(prev_key)

func _count_level_pins(wid: int, level_num: int, is_boss: bool) -> int:
	# Pines con prefijo "pin_W{wid}_L{level_num}_" o "pin_W{wid}_Boss_"
	var prefix : String
	if is_boss:
		prefix = "pin_W%d_Boss_" % wid
	else:
		prefix = "pin_W%d_L%d_" % [wid, level_num]
	var count := 0
	for p in GameManager.pins_collected:
		if p.begins_with(prefix):
			count += 1
	return count

func _format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	var ms := int(fmod(seconds, 1.0) * 100)
	return "%d:%02d.%02d" % [m, s, ms]

# ── CLASE INTERNA: DECORACION DE FONDO ───────
class _DecoCircle extends Control:
	var world_color : Color = Color.WHITE

	func _draw() -> void:
		var cx := size.x * 0.85
		var cy := size.y * 0.80
		draw_circle(Vector2(cx, cy), 120, world_color.darkened(0.20) * Color(1,1,1,0.18))
		draw_circle(Vector2(size.x * 0.05, size.y * 0.15), 55,
			world_color.lightened(0.30) * Color(1,1,1,0.12))
