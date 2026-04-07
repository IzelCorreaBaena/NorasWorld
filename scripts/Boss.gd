class_name Boss
extends Node2D

# ── BASE PARA TODOS LOS JEFES ─────────────────
# Cada jefe hereda de este script y sobreescribe los métodos virtuales.

@export var world_id   : int   = 1
@export var max_health : int   = 3

var health         : int  = 3
var phase          : int  = 1
var is_defeated    := false
var player         : Node2D = null

signal boss_defeated(world_id: int)
signal phase_changed(new_phase: int)

func _ready() -> void:
	health = max_health
	add_to_group("boss")
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	_on_boss_ready()
	# Avisar a Yeli
	var yeli_node := get_tree().get_first_node_in_group("yeli")
	if yeli_node:
		yeli_node.show_boss_nearby()
	_lock_camera()

func _lock_camera() -> void:
	if player == null:
		return
	var cam := player.get_node_or_null("Camera")
	if cam is Camera2D:
		# Fijar la cámara a la arena del jefe — las subclases pueden ajustar los límites
		cam.position_smoothing_enabled = false

func _unlock_camera() -> void:
	if player == null:
		return
	var cam := player.get_node_or_null("Camera")
	if cam is Camera2D:
		cam.position_smoothing_enabled = true

# ── DAÑO ─────────────────────────────────────
func take_hit() -> void:
	if is_defeated:
		return
	health -= 1
	_on_hit()
	_flash_hit()
	if health <= 0:
		_defeat()
	else:
		_check_phase()

func _check_phase() -> void:
	var new_phase := 1
	if max_health > 0:
		var pct := float(health) / float(max_health)
		if   pct <= 0.33: new_phase = 3
		elif pct <= 0.66: new_phase = 2
	if new_phase != phase:
		phase = new_phase
		emit_signal("phase_changed", phase)
		_on_phase_changed(phase)

func _flash_hit() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.5, 0.5, 0.5), 0.06)
	tw.tween_property(self, "modulate", Color.WHITE,           0.12)

func _defeat() -> void:
	is_defeated = true
	_unlock_camera()
	_on_defeated()
	emit_signal("boss_defeated", world_id)
	# Dar recompensa
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)

# ── MÉTODOS VIRTUALES ─────────────────────────
# Sobreescribir en cada jefe:
func _on_boss_ready()          -> void: pass
func _on_hit()                 -> void: pass
func _on_phase_changed(_p:int) -> void: pass
func _on_defeated()            -> void: pass
