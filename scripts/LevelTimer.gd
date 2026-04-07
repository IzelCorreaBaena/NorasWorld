extends Node
class_name LevelTimer
# Componente que se añade a cada nivel para medir tiempo y emitir medallas.
# Level.gd lo instancia en _ready() si level_key != "".

signal medal_earned(tier: String)   # "gold" | "silver" | "bronze" | "none"

var time_par  : float = 120.0
var elapsed   : float = 0.0
var running   := false
var level_key : String = ""

func start(key: String, par: float) -> void:
	level_key = key
	time_par  = par
	elapsed   = 0.0
	running   = true

func stop() -> String:
	running = false
	var tier := _medal_tier()
	if tier != "none":
		GameManager.set_best_time(level_key, elapsed)
		emit_signal("medal_earned", tier)
	elif GameManager.get_best_time(level_key) <= 0:
		GameManager.set_best_time(level_key, elapsed)
	return tier

func _process(delta: float) -> void:
	if running:
		elapsed += delta

func _medal_tier() -> String:
	var best := GameManager.get_best_time(level_key)
	var t    := elapsed if (best <= 0 or elapsed < best) else best
	if   t <= time_par * 0.8: return "gold"
	elif t <= time_par:        return "silver"
	elif t <= time_par * 1.3:  return "bronze"
	return "none"
