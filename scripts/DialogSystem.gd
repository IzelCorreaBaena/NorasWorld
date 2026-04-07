extends CanvasLayer

# ── TEXTOS DE PINES ──────────────────────────
const PIN_TEXTS := {
	# Mundo 1 – Ola Grande (dorado)
	"pin_world1_01": "El primer paso siempre da miedo",
	"pin_world1_02": "Respira. Ya lo tienes",
	"pin_world1_03": "La vista desde arriba lo cambia todo",
	"pin_world1_04": "Confía en el momento",
	"pin_world1_05": "Domaste tu primera ola. Hay más",
	# Mundo 2 – Pasarela Infinita (rosa)
	"pin_world2_01": "El estilo es una forma de decir quién eres sin hablar",
	"pin_world2_02": "Lo que ves depende de cómo miras",
	"pin_world2_03": "El escenario es tuyo. Siempre lo fue",
	"pin_world2_04": "A veces hay que romper algo para llegar",
	"pin_world2_05": "Nadie puede imitarte de verdad. Eso es tuyo",
	# Mundo 3 – La Tribu (azul)
	"pin_world3_01": "Tus amigos son tu mejor outfit",
	"pin_world3_02": "Siente el ritmo. Ya lo llevas dentro",
	"pin_world3_03": "Los mejores momentos no se planean",
	"pin_world3_04": "Incluso en la oscuridad sabes quién eres",
	"pin_world3_05": "Tu sombra no te define. Tú la defines a ella",
	# Mundo 4 – El Estudio (morado)
	"pin_world4_01": "El primer boceto nunca es el último",
	"pin_world4_02": "Todo lo que imaginas ya existe dentro de ti",
	"pin_world4_03": "El reflejo que importa eres tú eligiéndolo",
	"pin_world4_04": "Crear algo es el acto más valiente que existe",
	"pin_world4_05": "Ya eres la estilista que querías ser. Siempre lo fuiste",
}

const PIN_COLORS := {
	"world1": Color(1.00, 0.80, 0.10),  # dorado
	"world2": Color(1.00, 0.30, 0.60),  # rosa
	"world3": Color(0.30, 0.70, 1.00),  # azul
	"world4": Color(0.65, 0.30, 0.90),  # morado
}

const DISPLAY_TIME := 3.0

# ── NODOS ─────────────────────────────────────
var _panel      : PanelContainer
var _pin_icon   : Label
var _text_label : Label
var _timer      : float = 0.0
var _showing    := false

# ── INIT ─────────────────────────────────────
func _ready() -> void:
	layer = 20
	add_to_group("dialog")
	_build_ui()
	_panel.modulate.a = 0.0

	GameManager.pin_collected.connect(_on_pin_collected)

func _build_ui() -> void:
	# Fondo semitransparente en la parte inferior
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top    = -110.0
	_panel.offset_bottom = -12.0
	_panel.offset_left   = 60.0
	_panel.offset_right  = -60.0
	add_child(_panel)

	# Estilo del panel
	var style := StyleBoxFlat.new()
	style.bg_color          = Color(0.0, 0.0, 0.0, 0.72)
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left   = 20.0
	style.content_margin_right  = 20.0
	style.content_margin_top    = 14.0
	style.content_margin_bottom = 14.0
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	# Icono del pin (emoji coloreado)
	_pin_icon = Label.new()
	_pin_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pin_icon.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_pin_icon)

	# Texto del pin
	_text_label = Label.new()
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 18)
	_text_label.add_theme_color_override("font_color",        Color(1.0, 1.0, 1.0))
	_text_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_text_label.add_theme_constant_override("shadow_offset_x", 1)
	_text_label.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(_text_label)

# ── LOOP ─────────────────────────────────────
func _process(delta: float) -> void:
	if not _showing:
		return
	_timer -= delta
	if _timer <= 0.0:
		_hide_popup()
		return
	# Cerrar con cualquier botón
	if Input.is_anything_pressed():
		_hide_popup()

# ── MOSTRAR / OCULTAR ─────────────────────────
func _on_pin_collected(pin_id: String) -> void:
	var text  = PIN_TEXTS.get(pin_id, "")
	if text.is_empty():
		return

	var world_key := _world_key(pin_id)
	var color     = PIN_COLORS.get(world_key, Color.WHITE)
	var is_boss   := pin_id.ends_with("_05")

	_pin_icon.text = "📍" if not is_boss else "⭐"
	_pin_icon.add_theme_color_override("font_color", color)
	_text_label.text = text

	_timer   = DISPLAY_TIME
	_showing = true
	_animate_in()

func _animate_in() -> void:
	_panel.position.y = 30.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_panel, "position:y", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _hide_popup() -> void:
	_showing = false
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_panel, "position:y", 20.0, 0.25)

# ── HELPERS ──────────────────────────────────
func _world_key(pin_id: String) -> String:
	if   "world1" in pin_id: return "world1"
	elif "world2" in pin_id: return "world2"
	elif "world3" in pin_id: return "world3"
	elif "world4" in pin_id: return "world4"
	return ""

# ── API PÚBLICA ──────────────────────────────
func show_message(text: String, color: Color = Color.WHITE, duration: float = DISPLAY_TIME) -> void:
	_pin_icon.text  = "💬"
	_pin_icon.add_theme_color_override("font_color", color)
	_text_label.text = text
	_timer   = duration
	_showing = true
	_animate_in()
