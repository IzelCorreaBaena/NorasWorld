extends Boss
# ── JEFE MUNDO 3: LA SOMBRA ───────────────────
# Versi de oscura de Nora con las mismas habilidades, sin límites.
# Para dañarla: atraerla hacia las zonas de luz del festival.
# 3 fases: cada fase gana una habilidad más.

const SPEED        := 180.0
const LIGHT_DAMAGE := true   # La luz la daña

var sprite_node  : Sprite2D
var light_zones  : Array = []  # Nodos de tipo Area2D con group "light_zone"
var chase_timer  := 0.0
var phase_skills := {1: false, 2: false, 3: false}  # dash, double_jump, wall_jump
var is_in_light  := false
var light_timer  := 0.0
const LIGHT_TICK := 0.4  # segundos en luz para recibir daño

func _on_boss_ready() -> void:
	world_id   = 3
	max_health = 3
	health     = 3
	_build_sprite()
	# Buscar zonas de luz en el nivel
	await get_tree().process_frame
	light_zones = get_tree().get_nodes_in_group("light_zone")
	if player:
		global_position = player.global_position + Vector2(300.0, 0.0)

func _build_sprite() -> void:
	sprite_node = Sprite2D.new()
	var img := Image.create(28, 48, false, Image.FORMAT_RGBA8)
	# Silueta oscura (copia de Nora pero negra/morada)
	for y in 48:
		for x in 28:
			var dx := float(x) - 14.0
			var is_head := y < 12 and sqrt(dx*dx + (y-6.0)*(y-6.0)) < 7
			var is_body := y >= 12 and y < 36 and abs(dx) < 7
			var is_leg  := y >= 36 and abs(dx - (4.0 if y % 4 < 2 else -4.0)) < 5
			if is_head or is_body or is_leg:
				var alpha := 0.7 + randf() * 0.3
				img.set_pixel(x, y, Color(0.15, 0.05, 0.25, alpha))
	sprite_node.texture = ImageTexture.create_from_image(img)
	sprite_node.offset  = Vector2(0, -24)
	add_child(sprite_node)

	# Aura oscilante
	var tw := create_tween().set_loops()
	tw.tween_property(sprite_node, "modulate:a", 0.6, 0.7)
	tw.tween_property(sprite_node, "modulate:a", 1.0, 0.7)

func _physics_process(delta: float) -> void:
	if is_defeated or player == null:
		return

	# Perseguir al jugador
	var dir := (player.global_position - global_position).normalized()
	global_position += dir * SPEED * delta

	# Comprobar si está en zona de luz
	_check_light_zones(delta)

	# Dañar al jugador al contacto (si no es invencible)
	if global_position.distance_to(player.global_position) < 30:
		player.take_damage(global_position)

func _check_light_zones(delta: float) -> void:
	var in_light := false
	for zone in light_zones:
		if not is_instance_valid(zone):
			continue
		if zone.has_method("get_global_position"):
			# Verificar si la sombra está dentro del radio de la zona
			var radius : float = 80.0
			if zone.has_method("get_radius"):
				radius = zone.call("get_radius")
			if global_position.distance_to(zone.global_position) < radius:
				in_light = true
				break

	if in_light:
		light_timer += delta
		# Flash de luz en la sombra
		sprite_node.modulate = Color(0.8, 0.5, 1.0, 0.5)
		if light_timer >= LIGHT_TICK:
			light_timer = 0.0
			take_hit()
	else:
		light_timer = 0.0
		# Restaurar color si no está recibiendo hit
		if sprite_node.modulate != Color.WHITE:
			sprite_node.modulate = Color.WHITE

func _on_phase_changed(p: int) -> void:
	match p:
		2:
			_start_dash_behavior()
		3:
			_start_erratic_behavior()

func _start_dash_behavior() -> void:
	var tw := create_tween().set_loops()
	tw.tween_interval(1.5)
	tw.tween_callback(func():
		if not is_defeated and player:
			var dir2 := (player.global_position - global_position).normalized()
			global_position += dir2 * 150.0
	)

func _start_erratic_behavior() -> void:
	var tw := create_tween().set_loops()
	tw.tween_interval(0.8)
	tw.tween_callback(func():
		if not is_defeated:
			global_position += Vector2(
				randf_range(-60, 60), randf_range(-40, 10))
	)

func _on_defeated() -> void:
	GameManager.collect_pin("pin_W3_Boss_01")
	# Efecto de desvanecimiento en luz
	var tw := create_tween()
	tw.tween_property(sprite_node, "modulate",
		Color(1.0, 0.8, 1.0, 0.0), 1.0)
