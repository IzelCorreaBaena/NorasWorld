extends CanvasLayer

# Interfaz de usuario para mostrar diálogos
@onready var box := $DialogueBox
@onready var name_label := $DialogueBox/NameLabel
@onready var text_label := $DialogueBox/TextLabel

signal dialogue_finished

func _ready() -> void:
	add_to_group("dialogue_ui")
	hide_dialogue()

func show_dialogue(name: String, text: String) -> void:
	name_label.text = name
	text_label.text = text
	show()

func hide_dialogue() -> void:
	hide()
	dialogue_finished.emit()

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_accept"):
		# El NPC ya maneja la progresión de líneas, aquí solo cerramos
		# si el NPC no está gestionando la secuencia.
		# Para simplicidad, lo manejamos desde el NPC.
		pass
