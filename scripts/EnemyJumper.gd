extends CharacterBody2D
# ── ENEMIGO SALTARIN ─────────────────────────
# Salta periódicamente hacia el jugador.
# Daña al jugador al contacto mediante un Area2D interno.

# === CONSTANTS ===
const GRAVITY := 900.0

# === EXPORTS ===
@export var speed        : float = 50.0
@export var jump_force   : float = -350.0
@export var jump_interval: float = 2.5

# === PRIVATE VARIABLES ===
var _jump_timer : float = 1.5
var _player     : Node2D = null

# === BUILT-IN CALLBACKS ===
func _ready() -> void:
	add_to_group("enemy")
	_build_sprite()
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
		_jump_timer -= delta
		if _jump_timer <= 0.0:
			_jump_timer = jump_interval
			if _player and is_instance_valid(_player):
				var dir = sign(_player.global_position.x - global_position.x)
				velocity.x = dir * speed * 2.0
				velocity.y = jump_force

	move_and_slide()

# === PRIVATE METHODS ===
func _build_sprite() -> void:
	var sprite := Sprite2D.new()
	var img    := Image.create(22, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.133, 0.4, 1.0))  # magenta #CC2266
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)

	var col   := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 11.0
	shape.height = 28.0
	col.shape    = shape
	add_child(col)

	# Area2D para detectar contacto con el jugador
	var area  := Area2D.new()
	area.collision_layer = 4
	area.collision_mask  = 1
	var acol  := CollisionShape2D.new()
	var acirc := CircleShape2D.new()
	acirc.radius = 16.0
	acol.shape   = acirc
	area.add_child(acol)
	area.body_entered.connect(func(b: Node2D) -> void:
		if b.is_in_group("player"):
			b.take_damage(global_position)
	)
	add_child(area)
