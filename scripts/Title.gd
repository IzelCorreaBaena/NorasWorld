extends Node2D

var _bg     : ColorRect
var _tween  : Tween
var _credits_label : Label

const BG_COLORS := [
	Color(0.98, 0.87, 0.55),
	Color(0.99, 0.72, 0.45),
	Color(0.97, 0.60, 0.65),
	Color(0.98, 0.78, 0.50),
]
var _bg_color_idx := 0

func _ready() -> void:
	_build_background()
	_build_title()
	_build_buttons()
	_build_footer()
	_start_bg_animation()

# ── FONDO ────────────────────────────────────
func _build_background() -> void:
	_bg = ColorRect.new()
	_bg.name = "BG"
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = BG_COLORS[0]
	add_child(_bg)

	# Círculos decorativos (dibujados via _draw)
	var deco := _DecoLayer.new()
	deco.name = "Deco"
	deco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(deco)

func _start_bg_animation() -> void:
	_tween = create_tween().set_loops()
	for c in BG_COLORS:
		_tween.tween_property(_bg, "color", c, 2.5).set_ease(Tween.EASE_IN_OUT)

# ── TÍTULO ───────────────────────────────────
func _build_title() -> void:
	var vp := get_viewport_rect().size

	var title := Label.new()
	title.name = "Title"
	title.text = "NORA'S WORLD"
	title.position = Vector2(0, 48)
	title.size     = Vector2(vp.x, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color",        Color(0.25, 0.10, 0.03))
	title.add_theme_color_override("font_shadow_color", Color(1.0, 0.75, 0.20, 0.60))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	add_child(title)

	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = "Una aventura llena de color"
	sub.position = Vector2(0, 112)
	sub.size     = Vector2(vp.x, 28)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.40, 0.20, 0.06, 0.90))
	add_child(sub)

# ── BOTONES ──────────────────────────────────
func _build_buttons() -> void:
	var vp := get_viewport_rect().size

	var vbox := VBoxContainer.new()
	vbox.name = "Buttons"
	vbox.add_theme_constant_override("separation", 10)
	# Centrado en pantalla, parte inferior
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left   = -80.0
	vbox.offset_right  =  80.0
	vbox.offset_top    = -20.0
	vbox.offset_bottom =  70.0
	add_child(vbox)

	# Botón Jugar
	var btn_play := _make_button("  Jugar  ", Color(0.95, 0.55, 0.10))
	btn_play.name = "BtnPlay"
	btn_play.pressed.connect(_on_play)
	vbox.add_child(btn_play)

	# Botón Continuar (solo si hay save)
	var has_save := GameManager.levels_completed.size() > 0 or GameManager.worlds_completed.size() > 0
	if has_save:
		var btn_cont := _make_button("  Continuar  ", Color(0.25, 0.62, 0.90))
		btn_cont.name = "BtnContinue"
		btn_cont.pressed.connect(_on_continue)
		vbox.add_child(btn_cont)

	# Botón Créditos
	var btn_cred := _make_button("  Créditos  ", Color(0.60, 0.45, 0.80))
	btn_cred.name = "BtnCredits"
	btn_cred.pressed.connect(_on_credits)
	vbox.add_child(btn_cred)

	# Label de créditos (oculto inicialmente)
	_credits_label = Label.new()
	_credits_label.name = "CreditsText"
	_credits_label.text = (
		"Diseño y programación: Nora's Team\n" +
		"Arte: Procedural & Love\n" +
		"Música: Silencio alegre\n" +
		"Versión: v0.1 — 2026"
	)
	_credits_label.position = Vector2(0, vp.y * 0.62)
	_credits_label.size     = Vector2(vp.x, 80)
	_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits_label.add_theme_font_size_override("font_size", 11)
	_credits_label.add_theme_color_override("font_color", Color(0.30, 0.15, 0.05, 0.90))
	_credits_label.visible = false
	add_child(_credits_label)

func _make_button(text: String, base_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 15)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = base_color
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left   = 16.0
	style.content_margin_right  = 16.0
	style.content_margin_top    = 8.0
	style.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", style)
	var style_hover := style.duplicate()
	style_hover.bg_color = base_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	return btn

# ── FOOTER ───────────────────────────────────
func _build_footer() -> void:
	var vp := get_viewport_rect().size
	var ver := Label.new()
	ver.name = "Version"
	ver.text = "v0.1"
	ver.position = Vector2(vp.x - 48, vp.y - 22)
	ver.size     = Vector2(40, 20)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.add_theme_font_size_override("font_size", 10)
	ver.add_theme_color_override("font_color", Color(0.35, 0.20, 0.08, 0.65))
	add_child(ver)

# ── CALLBACKS ────────────────────────────────
func _on_play() -> void:
	SceneTransition.go_to("res://scenes/WorldMap.tscn")

func _on_continue() -> void:
	var level := GameManager.current_level
	if level == "" or level == "res://scenes/levels/W1_L1.tscn":
		SceneTransition.go_to("res://scenes/WorldMap.tscn")
	else:
		SceneTransition.go_to(level)

func _on_credits() -> void:
	if _credits_label:
		_credits_label.visible = not _credits_label.visible

# ── CLASE INTERNA: CAPA DECORATIVA ───────────
class _DecoLayer extends Control:
	func _draw() -> void:
		draw_circle(Vector2(60,  55),  50, Color(1.0, 0.65, 0.20, 0.18))
		draw_circle(Vector2(430, 240), 80, Color(0.95, 0.30, 0.50, 0.14))
		draw_circle(Vector2(240, 30),  30, Color(0.95, 0.80, 0.30, 0.16))
		draw_circle(Vector2(10,  190), 40, Color(1.0, 0.55, 0.25, 0.12))
		draw_circle(Vector2(470, 80),  25, Color(0.85, 0.40, 0.70, 0.15))
