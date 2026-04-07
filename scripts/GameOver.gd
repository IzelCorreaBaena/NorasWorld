extends Node2D

# Pantalla de Game Over y pantalla de créditos/final.
# Se muestra en dos modos:
#   mode = "game_over"  → Nora perdió (viene de Player.die())
#   mode = "ending"     → Nora completó el Mundo 4

@export var mode : String = "game_over"  # "game_over" | "ending"

var _bg       : ColorRect
var _title    : Label
var _subtitle : Label
var _btn      : Button
var _timer    : float = 0.0
const AUTO_ADVANCE := 12.0  # segundos antes de volver al mapa sola en el ending

func _ready() -> void:
	_detect_mode()
	_build_ui()
	_animate_in()

func _detect_mode() -> void:
	# Si todos los mundos están completos → ending, sino game_over
	if GameManager.worlds_completed.size() >= 4:
		mode = "ending"

func _build_ui() -> void:
	var vp := get_viewport_rect().size

	# Fondo
	_bg = ColorRect.new()
	_bg.size    = vp
	_bg.color   = Color(0.04, 0.02, 0.08, 1.0) if mode == "ending" else Color(0.05, 0.0, 0.0, 1.0)
	_bg.modulate.a = 0.0
	add_child(_bg)

	# Partículas decorativas (solo en ending)
	if mode == "ending":
		_spawn_ending_particles()

	# Título
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.size         = Vector2(vp.x, 80)
	_title.position     = Vector2(0, vp.y * 0.22)
	_title.modulate.a   = 0.0
	_title.add_theme_font_size_override("font_size", 32)

	if mode == "ending":
		_title.text = "Ya eres la estilista\nque querías ser."
		_title.add_theme_color_override("font_color", Color(0.85, 0.5, 1.0))
	else:
		_title.text = "GAME OVER"
		_title.add_theme_color_override("font_color", Color(0.9, 0.25, 0.25))

	add_child(_title)

	# Subtítulo
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.size       = Vector2(vp.x * 0.7, 80)
	_subtitle.position   = Vector2(vp.x * 0.15, vp.y * 0.52)
	_subtitle.modulate.a = 0.0
	_subtitle.add_theme_font_size_override("font_size", 14)
	_subtitle.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

	if mode == "ending":
		var pins := GameManager.pins_collected.size()
		_subtitle.text = "Recuerdos recuperados: %d / 20\n\nGracias por jugar con Nora." % pins
	else:
		_subtitle.text = "Nora se levanta.\nSiempre se levanta."

	add_child(_subtitle)

	# Botón
	_btn = Button.new()
	_btn.text     = "Volver al mapa" if mode == "ending" else "Intentar de nuevo"
	_btn.size     = Vector2(200, 44)
	_btn.position = Vector2((vp.x - 200.0) * 0.5, vp.y * 0.76)
	_btn.modulate.a = 0.0
	_btn.add_theme_font_size_override("font_size", 14)
	_btn.pressed.connect(_on_btn_pressed)
	add_child(_btn)

func _animate_in() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(_bg,       "modulate:a", 1.0, 0.5)
	tw.tween_property(_title,    "modulate:a", 1.0, 0.8).set_delay(0.3)
	tw.tween_property(_subtitle, "modulate:a", 1.0, 0.8).set_delay(0.7)
	tw.tween_property(_btn,      "modulate:a", 1.0, 0.8).set_delay(1.2)

func _process(delta: float) -> void:
	if mode == "ending":
		_timer += delta
		if _timer >= AUTO_ADVANCE:
			_go_to_map()

func _on_btn_pressed() -> void:
	if mode == "ending":
		_go_to_map()
	else:
		GameManager.restore_full_health()
		var level := GameManager.current_level
		if level == "" or not ResourceLoader.exists(level):
			level = "res://scenes/WorldMap.tscn"
			GameManager.clear_checkpoint()
		get_tree().change_scene_to_file(level)

func _go_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")

func _spawn_ending_particles() -> void:
	var colors := [
		Color(1.0, 0.8, 0.1),
		Color(1.0, 0.3, 0.6),
		Color(0.3, 0.7, 1.0),
		Color(0.65, 0.3, 0.9),
	]
	var vp := get_viewport_rect().size
	for i in 4:
		var p := CPUParticles2D.new()
		p.emitting             = true
		p.amount               = 20
		p.lifetime             = 3.0
		p.spread               = 180.0
		p.gravity              = Vector2(0, -20.0)
		p.initial_velocity_min = 20.0
		p.initial_velocity_max = 60.0
		p.scale_amount_min     = 2.0
		p.scale_amount_max     = 5.0
		p.color                = colors[i]
		p.position = Vector2(vp.x * (0.2 + i * 0.2), vp.y * 0.85)
		add_child(p)
