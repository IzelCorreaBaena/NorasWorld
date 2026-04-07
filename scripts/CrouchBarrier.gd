extends StaticBody2D
## CrouchBarrier - Low ceiling obstacle that forces the player to crouch.
## Usage: Place in level as a StaticBody2D. Standing player (~30px) hits it,
## crouching player (~15px) passes underneath.
## Recommended: position bottom edge at y~247 with ground at y=267, leaving 20px gap.

# === CONSTANTS ===
const DEFAULT_COLOR := Color(0.35, 0.24, 0.18, 1.0)  # dark brown / stone
const STRIPE_COLOR  := Color(0.28, 0.18, 0.12, 1.0)  # darker stripe
const STRIPE_WIDTH  := 6.0
const STRIPE_GAP    := 10.0

# === EXPORTS ===
@export var barrier_size := Vector2(100.0, 18.0):
	set(value):
		barrier_size = value
		_update_collision()
		queue_redraw()

@export var barrier_color := DEFAULT_COLOR:
	set(value):
		barrier_color = value
		queue_redraw()

# === ONREADY ===
@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if col_shape == null:
		push_error("CrouchBarrier: CollisionShape2D child not found")
		return
	_update_collision()
	queue_redraw()

func _update_collision() -> void:
	if col_shape == null:
		return
	var rect := col_shape.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		col_shape.shape = rect
	rect.size = barrier_size

func _draw() -> void:
	# Draw solid background
	var half := barrier_size * 0.5
	var rect := Rect2(-half, barrier_size)
	draw_rect(rect, barrier_color)

	# Draw diagonal stripes for visual texture
	var left  := -half.x
	var right :=  half.x
	var top   := -half.y
	var bottom := half.y
	var stripe_step := STRIPE_WIDTH + STRIPE_GAP
	var total_span  := barrier_size.x + barrier_size.y

	var offset := 0.0
	while offset < total_span:
		var x0 := left + offset
		var y0 := top
		var x1 := x0 - barrier_size.y
		var y1 := bottom
		# Clamp to rect bounds
		if x0 > right:
			y0 += x0 - right
			x0 = right
		if x1 < left:
			y1 -= left - x1
			x1 = left
		if y0 < bottom and y1 > top:
			draw_line(Vector2(x0, y0), Vector2(x1, y1), STRIPE_COLOR, 2.0)
		offset += stripe_step
