extends Area2D

@export var pin_id   : String = "pin_world1_01"
@export var pin_color: Color  = Color(1.0, 0.8, 0.1, 1.0)  # dorado por defecto

var collected := false
@onready var sprite = $Sprite2D

func _ready() -> void:
	add_to_group("collectible")
	body_entered.connect(_on_body_entered)

	# Si ya fue recogido en otra sesion, no mostrar
	if GameManager.has_pin(pin_id):
		queue_free()
		return

	_draw_pin()
	_start_float()

func _draw_pin() -> void:
	var img := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	# Circulo con borde
	for y in 20:
		for x in 20:
			var dx := x - 10.0
			var dy := y - 10.0
			var dist := sqrt(dx*dx + dy*dy)
			if dist < 9:
				img.set_pixel(x, y, pin_color)
			elif dist < 10:
				img.set_pixel(x, y, Color(1,1,1,0.8))
	sprite.texture = ImageTexture.create_from_image(img)

func _start_float() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 6, 0.9).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y,     0.9).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	GameManager.collect_pin(pin_id)
	_play_collect_fx()

func _play_collect_fx() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
