extends Area2D
## Hazard (spikes/danger zone) — deals normal damage on contact.
## Visual: dark red base with triangular spikes on top.

# === CONSTANTS ===
const SPIKE_COLOR   := Color(0.55, 0.08, 0.08)
const BASE_COLOR    := Color(0.35, 0.05, 0.05)
const SPIKE_WIDTH   := 8.0
const SPIKE_HEIGHT  := 8.0

# === EXPORTS ===
@export var hazard_size := Vector2(32, 12)

# === PRIVATE VARIABLES ===
var _base_rect: ColorRect

# === BUILT-IN CALLBACKS ===
func _ready() -> void:
	add_to_group("hazard")
	_build_collision()
	_build_visuals()
	body_entered.connect(_on_body_entered)

# === PRIVATE METHODS ===
func _build_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = hazard_size
	col.shape = shape
	add_child(col)

func _build_visuals() -> void:
	# Dark red base rectangle
	_base_rect = ColorRect.new()
	_base_rect.size = hazard_size
	_base_rect.position = -hazard_size * 0.5
	_base_rect.color = BASE_COLOR
	_base_rect.z_index = 1
	add_child(_base_rect)

	# Triangular spikes on top — rows of small V-shaped ColorRects
	var spike_count := int(hazard_size.x / SPIKE_WIDTH)
	for i in spike_count:
		# Each spike is two small rotated ColorRects forming a V / triangle
		var cx := -hazard_size.x * 0.5 + i * SPIKE_WIDTH + SPIKE_WIDTH * 0.5
		var base_y := -hazard_size.y * 0.5

		# Left side of spike
		var left := ColorRect.new()
		left.size = Vector2(SPIKE_WIDTH * 0.5, SPIKE_HEIGHT)
		left.position = Vector2(cx - SPIKE_WIDTH * 0.5, base_y - SPIKE_HEIGHT)
		left.color = SPIKE_COLOR
		left.z_index = 2
		add_child(left)

		# Right side of spike (slightly offset for pointed look)
		var right := ColorRect.new()
		right.size = Vector2(SPIKE_WIDTH * 0.5, SPIKE_HEIGHT)
		right.position = Vector2(cx, base_y - SPIKE_HEIGHT)
		right.color = SPIKE_COLOR.darkened(0.15)
		right.z_index = 2
		add_child(right)

		# Tip highlight — small rect at top center
		var tip := ColorRect.new()
		tip.size = Vector2(2, 3)
		tip.position = Vector2(cx - 1, base_y - SPIKE_HEIGHT)
		tip.color = Color(0.75, 0.15, 0.15)
		tip.z_index = 3
		add_child(tip)

# === SIGNAL CALLBACKS ===
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(global_position)
