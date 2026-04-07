extends CanvasLayer

# ── TEXTOS DE PINES ──────────────────────────
const PIN_TEXTS := {
	# Mundo 1 – La Orilla (dorado)
	"pin_W1_L1_01": "El primer paso siempre da miedo",
	"pin_W1_L1_02": "Respira. Ya lo tienes",
	"pin_W1_L1_03": "La vista desde arriba lo cambia todo",
	"pin_W1_L1_04": "Confía en el momento",
	"pin_W1_L1_05": "Domaste tu primera ola. Hay más",
	"pin_W1_L2_01": "El camino siempre aparece cuando caminas",
	"pin_W1_L2_02": "No mires atrás, el horizonte está adelante",
	"pin_W1_L2_03": "Cada salto es un acto de fe",
	"pin_W1_L2_04": "La orilla siempre llega",
	"pin_W1_L2_05": "Ya sabes nadar. Ahora vuela",
	"pin_W1_L3_01": "El ritmo del mar te enseña todo",
	"pin_W1_L3_02": "La calma después de la tormenta es tuya",
	"pin_W1_L3_03": "Cada ola que pasas te hace más fuerte",
	"pin_W1_L3_04": "El océano también te escucha",
	"pin_W1_L3_05": "La playa recuerda cada paso que das",
	"pin_W1_L4_01": "La aventura empieza donde termina el mapa",
	"pin_W1_L4_02": "El miedo es solo el principio",
	"pin_W1_L4_03": "Eres más valiente de lo que crees",
	"pin_W1_L4_04": "El horizonte te llama por tu nombre",
	"pin_W1_L4_05": "Nora, ya eres imparable",
	# Mundo 2 – Pasarela Infinita (rosa)
	"pin_W2_L1_01": "El estilo es una forma de decir quién eres sin hablar",
	"pin_W2_L1_02": "Lo que ves depende de cómo miras",
	"pin_W2_L1_03": "El escenario es tuyo. Siempre lo fue",
	"pin_W2_L1_04": "A veces hay que romper algo para llegar",
	"pin_W2_L1_05": "Nadie puede imitarte de verdad. Eso es tuyo",
	"pin_W2_L2_01": "La pasarela empieza en tu cabeza",
	"pin_W2_L2_02": "Camina como si el mundo te mirara. Lo hace",
	"pin_W2_L2_03": "Cada look es una declaración",
	"pin_W2_L2_04": "La moda pasa. El estilo queda",
	"pin_W2_L2_05": "Eres la tendencia que no existía",
	"pin_W2_L3_01": "La ciudad es tu runway",
	"pin_W2_L3_02": "Cada esquina tiene su propia magia",
	"pin_W2_L3_03": "El ritmo urbano late en ti",
	"pin_W2_L3_04": "La noche tiene sus propias luces",
	"pin_W2_L3_05": "Tú defines el código de vestimenta",
	"pin_W2_L4_01": "El desfile más importante es el de tu vida",
	"pin_W2_L4_02": "Crea. Destruye. Vuelve a crear",
	"pin_W2_L4_03": "El arte y la moda son el mismo idioma",
	"pin_W2_L4_04": "Tu intuición siempre tiene razón",
	"pin_W2_L4_05": "La colección más importante eres tú",
	# Mundo 3 – La Tribu (azul)
	"pin_W3_L1_01": "Tus amigos son tu mejor outfit",
	"pin_W3_L1_02": "Siente el ritmo. Ya lo llevas dentro",
	"pin_W3_L1_03": "Los mejores momentos no se planean",
	"pin_W3_L1_04": "Incluso en la oscuridad sabes quién eres",
	"pin_W3_L1_05": "Tu sombra no te define. Tú la defines a ella",
	"pin_W3_L2_01": "La tribu te espera siempre",
	"pin_W3_L2_02": "Juntos somos más que la suma",
	"pin_W3_L2_03": "El fuego del grupo te calienta",
	"pin_W3_L2_04": "La lealtad es el tejido más fino",
	"pin_W3_L2_05": "Eres el eslabón que completaba la cadena",
	"pin_W3_L3_01": "La música une lo que las palabras no alcanzan",
	"pin_W3_L3_02": "Baila aunque nadie te vea. Siempre te ves tú",
	"pin_W3_L3_03": "El ritmo tribal es el más antiguo que existe",
	"pin_W3_L3_04": "Tu cuerpo sabe el camino",
	"pin_W3_L3_05": "La celebración es parte del viaje",
	"pin_W3_L4_01": "Las raíces te dan alas",
	"pin_W3_L4_02": "La tradición reinventada eres tú",
	"pin_W3_L4_03": "Lo que llevas dentro nadie te lo puede quitar",
	"pin_W3_L4_04": "El legado también se puede elegir",
	"pin_W3_L4_05": "Llevas la tribu contigo a todas partes",
	# Mundo 4 – El Estudio (morado)
	"pin_W4_L1_01": "El primer boceto nunca es el último",
	"pin_W4_L1_02": "Todo lo que imaginas ya existe dentro de ti",
	"pin_W4_L1_03": "El reflejo que importa eres tú eligiéndolo",
	"pin_W4_L1_04": "Crear algo es el acto más valiente que existe",
	"pin_W4_L1_05": "Ya eres la estilista que querías ser. Siempre lo fuiste",
	"pin_W4_L2_01": "El estudio es donde los sueños toman forma",
	"pin_W4_L2_02": "La aguja y el hilo cosen futuros",
	"pin_W4_L2_03": "Cada puntada es una decisión",
	"pin_W4_L2_04": "La perfección es el enemigo de lo hecho",
	"pin_W4_L2_05": "Tu obra maestra ya está en camino",
	"pin_W4_L3_01": "El espejo te muestra lo que eliges ver",
	"pin_W4_L3_02": "Diseña para ti primero",
	"pin_W4_L3_03": "La creatividad no se agota. Se renueva",
	"pin_W4_L3_04": "El caos es el primer paso del orden",
	"pin_W4_L3_05": "Todo gran diseño empieza con una pregunta",
	"pin_W4_L4_01": "El último nivel siempre parece imposible",
	"pin_W4_L4_02": "Y aun así aquí estás",
	"pin_W4_L4_03": "La distancia que recorriste es tu obra",
	"pin_W4_L4_04": "Ya no eres quien empezó. Eso es crecer",
	"pin_W4_L4_05": "El final es solo el comienzo de lo siguiente",
	# Mundo 5 – El Umbral Secreto (magenta)
	"pin_W5_L1_01": "Llegaste hasta aquí. Nadie más lo hizo",
	"pin_W5_L1_02": "Este lugar existe porque tú lo buscaste",
	"pin_W5_L1_03": "El secreto no era el lugar. Eras tú",
	"pin_W5_L1_04": "Cada duda que venciste te trajo aquí",
	"pin_W5_L1_05": "El umbral siempre estuvo abierto para ti",
	"pin_W5_L2_01": "El vacío no está vacío. Está lleno de posibilidad",
	"pin_W5_L2_02": "Cuando todo desaparece, ves lo que queda",
	"pin_W5_L2_03": "Lo que imaginas aquí se vuelve real allá",
	"pin_W5_L2_04": "No temas al silencio. Él también te escucha",
	"pin_W5_L2_05": "El camino que ves es el que crearás",
	"pin_W5_L3_01": "Los recuerdos no pesan. Te sostienen",
	"pin_W5_L3_02": "Cada versión de ti que olvidaste aún existe aquí",
	"pin_W5_L3_03": "Recuerda quien eras para saber quién eres",
	"pin_W5_L3_04": "Nada de lo que viviste fue en vano",
	"pin_W5_L3_05": "El pasado no te persigue. Te acompaña",
	"pin_W5_L4_01": "El núcleo de todo siempre fuiste tú",
	"pin_W5_L4_02": "Este es el lugar donde todo comienza de nuevo",
	"pin_W5_L4_03": "La versión más real de ti espera al final",
	"pin_W5_L4_04": "No llegaste hasta aquí para rendirte ahora",
	"pin_W5_L4_05": "Nora. Lo lograste. Todo lo lograste",
}

const PIN_COLORS := {
	"world1": Color(1.00, 0.80, 0.10),  # dorado
	"world2": Color(1.00, 0.30, 0.60),  # rosa
	"world3": Color(0.30, 0.70, 1.00),  # azul
	"world4": Color(0.65, 0.30, 0.90),  # morado
	"world5": Color(0.90, 0.10, 0.90),  # magenta
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
	if   "W1_" in pin_id or "world1" in pin_id: return "world1"
	elif "W2_" in pin_id or "world2" in pin_id: return "world2"
	elif "W3_" in pin_id or "world3" in pin_id: return "world3"
	elif "W4_" in pin_id or "world4" in pin_id: return "world4"
	return ""

# ── API PÚBLICA ──────────────────────────────
func show_message(text: String, color: Color = Color.WHITE, duration: float = DISPLAY_TIME) -> void:
	_pin_icon.text  = "💬"
	_pin_icon.add_theme_color_override("font_color", color)
	_text_label.text = text
	_timer   = duration
	_showing = true
	_animate_in()
