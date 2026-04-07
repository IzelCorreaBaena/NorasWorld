extends Node
# Autoload: NGPlusManager
# Modifica enemigos y jefes en tiempo real al iniciar un nivel en NG+.

var active  := false
var run_num := 0   # 1 = primer NG+, 2 = segundo, etc.

func enemy_speed_mult() -> float:
	return 1.0 + run_num * 0.5     # +50% por run

func boss_health_mult() -> int:
	return 1 + run_num             # +1 HP por run

func apply_to_scene(root: Node) -> void:
	if not active:
		return
	# Modificar enemigos
	for e in root.get_tree().get_nodes_in_group("enemy"):
		if "speed" in e:
			e.speed *= enemy_speed_mult()
	# Modificar jefes
	for b in root.get_tree().get_nodes_in_group("boss"):
		if "max_health" in b:
			b.max_health = max(b.max_health * boss_health_mult(), b.max_health + 1)
			b.health     = b.max_health

func start_ng_plus() -> void:
	active  = true
	run_num += 1
	GameManager.ng_plus_active = true
	GameManager.ng_plus_run    = run_num

func reset() -> void:
	active  = false
	run_num = 0
