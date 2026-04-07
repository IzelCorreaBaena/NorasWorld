extends Area2D
## Collectible item — health restore, speed boost, or shield.
## Bobs up/down with a tween, flashes and destroys on pickup.

# === CONSTANTS ===
const BOB_AMPLITUDE := 3.0
const BOB_DURATION  := 1.2
const PICKUP_RADIUS := 10.0
const SHIELD_DURATION := 5.0

const ITEM_LABELS := {
	"health": "+"  ,
	"speed_boost": ">>",
	"shield": "O"  ,
}

const ITEM_COLORS := {
	"health":      Color(0.2, 0.85, 0.3),
	"speed_boost": Color(1.0, 0.85, 0.1),
	"shield":      Color(0.3, 0.6, 1.0),
}

# === EXPORTS ===
@export var item_type: String = "health"

# === SIGNALS ===
signal item_collected(type: String)

# === PRIVATE VARIABLES ===
var _origin_y   := 0.0
var _bob_tween  : Tween
var _visual     : Label

# === BUILT-IN CALLBACKS ===
func _ready() -> void:
	add_to_group("item")
	_origin_y = position.y
	_build_collision()
	_build_visual()
	_start_bob()
	body_entered.connect(_on_body_entered)

# === PRIVATE METHODS ===
func _build_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = PICKUP_RADIUS
	col.shape = shape
	add_child(col)

func _build_visual() -> void:
	var color: Color = ITEM_COLORS.get(item_type, Color.WHITE)
	var text: String = ITEM_LABELS.get(item_type, "?")

	# Background panel via a ColorRect with rounded feel
	var bg := ColorRect.new()
	bg.size = Vector2(16, 16)
	bg.position = Vector2(-8, -8)
	bg.color = color.darkened(0.3)
	bg.z_index = 2
	add_child(bg)

	# Inner highlight
	var inner := ColorRect.new()
	inner.size = Vector2(12, 12)
	inner.position = Vector2(-6, -6)
	inner.color = color
	inner.z_index = 3
	add_child(inner)

	# Text label
	_visual = Label.new()
	_visual.text = text
	_visual.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_visual.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_visual.size = Vector2(16, 16)
	_visual.position = Vector2(-8, -10)
	_visual.add_theme_font_size_override("font_size", 10)
	_visual.add_theme_color_override("font_color", Color.WHITE)
	_visual.z_index = 4
	add_child(_visual)

func _start_bob() -> void:
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(self, "position:y", _origin_y - BOB_AMPLITUDE, BOB_DURATION * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(self, "position:y", _origin_y + BOB_AMPLITUDE, BOB_DURATION * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _apply_effect(body: Node2D) -> void:
	match item_type:
		"health":
			GameManager.heal(1)
		"speed_boost":
			item_collected.emit("speed_boost")
		"shield":
			# Grant temporary invincibility via the player
			if "is_invincible" in body and "invincible_timer" in body:
				body.is_invincible = true
				body.invincible_timer = SHIELD_DURATION
			item_collected.emit("shield")

func _pickup_effect() -> void:
	# Flash and destroy
	if _bob_tween:
		_bob_tween.kill()
	var flash := create_tween()
	flash.tween_property(self, "modulate:a", 0.0, 0.2)
	flash.tween_callback(queue_free)

# === SIGNAL CALLBACKS ===
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_apply_effect(body)
	_pickup_effect()
