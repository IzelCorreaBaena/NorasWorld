extends Area2D

# NPC amistoso con sistema de interacción
@export_group("Diálogo")
@export var npc_name := "Vecino"
@export var dialogue_lines : Array[String] = ["Hola!", "Bienvenido al mundo."]

var _current_line_index := 0
var _is_player_nearby := false
var _dialogue_ui : Node # Referencia a la UI

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Buscar la UI de diálogo en el árbol (asumiendo que es un Autoload o está en la escena principal)
	_dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")

func _input(event: InputEvent) -> void:
	if _is_player_nearby and event.is_action_pressed("ui_accept"):
		_start_dialogue()

func _start_dialogue() -> void:
	if _dialogue_ui:
		_current_line_index = 0
		_dialogue_ui.show_dialogue(npc_name, dialogue_lines[_current_line_index])
		_dialogue_ui.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	else:
		print("[NPC] ", npc_name, ": ", dialogue_lines[0])

func _on_dialogue_finished() -> void:
	_current_line_index += 1
	if _current_line_index < dialogue_lines.size():
		_dialogue_ui.show_dialogue(npc_name, dialogue_lines[_current_line_index])
	else:
		_dialogue_ui.hide_dialogue()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_is_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_is_player_nearby = false
		if _dialogue_ui:
			_dialogue_ui.hide_dialogue()
