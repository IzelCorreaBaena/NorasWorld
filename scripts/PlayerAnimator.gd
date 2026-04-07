extends AnimatedSprite2D

# Todas las filas tienen 8 columnas de 224px x 597px
const FRAME_W := 224
const FRAME_H := 597
const SHEET_W := 1792

func _ready() -> void:
	var tex := load("res://assets/nora_sheet.png") as Texture2D
	if not tex:
		push_error("No se encuentra res://assets/nora_sheet.png")
		return

	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	# ── IDLE (fila 3, frames 0-3) ──
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 5.0)
	for i in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas  = tex
		atlas.region = Rect2(i * FRAME_W, FRAME_H * 2, FRAME_W, FRAME_H)
		frames.add_frame("idle", atlas)

	# ── WALK (fila 2, 8 frames) ──
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 10.0)
	for i in 8:
		var atlas := AtlasTexture.new()
		atlas.atlas  = tex
		atlas.region = Rect2(i * FRAME_W, FRAME_H * 1, FRAME_W, FRAME_H)
		frames.add_frame("walk", atlas)

	# ── JUMP (fila 1, frames 0-1) ──
	frames.add_animation("jump")
	frames.set_animation_loop("jump", false)
	frames.set_animation_speed("jump", 4.0)
	for i in 2:
		var atlas := AtlasTexture.new()
		atlas.atlas  = tex
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
		frames.add_frame("jump", atlas)

	# ── FALL (fila 1, frames 2-3) ──
	frames.add_animation("fall")
	frames.set_animation_loop("fall", true)
	frames.set_animation_speed("fall", 4.0)
	for i in range(2, 4):
		var atlas := AtlasTexture.new()
		atlas.atlas  = tex
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
		frames.add_frame("fall", atlas)

	# ── INTERACT (fila 4, frames 0-3) ──
	frames.add_animation("interact")
	frames.set_animation_loop("interact", false)
	frames.set_animation_speed("interact", 5.0)
	for i in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas  = tex
		atlas.region = Rect2(i * FRAME_W, FRAME_H * 3, FRAME_W, FRAME_H)
		frames.add_frame("interact", atlas)

	sprite_frames = frames

	# 224px de ancho -> queremos ~50px en pantalla -> 50/224 = 0.22
	scale = Vector2(0.22, 0.22)
	# Centrar verticalmente (pies al suelo)
	offset = Vector2(-FRAME_W * 0.5, -FRAME_H * 0.5)

	play("idle")
