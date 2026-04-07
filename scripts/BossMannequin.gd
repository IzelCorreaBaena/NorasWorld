extends "res://scripts/Boss.gd"
# ── JEFE MUNDO 2: EL MANIQUÍ ─────────────────
# Copia el último movimiento de Nora con delay.
# Para dañarle: hacer que se golpee contra las paredes.
# 3 fases — el delay disminuye.

const DELAYS    := [1.0, 0.65, 0.35]  # segundos de delay por fase
const ARENA_MIN := Vector2(50.0,  80.0)
const ARENA_MAX := Vector2(550.0, 280.0)

var delay_time   := 1.0
var move_history : Array = []   # Array de {pos, time}
var sprite_node  : Sprite2D
var hits_taken   := 0

func _on_boss_ready() -> void:
	world_id   = 2
	max_health = 3
	health     = 3
	_build_sprite()
	# Empezar en el centro del arena
	if player:
		global_position = player.global_position + Vector2(200.0, 0.0)

func _build_sprite() -> void:
	sprite_node = Sprite2D.new()
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	# Cuerpo del maniquí (blanco articulado)
	for y in 48:
		for x in 32:
			var is_body    := y > 10 and y < 38 and x > 8 and x < 24
			var is_head    := y < 10 and x > 10 and x < 22
			var is_legs    := y >= 38 and (x < 12 or x > 20)
			if is_body or is_head or is_legs:
				img.set_pixel(x, y, Color(0.92, 0.92, 0.92))
	sprite_node.texture = ImageTexture.create_from_image(img)
	sprite_node.offset  = Vector2(0, -24)
	add_child(sprite_node)

func _physics_process(delta: float) -> void:
	if is_defeated or player == null:
		return

	# Guardar historial de posición del jugador
	move_history.append({"pos": player.global_position, "time": Time.get_ticks_msec() / 1000.0})
	# Limpiar historial viejo (solo necesitamos delay_time + 0.5 s)
	var now    := Time.get_ticks_msec() / 1000.0
	var cutoff := now - delay_time - 0.5
	while move_history.size() > 0 and move_history[0]["time"] < cutoff:
		move_history.pop_front()

	# Moverse a la posición del jugador de hace delay_time segundos
	var target_time := now - delay_time
	var target_pos  := _interpolate_history(target_time)
	if target_pos != Vector2.ZERO:
		global_position = global_position.lerp(target_pos, 0.12)

	# Rebotar en paredes del arena → daño al maniquí
	if global_position.x < ARENA_MIN.x or global_position.x > ARENA_MAX.x:
		take_hit()
		_bounce_from_wall()

func _interpolate_history(t: float) -> Vector2:
	if move_history.size() < 2:
		return Vector2.ZERO
	for i in range(move_history.size() - 1, 0, -1):
		if move_history[i]["time"] <= t:
			var a : Dictionary = move_history[i]
			var b : Dictionary = move_history[min(i + 1, move_history.size() - 1)]
			var dt = b["time"] - a["time"]
			if dt <= 0:
				return a["pos"]
			var frac = (t - a["time"]) / dt
			return a["pos"].lerp(b["pos"], frac)
	return move_history[0]["pos"]

func _bounce_from_wall() -> void:
	var tw := create_tween()
	var bounce_x := ARENA_MIN.x + (ARENA_MAX.x - ARENA_MIN.x) * 0.5
	tw.tween_property(self, "position:x", bounce_x, 0.25).set_ease(Tween.EASE_OUT)

func _on_phase_changed(p: int) -> void:
	delay_time = DELAYS[p - 1]

func _on_hit() -> void:
	hits_taken += 1

func _on_defeated() -> void:
	GameManager.collect_pin("pin_W2_Boss_01")
	# El maniquí se fragmenta en pines de colores (visual)
	for i in 8:
		var frag := ColorRect.new()
		frag.size  = Vector2(8, 8)
		frag.color = Color(1.0, 0.3, 0.6, 0.9)
		frag.position = global_position + Vector2(
			randf_range(-40, 40), randf_range(-40, 20))
		get_parent().add_child(frag)
		var tw := frag.create_tween()
		tw.tween_property(frag, "modulate:a", 0.0, 0.6)
		tw.tween_callback(frag.queue_free)
