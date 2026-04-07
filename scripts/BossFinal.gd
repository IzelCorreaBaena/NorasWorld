extends Boss
# ── JEFE MUNDO 5: LA NORA PERDIDA ───────────
# Versión corrupta de Nora que combina los 4 jefes anteriores.
# Fase 1 (HP 9-7): Scroll lateral como La Ola (BossWave)
# Fase 2 (HP 6-4): Copia movimientos con delay como El Maniquí (BossMannequin)
# Fase 3 (HP 3-1): Fragmentos de luz/oscuridad (BossShadow + BossMirror)
# Recompensa: pin_W5_Boss

# === CONSTANTS ===
const SCROLL_SPEED_BASE  := 160.0
const COPY_DELAY         := 0.8
const FRAGMENT_COUNT     := 3
const CHASE_SPEED        := 150.0
const ARENA_MIN          := Vector2(40.0, 60.0)
const ARENA_MAX          := Vector2(440.0, 250.0)

const FRAGMENT_COLORS := [
	Color(0.9, 0.8, 0.2),  # luz dorada
	Color(0.3, 0.1, 0.5),  # oscuridad
	Color(1.0, 0.4, 0.7),  # rosa corrupto
]

# === PRIVATE VARIABLES ===
var _sprite_node    : Sprite2D
var _scroll_speed   := SCROLL_SPEED_BASE
var _arena_end_x    := 0.0
var _scroll_active  := false

# Fase 2: copia de movimientos
var _move_history   : Array = []
var _copy_active    := false

# Fase 3: fragmentos + persecución
var _fragments      : Array = []
var _chase_active   := false
var _frag_spawn_timer := 0.0

# Obstáculos de fase 1
var _obstacle_timer := 0.0
var _obstacles      : Array = []

# === BUILT-IN CALLBACKS ===
func _on_boss_ready() -> void:
	world_id   = 5
	max_health = 9
	health     = 9
	_build_sprite()
	_start_phase_1()

func _physics_process(delta: float) -> void:
	if is_defeated or player == null:
		return

	match phase:
		1: _process_phase_1(delta)
		2: _process_phase_2(delta)
		3: _process_phase_3(delta)

# === PRIVATE METHODS ===
func _build_sprite() -> void:
	_sprite_node = Sprite2D.new()
	var img := Image.create(28, 48, false, Image.FORMAT_RGBA8)
	# Silueta corrupta: mezcla de colores oscuros y brillantes
	for y in 48:
		for x in 28:
			var dx := float(x) - 14.0
			var is_head := y < 12 and sqrt(dx * dx + (y - 6.0) * (y - 6.0)) < 7
			var is_body := y >= 12 and y < 36 and abs(dx) < 7
			var is_leg  := y >= 36 and abs(dx - (4.0 if y % 4 < 2 else -4.0)) < 5
			if is_head or is_body or is_leg:
				# Gradiente corrupto: morado oscuro con destellos dorados
				var t := float(y) / 48.0
				var base_col := Color(0.4, 0.1, 0.5).lerp(Color(0.9, 0.7, 0.1), t * 0.3)
				img.set_pixel(x, y, base_col)
	_sprite_node.texture = ImageTexture.create_from_image(img)
	_sprite_node.offset  = Vector2(0, -24)
	add_child(_sprite_node)

	# Aura pulsante corrupta
	var tw := create_tween().set_loops()
	tw.tween_property(_sprite_node, "modulate",
		Color(1.2, 0.8, 1.5), 0.6)
	tw.tween_property(_sprite_node, "modulate",
		Color(0.8, 0.6, 1.0), 0.6)

# ── FASE 1: LA OLA (scroll lateral) ─────────
func _start_phase_1() -> void:
	_scroll_active = true
	_copy_active   = false
	_chase_active  = false
	if player:
		global_position = Vector2(player.global_position.x - 100.0,
								  player.global_position.y)
		_arena_end_x = player.global_position.x + 800.0

func _process_phase_1(delta: float) -> void:
	if not _scroll_active:
		return

	# Avanzar hacia el jugador como la ola
	var target_x := player.global_position.x - 70.0
	global_position.x = move_toward(global_position.x, target_x,
									_scroll_speed * delta)

	# Forzar avance del jugador
	player.global_position.x += _scroll_speed * 0.3 * delta

	# Generar obstaculos
	_obstacle_timer -= delta
	if _obstacle_timer <= 0.0:
		_obstacle_timer = 1.8
		_spawn_phase1_obstacle()

	# Contacto = dano
	if global_position.x >= player.global_position.x - 10:
		player.take_damage(global_position)

func _spawn_phase1_obstacle() -> void:
	if player == null:
		return
	var obs := StaticBody2D.new()
	obs.position = Vector2(player.global_position.x + 260.0,
						   player.global_position.y - 16.0)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 28)
	col.shape  = shape
	obs.add_child(col)

	var vis := ColorRect.new()
	vis.size     = Vector2(24, 28)
	vis.position = Vector2(-12.0, -14.0)
	vis.color    = Color(0.35, 0.15, 0.45)
	obs.add_child(vis)

	get_parent().add_child(obs)
	_obstacles.append(obs)
	get_tree().create_timer(5.0).timeout.connect(func():
		if is_instance_valid(obs): obs.queue_free()
	)

# ── FASE 2: EL MANIQUI (copia con delay) ────
func _start_phase_2() -> void:
	_scroll_active = false
	_copy_active   = true
	_chase_active  = false
	_move_history.clear()
	# Limpiar obstaculos de fase 1
	for obs in _obstacles:
		if is_instance_valid(obs): obs.queue_free()
	_obstacles.clear()
	# Reposicionar en el arena
	if player:
		global_position = player.global_position + Vector2(180.0, 0.0)

func _process_phase_2(delta: float) -> void:
	if not _copy_active:
		return

	# Guardar historial de posicion del jugador
	var now := Time.get_ticks_msec() / 1000.0
	_move_history.append({"pos": player.global_position, "time": now})
	# Limpiar historial viejo
	var cutoff := now - COPY_DELAY - 0.5
	while _move_history.size() > 0 and _move_history[0]["time"] < cutoff:
		_move_history.pop_front()

	# Seguir la posicion del jugador con delay
	var target_time := now - COPY_DELAY
	var target_pos  := _interpolate_history(target_time)
	if target_pos != Vector2.ZERO:
		global_position = global_position.lerp(target_pos, 0.15)

	# Rebote en paredes del arena = dano al jefe
	if global_position.x < ARENA_MIN.x or global_position.x > ARENA_MAX.x:
		take_hit()
		global_position.x = clampf(global_position.x,
			ARENA_MIN.x + 20.0, ARENA_MAX.x - 20.0)

	# Contacto = dano al jugador
	if global_position.distance_to(player.global_position) < 28:
		player.take_damage(global_position)

func _interpolate_history(t: float) -> Vector2:
	if _move_history.size() < 2:
		return Vector2.ZERO
	for i in range(_move_history.size() - 1, 0, -1):
		if _move_history[i]["time"] <= t:
			var a : Dictionary = _move_history[i]
			var b : Dictionary = _move_history[min(i + 1, _move_history.size() - 1)]
			var dt := b["time"] - a["time"]
			if dt <= 0:
				return a["pos"]
			var frac := (t - a["time"]) / dt
			return a["pos"].lerp(b["pos"], frac)
	return _move_history[0]["pos"]

# ── FASE 3: LUZ Y OSCURIDAD (fragmentos) ────
func _start_phase_3() -> void:
	_scroll_active = false
	_copy_active   = false
	_chase_active  = true
	_move_history.clear()
	# Generar fragmentos iniciales
	_spawn_fragments()

func _process_phase_3(delta: float) -> void:
	if not _chase_active:
		return

	# Perseguir al jugador (como BossShadow)
	var dir := (player.global_position - global_position).normalized()
	global_position += dir * CHASE_SPEED * delta

	# Contacto = dano
	if global_position.distance_to(player.global_position) < 28:
		player.take_damage(global_position)

	# Regenerar fragmentos periodicamente
	_frag_spawn_timer -= delta
	if _frag_spawn_timer <= 0.0:
		_frag_spawn_timer = 3.5
		_spawn_single_fragment()

func _spawn_fragments() -> void:
	for i in FRAGMENT_COUNT:
		_spawn_single_fragment()

func _spawn_single_fragment() -> void:
	# Fragmento flotante que dana al jugador y puede ser golpeado para danar al jefe
	var frag := Area2D.new()
	frag.add_to_group("boss_fragment")
	var angle := randf() * TAU
	var radius := randf_range(80.0, 160.0)
	frag.global_position = global_position + Vector2(cos(angle), sin(angle)) * radius

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	col.shape = circle
	frag.add_child(col)

	var vis := ColorRect.new()
	var color_idx := randi() % FRAGMENT_COLORS.size()
	vis.size     = Vector2(16, 16)
	vis.position = Vector2(-8, -8)
	vis.color    = FRAGMENT_COLORS[color_idx]
	frag.add_child(vis)

	get_parent().add_child(frag)
	_fragments.append(frag)

	# El jugador puede golpear el fragmento para danar al jefe
	frag.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			# Verificar si el jugador viene desde arriba (stomp) o esta en dash
			var coming_from_above := body.global_position.y < frag.global_position.y - 5
			if coming_from_above:
				take_hit()
				_break_fragment(frag)
			else:
				body.take_damage(frag.global_position)
	)

	# Animacion de flotacion
	var tw := frag.create_tween().set_loops()
	var base_y := frag.position.y
	tw.tween_property(frag, "position:y", base_y - 6.0, 0.7)
	tw.tween_property(frag, "position:y", base_y,       0.7)

	# Autodestruccion tras 8 segundos
	get_tree().create_timer(8.0).timeout.connect(func():
		if is_instance_valid(frag):
			_fragments.erase(frag)
			frag.queue_free()
	)

func _break_fragment(frag: Area2D) -> void:
	if not is_instance_valid(frag):
		return
	_fragments.erase(frag)
	# Efecto de explosion
	var tw := frag.create_tween()
	tw.tween_property(frag, "scale", Vector2(2.0, 2.0), 0.1)
	tw.tween_property(frag, "modulate:a", 0.0, 0.2)
	tw.tween_callback(frag.queue_free)

# ── CAMBIO DE FASE ───────────────────────────
func _on_phase_changed(p: int) -> void:
	match p:
		2: _start_phase_2()
		3: _start_phase_3()

func _on_hit() -> void:
	# Flash adicional con color corrupto
	var tw := create_tween()
	tw.tween_property(_sprite_node, "modulate",
		Color(1.5, 0.3, 1.0), 0.08)
	tw.tween_property(_sprite_node, "modulate",
		Color(1.0, 0.8, 1.2), 0.15)

func _on_defeated() -> void:
	GameManager.collect_pin("pin_W5_Boss")
	# Limpiar fragmentos restantes
	for frag in _fragments:
		if is_instance_valid(frag): frag.queue_free()
	_fragments.clear()
	for obs in _obstacles:
		if is_instance_valid(obs): obs.queue_free()
	_obstacles.clear()
	# Efecto final: explosion de luz y oscuridad
	for i in 12:
		var sp := ColorRect.new()
		sp.size  = Vector2(10, 10)
		sp.color = FRAGMENT_COLORS[i % FRAGMENT_COLORS.size()]
		sp.position = global_position + Vector2(
			randf_range(-60, 60), randf_range(-50, 30))
		get_parent().add_child(sp)
		var tw := sp.create_tween()
		tw.tween_property(sp, "position:y", sp.position.y - 40.0, 0.8 + i * 0.05)
		tw.tween_property(sp, "modulate:a", 0.0, 0.5)
		tw.tween_callback(sp.queue_free)
