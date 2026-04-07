extends Node2D

# ── DATOS DE MUNDOS ──────────────────────────
const WORLD_DATA := [
	{
		"id"    : 1,
		"name"  : "Ola Grande",
		"theme" : "Surf / Playa / Océano",
		"scene" : "res://scenes/WorldHub1.tscn",
		"color" : Color(0.0, 0.60, 0.85),
		"pos"   : Vector2(80, 180),
	},
	{
		"id"    : 2,
		"name"  : "Pasarela Infinita",
		"theme" : "Moda / Pasarela / City",
		"scene" : "res://scenes/WorldHub2.tscn",
		"color" : Color(1.0, 0.20, 0.55),
		"pos"   : Vector2(200, 140),
	},
	{
		"id"    : 3,
		"name"  : "La Tribu",
		"theme" : "Amigos / Festival / Tribu",
		"scene" : "res://scenes/WorldHub3.tscn",
		"color" : Color(1.0, 0.42, 0.13),
		"pos"   : Vector2(300, 190),
	},
	{
		"id"    : 4,
		"name"  : "El Estudio",
		"theme" : "Estilismo / Taller / Sueño",
		"scene" : "res://scenes/WorldHub4.tscn",
		"color" : Color(0.55, 0.20, 0.85),
		"pos"   : Vector2(400, 145),
	},
	{
		"id"    : 5,
		"name"  : "El Otro Mundo",
		"theme" : "Secreto / Final",
		"scene" : "res://scenes/WorldHub5.tscn",
		"color" : Color(0.3, 0.05, 0.5),
		"pos"   : Vector2(440, 195),
	},
]

# Nodos de los badges (creados dinámicamente)
var _badges      : Array  = []
var _badge_tweens: Array  = []   # un tween de pulso por badge
var _outfit_label : Label
var _outfit_btn   : Button

func _ready() -> void:
	_build_background()
	_build_title()
	_build_connections()
	_build_badges()
	_build_outfit_panel()
	_refresh_badges()

	GameManager.world_completed.connect(func(_id): _refresh_badges())
	GameManager.outfit_changed.connect(func(_id): _refresh_outfit_panel())

# ── FONDO ─────────────────────────────────────
func _draw() -> void:
	var vp := get_viewport_rect()
	# Degradado cálido de arriba a abajo
	draw_rect(Rect2(0, 0, vp.size.x, vp.size.y * 0.5),
		Color(0.98, 0.87, 0.55))
	draw_rect(Rect2(0, vp.size.y * 0.5, vp.size.x, vp.size.y * 0.5),
		Color(0.95, 0.70, 0.35))
	# Círculos decorativos — ajustados para 5 mundos (viewport 480x270)
	draw_circle(Vector2(30,  50),  40, Color(1.0, 0.70, 0.20, 0.22))
	draw_circle(Vector2(460, 240), 70, Color(0.30, 0.75, 0.90, 0.18))
	draw_circle(Vector2(240, 30),  28, Color(0.90, 0.35, 0.50, 0.20))
	draw_circle(Vector2(700, 80),  45, Color(0.40, 0.10, 0.60, 0.18))

func _build_background() -> void:
	queue_redraw()

func _build_title() -> void:
	var title := Label.new()
	title.text = "NORA'S WORLD"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position = Vector2(0, 20)
	title.size     = Vector2(get_viewport_rect().size.x, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color",        Color(0.25, 0.12, 0.05))
	title.add_theme_color_override("font_shadow_color", Color(1.0, 0.8, 0.3, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	var sub := Label.new()
	sub.text = "Elige tu próxima aventura"
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.position = Vector2(0, 56)
	sub.size     = Vector2(get_viewport_rect().size.x, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.35, 0.20, 0.08, 0.85))
	add_child(sub)

# ── LÍNEAS DE CONEXIÓN ───────────────────────
func _build_connections() -> void:
	# Dibuja líneas entre badges en _draw, usando sus posiciones
	pass  # Se dibujan en _draw_connections() via _draw()

# ── BADGES ───────────────────────────────────
func _build_badges() -> void:
	for data in WORLD_DATA:
		var badge := _make_badge(data)
		add_child(badge)
		_badges.append(badge)
		_badge_tweens.append(null)

func _make_badge(data: Dictionary) -> Control:
	var container := Control.new()
	container.name      = "Badge%d" % data["id"]
	container.position  = data["pos"]
	container.size      = Vector2(80, 80)
	# Centrar en pos
	container.position -= Vector2(40, 40)

	# Círculo de fondo (se dibuja en el control via _draw)
	var circle := _ColorCircle.new()
	circle.name       = "Circle"
	circle.color      = data["color"]
	circle.size       = Vector2(80, 80)
	circle.data_ref   = data
	container.add_child(circle)

	# Número del mundo
	var num_label := Label.new()
	num_label.name = "NumLabel"
	num_label.text = str(data["id"])
	num_label.position = Vector2(0, 14)
	num_label.size     = Vector2(80, 40)
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_label.add_theme_font_size_override("font_size", 26)
	num_label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(num_label)

	# Nombre del mundo
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = data["name"]
	name_label.position = Vector2(-30, 84)
	name_label.size     = Vector2(140, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	container.add_child(name_label)

	# Contador de pines
	var pin_label := Label.new()
	pin_label.name = "PinLabel"
	pin_label.text = "📍 0/5"
	pin_label.position = Vector2(-20, 102)
	pin_label.size     = Vector2(120, 20)
	pin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pin_label.add_theme_font_size_override("font_size", 11)
	pin_label.add_theme_color_override("font_color", Color(0.5, 0.3, 0.05))
	container.add_child(pin_label)

	# Botón invisible sobre el badge (para detectar clicks)
	var btn := Button.new()
	btn.name          = "Btn"
	btn.flat          = true
	btn.size          = Vector2(80, 80)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func(): _on_badge_pressed(data))
	container.add_child(btn)

	return container

func _refresh_badges() -> void:
	for i in _badges.size():
		var data    : Dictionary = WORLD_DATA[i]
		var wid     : int        = data["id"]
		var badge   : Control    = _badges[i]
		var circle  : Node       = badge.get_node("Circle")
		var pin_lbl : Label      = badge.get_node("PinLabel")
		var btn     : Button     = badge.get_node("Btn")
		var num_lbl : Label      = badge.get_node("NumLabel")

		var unlocked  := GameManager.is_world_unlocked(wid)
		var completed := wid in GameManager.worlds_completed
		var pins      := GameManager.pins_in_world(wid)

		pin_lbl.text = "📍 %d/%d" % [pins, GameManager.total_pins_in_world(wid)]

		if completed:
			num_lbl.text = "⭐"
			circle.locked    = false
			circle.completed = true
		elif unlocked:
			num_lbl.text = str(wid)
			circle.locked    = false
			circle.completed = false
		else:
			num_lbl.text = "🔒"
			circle.locked    = true
			circle.completed = false

		circle.queue_redraw()
		btn.disabled = not unlocked

		# Animación de brillo sólo para mundos disponibles no completados
		if unlocked and not completed:
			_start_pulse(i, badge)
		else:
			_stop_pulse(i)

func _start_pulse(idx: int, badge: Control) -> void:
	if _badge_tweens[idx] != null and _badge_tweens[idx].is_valid():
		return  # ya tiene tween activo
	var circle := badge.get_node("Circle")
	var tw := create_tween().set_loops()
	tw.tween_property(circle, "modulate:a", 0.75, 0.8).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(circle, "modulate:a", 1.00, 0.8).set_ease(Tween.EASE_IN_OUT)
	_badge_tweens[idx] = tw

func _stop_pulse(idx: int) -> void:
	if _badge_tweens[idx] != null and _badge_tweens[idx].is_valid():
		_badge_tweens[idx].kill()
	_badge_tweens[idx] = null

func _on_badge_pressed(data: Dictionary) -> void:
	if not GameManager.is_world_unlocked(data["id"]):
		return
	get_tree().change_scene_to_file(data["scene"])

# ── PANEL DE OUTFIT ──────────────────────────
func _build_outfit_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left   = -220.0
	panel.offset_top    = -90.0
	panel.offset_right  = -12.0
	panel.offset_bottom = -12.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left   = 12.0
	style.content_margin_right  = 12.0
	style.content_margin_top    = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	_outfit_label = Label.new()
	_outfit_label.add_theme_font_size_override("font_size", 12)
	_outfit_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_outfit_label)

	_outfit_btn = Button.new()
	_outfit_btn.text = "Cambiar outfit"
	_outfit_btn.add_theme_font_size_override("font_size", 11)
	_outfit_btn.pressed.connect(_cycle_outfit)
	vbox.add_child(_outfit_btn)

	add_child(panel)
	_refresh_outfit_panel()

func _refresh_outfit_panel() -> void:
	if not _outfit_label:
		return
	var outfit_id := GameManager.current_outfit
	var color     := OutfitManager.get_color(outfit_id)
	_outfit_label.text = "👗 %s" % OutfitManager.get_outfit_name(outfit_id)
	_outfit_label.add_theme_color_override("font_color", color)
	_outfit_btn.visible = GameManager.outfits_unlocked.size() > 1

func _cycle_outfit() -> void:
	var unlocked := GameManager.outfits_unlocked
	if unlocked.size() <= 1:
		return
	var idx  := unlocked.find(GameManager.current_outfit)
	var next := unlocked[(idx + 1) % unlocked.size()]
	GameManager.set_outfit(next)

# ── CLASE INTERNA: CÍRCULO DIBUJADO ──────────
class _ColorCircle extends Control:
	var color     : Color      = Color.WHITE
	var locked    : bool       = false
	var completed : bool       = false
	var data_ref  : Dictionary = {}

	func _draw() -> void:
		var center := size * 0.5
		var r      := minf(size.x, size.y) * 0.5

		if locked:
			draw_circle(center, r, Color(0.5, 0.5, 0.5, 0.6))
			draw_arc(center, r, 0, TAU, 32, Color(0.7, 0.7, 0.7, 0.5), 2.5)
		elif completed:
			draw_circle(center, r, color)
			draw_arc(center, r, 0, TAU, 32, Color(1.0, 0.9, 0.2), 3.0)
		else:
			draw_circle(center, r, color)
			draw_arc(center, r, 0, TAU, 32, Color(1.0, 1.0, 1.0, 0.6), 2.0)
