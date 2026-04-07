extends Boss
# ── JEFE MUNDO 1: LA OLA PERFECTA ────────────
# Mecánica: scroll lateral automático, la ola avanza desde la derecha.
# Nora debe correr, saltar obstáculos y llegar al final.
# 3 velocidades crecientes por fase.

const SCROLL_SPEEDS := [180.0, 240.0, 310.0]
const OBSTACLE_INTERVAL := [2.2, 1.7, 1.2]  # segundos entre obstáculos

var scroll_speed     := 180.0
var spawn_timer      := 0.0
var camera_start_x   := 0.0
var arena_end_x      := 0.0
var reached_end      := false
var wave_sprite      : Node2D
var obstacles        : Array = []

@export var arena_length : float = 1800.0

func _on_boss_ready() -> void:
	world_id   = 1
	max_health = 1  # La ola no tiene HP: se gana llegando al final
	health     = 1
	_build_wave()

	if player:
		camera_start_x = player.global_position.x
		arena_end_x    = player.global_position.x + arena_length
		# Posición inicial de la ola: detrás del jugador
		global_position = Vector2(player.global_position.x - 120.0,
								  player.global_position.y)

func _build_wave() -> void:
	wave_sprite = Node2D.new()
	add_child(wave_sprite)

	# Dibujar la ola como rectángulo azul alto
	var img := Image.create(60, 200, false, Image.FORMAT_RGBA8)
	for y in 200:
		for x in 60:
			var gradient := float(x) / 60.0
			img.set_pixel(x, y, Color(0.0, 0.3 + gradient * 0.4, 0.9, 0.85 - gradient * 0.3))
	var tex := ImageTexture.create_from_image(img)
	var sp  := Sprite2D.new()
	sp.texture = tex
	sp.offset  = Vector2(30, -100)
	wave_sprite.add_child(sp)

func _physics_process(delta: float) -> void:
	if is_defeated or reached_end or player == null:
		return

	# La ola avanza hacia el jugador
	var target_x := player.global_position.x - 80.0
	global_position.x = move_toward(global_position.x, target_x,
									scroll_speed * delta)

	# Forzar que el jugador avance (scroll)
	player.global_position.x += scroll_speed * 0.35 * delta

	# Generar obstáculos
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = OBSTACLE_INTERVAL[phase - 1]
		_spawn_obstacle()

	# ¿La ola alcanzó a Nora?
	if global_position.x >= player.global_position.x - 10:
		player.take_damage(global_position)

	# ¿Nora llegó al final?
	if player.global_position.x >= arena_end_x:
		_player_wins()

func _spawn_obstacle() -> void:
	if player == null:
		return
	# StaticBody2D con sprite visual y colisión real
	var obs := StaticBody2D.new()
	obs.position = Vector2(player.global_position.x + 280.0,
						   player.global_position.y - 16.0)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 32)
	col.shape  = shape
	obs.add_child(col)

	var vis := ColorRect.new()
	vis.size     = Vector2(28, 32)
	vis.position = Vector2(-14.0, -16.0)
	vis.color    = Color(0.25, 0.55, 0.35)
	obs.add_child(vis)

	get_parent().add_child(obs)
	obstacles.append(obs)
	# Destruir tras 6 segundos
	get_tree().create_timer(6.0).timeout.connect(func():
		if is_instance_valid(obs): obs.queue_free()
	)

func _on_phase_changed(p: int) -> void:
	scroll_speed = SCROLL_SPEEDS[p - 1]

func _player_wins() -> void:
	reached_end = true
	# Animación de surf: Nora "salta" sobre la ola
	if player:
		var tw := player.create_tween()
		tw.tween_property(player, "position:y", player.position.y - 40, 0.3)
		tw.tween_property(player, "position:y", player.position.y,       0.3)
	# Limpiar obstáculos
	for obs in obstacles:
		if is_instance_valid(obs): obs.queue_free()
	# Dar pin del jefe vía señal boss_defeated → Level lo conecta
	_defeat()

func _on_defeated() -> void:
	GameManager.collect_pin("pin_W1_Boss_01")
