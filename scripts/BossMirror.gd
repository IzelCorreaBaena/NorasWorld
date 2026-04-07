extends Boss
# ── JEFE MUNDO 4: EL ESPEJO ROTO ─────────────
# 7 fragmentos flotantes que crean copias fantasma de Nora.
# Las copias repiten el movimiento de hace 3 segundos.
# Para ganar: romper los fragmentos en orden (color indicado).
# Cada fragmento roto muestra un recuerdo (texto breve).

const FRAGMENT_COUNT  := 7
const GHOST_DELAY     := 3.0
const FRAGMENT_ORDER_COLORS := [
	Color(0.9, 0.3, 0.3),   # rojo
	Color(1.0, 0.6, 0.1),   # naranja
	Color(1.0, 0.9, 0.1),   # amarillo
	Color(0.3, 0.9, 0.3),   # verde
	Color(0.2, 0.6, 1.0),   # azul
	Color(0.7, 0.3, 0.9),   # morado
	Color(1.0, 0.5, 0.8),   # rosa
]
const MEMORY_TEXTS := [
	"Recuerdas la primera vez que entraste a una tienda de telas.",
	"Recuerdas cuando diseñaste tu primer outfit.",
	"Recuerdas a tus amigos aplaudiéndote.",
	"Recuerdas el mar y la tabla de surf.",
	"Recuerdas la música del festival.",
	"Recuerdas a Yeli apareciendo por primera vez.",
	"Recuerdas quién eres. Siempre lo supiste.",
]

var fragments     : Array = []   # Nodos de fragmentos
var ghost_copies  : Array = []
var move_history  : Array = []
var current_target_fragment := 0  # índice del siguiente fragmento a romper
var dialog_system : Node = null

func _on_boss_ready() -> void:
	world_id   = 4
	max_health = FRAGMENT_COUNT
	health     = FRAGMENT_COUNT
	_build_fragments()
	_build_ghost()
	# Buscar DialogSystem
	await get_tree().process_frame
	for node in get_tree().get_nodes_in_group("dialog"):
		dialog_system = node
		break
	if dialog_system == null:
		dialog_system = get_tree().root.find_child("DialogSystem", true, false)

func _build_fragments() -> void:
	var center := Vector2(300, 150)
	for i in FRAGMENT_COUNT:
		var angle  := (TAU / FRAGMENT_COUNT) * i - PI * 0.5
		var radius := 130.0
		var frag   := _make_fragment(i)
		frag.position = center + Vector2(cos(angle), sin(angle)) * radius
		add_child(frag)
		fragments.append(frag)
		# Animación de flotación
		var tw := frag.create_tween().set_loops()
		var oy := frag.position.y
		tw.tween_property(frag, "position:y", oy - 8.0, 0.9 + i * 0.1).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(frag, "position:y", oy,       0.9 + i * 0.1).set_ease(Tween.EASE_IN_OUT)

func _make_fragment(idx: int) -> Node2D:
	var node := Node2D.new()
	node.name = "Fragment%d" % idx
	node.set_meta("frag_index", idx)
	node.set_meta("broken", false)

	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var col := FRAGMENT_ORDER_COLORS[idx]
	# Forma de rombo / fragmento irregular
	for y in 24:
		for x in 24:
			var dx := float(x) - 12.0
			var dy := float(y) - 12.0
			if abs(dx) + abs(dy) < 10.0:
				# Añadir textura de espejo (brillo diagonal)
				var shine := (float(x + y) / 48.0)
				img.set_pixel(x, y, col.lerp(Color.WHITE, shine * 0.4))
	var sp := Sprite2D.new()
	sp.texture = ImageTexture.create_from_image(img)
	node.add_child(sp)

	# Área de colisión para que el jugador pueda golpearla
	var area := Area2D.new()
	var col_shape := CollisionShape2D.new()
	var circle    := CircleShape2D.new()
	circle.radius = 14.0
	col_shape.shape = circle
	area.add_child(col_shape)
	area.body_entered.connect(func(body):
		if body.is_in_group("player"):
			_on_fragment_hit(idx)
	)
	node.add_child(area)

	# Pulso de brillo para el fragmento activo
	var tw2 := sp.create_tween().set_loops()
	tw2.tween_property(sp, "modulate:a", 0.5, 0.5)
	tw2.tween_property(sp, "modulate:a", 1.0, 0.5)

	return node

func _build_ghost() -> void:
	# Copia fantasma (semitransparente)
	var ghost := Sprite2D.new()
	ghost.name    = "Ghost"
	var img       := Image.create(28, 48, false, Image.FORMAT_RGBA8)
	for y in 48:
		for x in 28:
			var dx := float(x) - 14.0
			var dist := sqrt(dx*dx + (float(y)-24.0)*(float(y)-24.0))
			if dist < 14:
				img.set_pixel(x, y, Color(0.7, 0.7, 1.0, 0.35))
	ghost.texture = ImageTexture.create_from_image(img)
	ghost.offset  = Vector2(0, -24)
	add_child(ghost)
	ghost_copies.append(ghost)

func _physics_process(delta: float) -> void:
	if is_defeated or player == null:
		return

	# Guardar historial de posición del jugador
	var now := Time.get_ticks_msec() / 1000.0
	move_history.append({"pos": player.global_position, "time": now})
	# Limpiar historial viejo
	while move_history.size() > 0 and move_history[0]["time"] < now - GHOST_DELAY - 0.5:
		move_history.pop_front()

	# Mover el fantasma a la posición de hace GHOST_DELAY segundos
	var target_time := now - GHOST_DELAY
	var ghost_pos   := _interpolate_history(target_time)
	if ghost_pos != Vector2.ZERO and ghost_copies.size() > 0:
		ghost_copies[0].global_position = ghost_pos

	# Resaltar el fragmento que debe romperse siguiente
	_highlight_current_fragment()

func _interpolate_history(t: float) -> Vector2:
	if move_history.size() < 2:
		return Vector2.ZERO
	for i in range(move_history.size() - 1, 0, -1):
		if move_history[i]["time"] <= t:
			var a := move_history[i]
			var b := move_history[min(i + 1, move_history.size() - 1)]
			var dt := b["time"] - a["time"]
			if dt <= 0: return a["pos"]
			return a["pos"].lerp(b["pos"], (t - a["time"]) / dt)
	return move_history[0]["pos"]

func _highlight_current_fragment() -> void:
	for i in fragments.size():
		var frag := fragments[i]
		if frag == null or not is_instance_valid(frag):
			continue
		if frag.get_meta("broken"):
			continue
		var sp := frag.get_child(0) as Sprite2D
		if sp == null:
			continue
		if i == current_target_fragment:
			# Brillo blanco intenso
			sp.modulate = Color(1.5, 1.5, 1.5)
		else:
			sp.modulate = Color(0.6, 0.6, 0.6, 0.7)

func _on_fragment_hit(idx: int) -> void:
	if idx != current_target_fragment:
		# Orden incorrecto: flash de error
		_wrong_order_fx()
		return
	if fragments[idx].get_meta("broken"):
		return

	fragments[idx].set_meta("broken", true)
	_break_fragment_fx(idx)

	# Mostrar recuerdo
	if dialog_system and dialog_system.has_method("show_message"):
		dialog_system.show_message(MEMORY_TEXTS[idx],
			FRAGMENT_ORDER_COLORS[idx], 4.0)

	current_target_fragment += 1
	take_hit()

func _break_fragment_fx(idx: int) -> void:
	var frag := fragments[idx]
	var tw   := frag.create_tween()
	tw.tween_property(frag, "scale",        Vector2(1.8, 1.8), 0.12)
	tw.tween_property(frag, "modulate:a",   0.0,               0.3)
	tw.tween_callback(frag.queue_free)
	fragments[idx] = null  # marcar como nulo

func _wrong_order_fx() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.0, 0.3, 0.3), 0.1)
	tw.tween_property(self, "modulate", Color.WHITE,           0.2)

func _on_defeated() -> void:
	GameManager.collect_pin("pin_W4_Boss_01")
	# Escena final: todos los fragmentos explotan en destellos
	for i in FRAGMENT_ORDER_COLORS.size():
		var sp := ColorRect.new()
		sp.size  = Vector2(12, 12)
		sp.color = FRAGMENT_ORDER_COLORS[i]
		sp.position = Vector2(randf_range(50, 550), randf_range(50, 280))
		get_parent().add_child(sp)
		var tw2 := sp.create_tween()
		tw2.tween_property(sp, "modulate:a", 0.0, 1.2 + i * 0.1)
		tw2.tween_callback(sp.queue_free)
