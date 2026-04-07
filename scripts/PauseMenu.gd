extends CanvasLayer

var _visible_menu := false
var _bg  : ColorRect
var _vbox: VBoxContainer

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")
	_build_ui()
	hide_menu()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _visible_menu:
			hide_menu()
		else:
			show_menu()

func show_menu() -> void:
	_visible_menu  = true
	_bg.visible    = true
	get_tree().paused = true

func hide_menu() -> void:
	_visible_menu  = false
	_bg.visible    = false
	get_tree().paused = false

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.name = "PauseBG"
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color        = Color(0.0, 0.0, 0.0, 0.65)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	# Panel central
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -110.0
	panel.offset_right  =  110.0
	panel.offset_top    = -100.0
	panel.offset_bottom =  100.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.20, 0.95)
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left   = 20.0
	style.content_margin_right  = 20.0
	style.content_margin_top    = 16.0
	style.content_margin_bottom = 16.0
	style.border_color = Color(0.55, 0.35, 0.90, 0.70)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	_bg.add_child(panel)

	_vbox = VBoxContainer.new()
	_vbox.name = "MenuItems"
	_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(_vbox)

	# Título
	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.55, 0.20, 0.90, 0.60))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	_vbox.add_child(title)

	# Separador visual
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.55, 0.35, 0.90, 0.40))
	_vbox.add_child(sep)

	_add_button("Continuar",       Color(0.20, 0.65, 0.30), func(): hide_menu())
	_add_button("Reiniciar nivel", Color(0.70, 0.45, 0.10), func(): _restart())
	_add_button("Volver al mapa",  Color(0.15, 0.45, 0.80), func(): _go_map())
	_add_button("Salir",           Color(0.70, 0.10, 0.10), func(): get_tree().quit())

func _add_button(text: String, base_color: Color, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style := StyleBoxFlat.new()
	style.bg_color = base_color.darkened(0.20)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_top    = 6.0
	style.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("normal", style)
	var style_h := style.duplicate() as StyleBoxFlat
	style_h.bg_color = base_color.lightened(0.10)
	btn.add_theme_stylebox_override("hover", style_h)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

	btn.pressed.connect(callback)
	_vbox.add_child(btn)

func _restart() -> void:
	get_tree().paused = false
	if GameManager.has_method("restore_full_health"):
		GameManager.restore_full_health()
	get_tree().reload_current_scene()

func _go_map() -> void:
	get_tree().paused = false
	SceneTransition.go_to("res://scenes/WorldMap.tscn")
