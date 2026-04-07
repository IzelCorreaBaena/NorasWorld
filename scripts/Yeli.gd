extends Node2D

# ── CONSTANTES ───────────────────────────────
const LERP_SPEED          := 0.08
const OFFSET_X            := 30.0
const OFFSET_Y            := -20.0
const FLOAT_AMP           := 4.0
const FLOAT_FREQ          := 2.5
const PIN_DETECT_RADIUS   := 150.0
const ENEMY_DETECT_RADIUS := 200.0

# ── ESTADO ───────────────────────────────────
var player        : Node2D = null
var float_time    := 0.0
var is_sad        := false
var emoji_visible := false

# Nodos de la escena
@onready var sprite      : Sprite2D       = $Sprite2D
@onready var emoji_label : Label          = $EmojiLabel
@onready var sparkles    : CPUParticles2D = $Sparkles

# ── INIT ─────────────────────────────────────
func _ready() -> void:
	add_to_group("yeli")
	_build_sprite()

	emoji_label.add_theme_font_size_override("font_size", 20)

	sparkles.one_shot             = true
	sparkles.lifetime             = 0.6
	sparkles.spread               = 180.0
	sparkles.gravity              = Vector2(0.0, -40.0)
	sparkles.initial_velocity_min = 40.0
	sparkles.initial_velocity_max = 80.0
	sparkles.scale_amount_min     = 2.0
	sparkles.scale_amount_max     = 4.0
	sparkles.color                = Color(1.0, 0.9, 0.1, 1.0)

	GameManager.pin_collected.connect(_on_pin_collected)
	GameManager.game_over.connect(_on_game_over)

func _build_sprite() -> void:
	var img  := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var body := Color(1.0, 0.85, 0.05, 1.0)
	var edge := Color(0.85, 0.65, 0.00, 1.0)
	for y in 16:
		for x in 16:
			var dx   := float(x) - 8.0
			var dy   := float(y) - 8.0
			var dist := sqrt(dx * dx + dy * dy)
			if   dist < 6.5: img.set_pixel(x, y, body)
			elif dist < 7.5: img.set_pixel(x, y, edge)
	sprite.texture = ImageTexture.create_from_image(img)

# ── LOOP PRINCIPAL ───────────────────────────
func _process(delta: float) -> void:
	if player == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		return

	float_time += delta
	_follow_player()

	if not is_sad:
		_detect_nearby()

# ── SEGUIR AL JUGADOR ────────────────────────
func _follow_player() -> void:
	var facing_right := true
	if "facing_right" in player:
		facing_right = player.facing_right

	var off_x := OFFSET_X if facing_right else -OFFSET_X
	var off_y := OFFSET_Y
	var lean  := 0.0

	if "velocity" in player:
		var vx: float = player.velocity.x
		var vy: float = player.velocity.y
		if abs(vx) > 30.0:
			lean = -8.0 if vx > 0.0 else 8.0
		if vy < -100.0:
			off_y -= 8.0

	sprite.rotation_degrees = lerp(sprite.rotation_degrees, lean, 0.15)

	var float_y := sin(float_time * FLOAT_FREQ) * FLOAT_AMP
	var target  := player.global_position + Vector2(off_x, off_y + float_y)
	global_position = global_position.lerp(target, LERP_SPEED)

# ── DETECCIÓN DE CERCANÍA ────────────────────
func _detect_nearby() -> void:
	var pin_dist   := _nearest_in_group("collectible")
	var enemy_dist := _nearest_in_group("enemy")

	if pin_dist < PIN_DETECT_RADIUS:
		_set_emoji("🔍")
	elif enemy_dist < ENEMY_DETECT_RADIUS:
		_set_emoji("⚠️")
	else:
		_clear_emoji()

func _nearest_in_group(group: String) -> float:
	var best := INF
	for node in get_tree().get_nodes_in_group(group):
		var d := global_position.distance_to(node.global_position)
		if d < best:
			best = d
	return best

# ── SISTEMA DE EMOJIS ────────────────────────
func _set_emoji(emoji: String) -> void:
	if emoji_label.text == emoji and emoji_visible:
		return
	emoji_label.text = emoji
	if not emoji_visible:
		emoji_visible = true
		var tw := create_tween()
		tw.tween_property(emoji_label, "modulate:a", 1.0, 0.25)

func _clear_emoji() -> void:
	if not emoji_visible:
		return
	emoji_visible = false
	var tw := create_tween()
	tw.tween_property(emoji_label, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): emoji_label.text = "")

# ── REACCIONES A EVENTOS ─────────────────────
func _on_pin_collected(_pin_id: String) -> void:
	emoji_label.text = "✨"
	emoji_visible    = true
	var tw := create_tween()
	tw.tween_property(emoji_label, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(
		sprite, "rotation_degrees", 360.0, 0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func():
		sprite.rotation_degrees = 0.0
		sparkles.restart()
		sparkles.emitting = true
	)
	tw.tween_interval(1.5)
	tw.tween_property(emoji_label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		emoji_label.text = ""
		emoji_visible    = false
	)

func _on_game_over() -> void:
	is_sad               = true
	emoji_label.text     = "😢"
	emoji_visible        = true
	emoji_label.modulate.a = 1.0

# ── API PÚBLICA ──────────────────────────────
func show_boss_nearby() -> void:
	_set_emoji("💀")

func show_secret_nearby() -> void:
	_set_emoji("✨")
