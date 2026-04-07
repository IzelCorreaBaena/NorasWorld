extends Area2D
# ── ENEMIGO VOLADOR ──────────────────────────
# Patrulla horizontalmente con movimiento sinusoidal vertical.
# Daña al jugador al contacto.

# === EXPORTS ===
@export var speed        : float = 80.0
@export var amplitude    : float = 40.0
@export var frequency    : float = 1.5
@export var patrol_dist  : float = 150.0

# === PRIVATE VARIABLES ===
var _start_pos  : Vector2
var _time_acc   : float = 0.0
var _direction  := 1.0
var _dist_moved := 0.0

# === BUILT-IN CALLBACKS ===
func _ready() -> void:
	_start_pos = global_position
	add_to_group("enemy")
	collision_layer = 4
	collision_mask  = 1
	body_entered.connect(_on_body_entered)
	_build_sprite()

func _process(delta: float) -> void:
	_time_acc   += delta
	_dist_moved += speed * delta

	global_position.x += _direction * speed * delta
	global_position.y  = _start_pos.y + sin(_time_acc * frequency * TAU) * amplitude

	if _dist_moved >= patrol_dist:
		_direction  *= -1.0
		_dist_moved  = 0.0

# === PRIVATE METHODS ===
func _build_sprite() -> void:
	var sprite := Sprite2D.new()
	var img    := Image.create(20, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.133, 0.667, 0.8, 1.0))  # cian #22AACC
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)

	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 14)
	col.shape  = shape
	add_child(col)

# === SIGNAL CALLBACKS ===
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(global_position)
