extends RigidBody2D

# Objeto interactivo que el jugador puede recoger y lanzar
@export_group("Configuración")
@export var object_type := "weapon" # "weapon", "prop", etc.
@export var weight := 1.0

var is_held := false
var holder := null

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	add_to_group("heavy_objects")

func pick_up(parent_node: Node2D) -> void:
	if is_held: return
	
	is_held = true
	holder = parent_node
	
	# Desactivamos física para que no interfiera mientras se sostiene
	freeze = true
	
	# Lo posicionamos en el socket del jugador
	if holder.has_node("HoldSocket"):
		global_position = holder.get_node("HoldSocket").global_position
	else:
		global_position = holder.global_position

func drop() -> void:
	if not is_held: return
	
	is_held = false
	freeze = false
	holder = null

func throw_object(direction: Vector2, force: float) -> void:
	if not is_held: return
	
	drop()
	apply_central_impulse(direction * force)
