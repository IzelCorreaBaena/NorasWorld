extends Node2D

const DIALOG_SCENE  := preload("res://scenes/DialogSystem.tscn")
const YELI_SCENE    := preload("res://scenes/Yeli.tscn")

@export var next_level      : String = ""
@export var level_id        : int    = 1
@export var level_key       : String = ""   # e.g. "W1_Boss"
@export var world_name      : String = "Mundo 1"
@export var pins_in_level   : int    = 5
@export var checkpoint_xs   : Array[float] = []

@onready var player     = $Player
@onready var level_end  = $LevelEnd
@onready var hud        = $HUD

var _checkpoint_pos  : Vector2
var _yeli            : Node2D
var _level_finished  := false
var _no_damage       := true
var _health_before   : int
var _timer_node      : Node

func _ready() -> void:
	var scene_path := get_tree().current_scene.scene_file_path
	if scene_path == "":
		scene_path = "res://scenes/World%d.tscn" % level_id
	GameManager.current_level = scene_path

	# Restaurar checkpoint
	if GameManager.checkpoint_pos != Vector2.ZERO:
		player.global_position = GameManager.checkpoint_pos
		_checkpoint_pos = GameManager.checkpoint_pos
	else:
		_checkpoint_pos = player.global_position

	_health_before = GameManager.nora["health"]
	GameManager.health_changed.connect(func(hp):
		if hp < _health_before: _no_damage = false
	)

	player.player_died.connect(_on_player_died)
	player.collectible_found.connect(_on_collectible_found)
	hud.set_world_name(world_name)

	add_child(DIALOG_SCENE.instantiate())
	_yeli = YELI_SCENE.instantiate()
	add_child(_yeli)

	_setup_checkpoints()

	# Timer para niveles con level_key
	if level_key != "":
		_timer_node = LevelTimer.new()
		add_child(_timer_node)
		_timer_node.start(level_key, 180.0)
		_timer_node.medal_earned.connect(func(tier):
			if hud.has_method("show_medal"): hud.show_medal(tier)
		)

	await get_tree().process_frame
	NGPlusManager.apply_to_scene(self)

func _process(_delta: float) -> void:
	if player.global_position.distance_to(level_end.global_position) < 80:
		_finish_level()
	if player.global_position.y > 420:
		player.die()
	_check_checkpoints()

# ── CHECKPOINTS ──────────────────────────────
func _setup_checkpoints() -> void:
	pass

func _check_checkpoints() -> void:
	if checkpoint_xs.is_empty(): return
	for x in checkpoint_xs:
		if player.global_position.x > x and _checkpoint_pos.x < x:
			_checkpoint_pos = Vector2(x, player.global_position.y)
			GameManager.set_checkpoint(GameManager.current_level, _checkpoint_pos)
			_show_checkpoint_fx()

func _show_checkpoint_fx() -> void:
	if _yeli: _yeli.show_secret_nearby()

func _respawn_at_checkpoint() -> void:
	player.global_position = _checkpoint_pos

# ── FIN DE NIVEL ─────────────────────────────
func _finish_level() -> void:
	if _level_finished: return
	_level_finished = true
	GameManager.clear_checkpoint()
	if _timer_node: _timer_node.stop()
	if _no_damage and level_key != "":
		GameManager.set_no_damage(level_key)
	if level_key != "":
		GameManager.complete_level(level_key)
	GameManager.complete_world(level_id)
	var next := next_level
	if next == "":
		next = "res://scenes/WorldMap.tscn"
	SceneTransition.go_to(next)

# ── EVENTOS ──────────────────────────────────
func _on_player_died() -> void:
	pass

func _on_collectible_found(id: String) -> void:
	GameManager.collect_pin(id)

