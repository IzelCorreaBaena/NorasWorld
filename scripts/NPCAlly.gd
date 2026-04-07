extends StaticBody2D
## Friendly NPC — stands in place, shows dialog bubble when player is near.
## Does NOT block the player (collision layer = 0).

# === CONSTANTS ===
const TRIGGER_RADIUS   := 60.0
const BODY_WIDTH       := 12.0
const BODY_HEIGHT      := 20.0
const HEAD_SIZE        := 10.0
const BUBBLE_OFFSET_Y  := -38.0
const BUBBLE_PADDING   := Vector2(6, 3)

# === EXPORTS ===
@export var npc_name   : String = "Surfista"
@export var dialog_text: String = "Animo Nora! Puedes lograrlo."
@export var npc_color  : Color  = Color(0.4, 0.8, 1.0)

# === PRIVATE VARIABLES ===
var _dialog_label : Label
var _trigger_area : Area2D
var _player_near  := false

# === BUILT-IN CALLBACKS ===
func _ready() -> void:
	add_to_group("npc_ally")
	# Disable collision so the NPC does not block the player
	collision_layer = 0
	collision_mask  = 0
	_build_body_visual()
	_build_trigger()
	_build_dialog_bubble()

# === PRIVATE METHODS ===
func _build_body_visual() -> void:
	# Simple colored body — rectangle + head circle approximation
	# Body
	var body_rect := ColorRect.new()
	body_rect.size = Vector2(BODY_WIDTH, BODY_HEIGHT)
	body_rect.position = Vector2(-BODY_WIDTH * 0.5, -BODY_HEIGHT)
	body_rect.color = npc_color
	body_rect.z_index = 1
	add_child(body_rect)

	# Head (square approximation of circle, slightly lighter)
	var head := ColorRect.new()
	head.size = Vector2(HEAD_SIZE, HEAD_SIZE)
	head.position = Vector2(-HEAD_SIZE * 0.5, -BODY_HEIGHT - HEAD_SIZE + 2)
	head.color = npc_color.lightened(0.25)
	head.z_index = 2
	add_child(head)

	# Eyes — two small dark dots
	for offset_x in [-2.0, 2.0]:
		var eye := ColorRect.new()
		eye.size = Vector2(2, 2)
		eye.position = Vector2(
			-HEAD_SIZE * 0.5 + HEAD_SIZE * 0.5 + offset_x - 1,
			-BODY_HEIGHT - HEAD_SIZE + 2 + 3
		)
		eye.color = Color(0.1, 0.1, 0.1)
		eye.z_index = 3
		add_child(eye)

func _build_trigger() -> void:
	_trigger_area = Area2D.new()
	_trigger_area.collision_layer = 0
	_trigger_area.collision_mask  = 1  # Detect player on layer 1
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = TRIGGER_RADIUS
	col.shape = shape
	_trigger_area.add_child(col)
	add_child(_trigger_area)
	_trigger_area.body_entered.connect(_on_player_entered)
	_trigger_area.body_exited.connect(_on_player_exited)

func _build_dialog_bubble() -> void:
	_dialog_label = Label.new()
	_dialog_label.text = dialog_text
	_dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialog_label.add_theme_font_size_override("font_size", 7)
	_dialog_label.add_theme_color_override("font_color", Color.WHITE)

	# Background style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	style.corner_radius_top_left     = 3
	style.corner_radius_top_right    = 3
	style.corner_radius_bottom_left  = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left   = BUBBLE_PADDING.x
	style.content_margin_right  = BUBBLE_PADDING.x
	style.content_margin_top    = BUBBLE_PADDING.y
	style.content_margin_bottom = BUBBLE_PADDING.y
	_dialog_label.add_theme_stylebox_override("normal", style)

	_dialog_label.position = Vector2(-40, BUBBLE_OFFSET_Y)
	_dialog_label.z_index  = 10
	_dialog_label.visible  = false
	add_child(_dialog_label)

# === SIGNAL CALLBACKS ===
func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_dialog_label.visible = true

func _on_player_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_dialog_label.visible = false
