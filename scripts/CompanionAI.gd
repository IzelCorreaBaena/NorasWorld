extends Node2D

# Compañero inteligente que sigue al jugador
@export_group("AI Settings")
@export var follow_distance := 60.0
@export var stop_distance := 40.0
@export var move_speed := 250.0

enum Command { FOLLOW, STAY }

var current_command := Command.FOLLOW
var player_ref : CharacterBody2D
var nav_agent : NavigationAgent2D

func _ready() -> void:
	# Configurar NavigationAgent2D dinámicamente
	nav_agent = NavigationAgent2D.new()
	add_child(nav_agent)
	
	# Buscar al jugador en el grupo "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _physics_process(delta: float) -> void:
	if not player_ref: return
	
	match current_command:
		Command.FOLLOW:
			_follow_player(delta)
		Command.STAY:
			_stay_put(delta)

func _follow_player(delta: float) -> void:
	var dist = global_position.distance_to(player_ref.global_position)
	
	if dist > follow_distance:
		nav_agent.target_position = player_ref.global_position
		
		if not nav_agent.is_navigation_finished():
			var next_path_pos = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_path_pos)
			velocity = direction * move_speed
			move_and_slide()
	else:
		velocity = move_toward(velocity, Vector2.ZERO, move_speed * delta)
		move_and_slide()

func _stay_put(delta: float) -> void:
	velocity = move_toward(velocity, Vector2.ZERO, move_speed * delta)
	move_and_slide()

# Comandos externos
func set_command(new_command: Command) -> void:
	current_command = new_command
	if new_command == Command.STAY:
		# Podrías guardar una posición específica aquí
		pass
