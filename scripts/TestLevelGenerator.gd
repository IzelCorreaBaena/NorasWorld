extends Node2D

# Script para generar un prototipo de nivel rápidamente
# Añade este script a un Node2D vacío en una nueva escena.

@export_group("Scenes")
@export var player_scene : PackedScene = preload("res://scenes/Player.tscn")
@export var platform_scene : PackedScene = preload("res://scenes/WeightedPlatform.tscn")
@export var trap_scene : PackedScene = preload("res://scenes/RhythmicTrap.tscn")
@export var enemy_scene : PackedScene = preload("res://scenes/Enemy.tscn")
@export var item_scene : PackedScene = preload("res://scenes/Item.tscn")
@export var pressure_plate_scene : PackedScene = preload("res://scenes/PressurePlate.tscn")
@export var remote_door_scene : PackedScene = preload("res://scenes/RemoteDoor.tscn")
@export var companion_scene : PackedScene = preload("res://scenes/Companion.tscn")
@export var npc_scene : PackedScene = preload("res://scenes/NPC.tscn")
@export var dialogue_ui_scene : PackedScene = preload("res://scenes/DialogueUI.tscn")

func _ready() -> void:
	_build_playground()

func _build_playground() -> void:
	# 1. Crear UI de Diálogo
	var ui = dialogue_ui_scene.instantiate()
	add_child(ui)

	# 2. Crear Suelo
	var floor = StaticBody2D.new()
	floor.position = Vector2(1000, 500)
	add_child(floor)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(3000, 40)
	col.shape = shape
	floor.add_child(col)
	
	var floor_vis = ColorRect.new()
	floor_vis.size = shape.size
	floor_vis.position = -shape.size / 2
	floor_vis.color = Color(0.2, 0.2, 0.2)
	floor.add_child(floor_vis)
	
	# 3. Spawn Player
	var player = player_scene.instantiate()
	player.position = Vector2(100, 400)
	add_child(player)
	
	# 4. Crear plataformas de prueba (Peso)
	for i in range(3):
		var plat = platform_scene.instantiate()
		plat.position = Vector2(400 + (i * 400), 400)
		add_child(plat)
		
	# 5. Crear trampas (Rítmicas)
	for i in range(2):
		var trap = trap_scene.instantiate()
		trap.position = Vector2(800 + (i * 600), 350)
		add_child(trap)
		
	# 6. Crear enemigos
	for i in range(2):
		var enemy = enemy_scene.instantiate()
		enemy.position = Vector2(1200 + (i * 500), 450)
		add_child(enemy)
		
	# 7. Crear objetos interactivos (Lanzables)
	for i in range(2):
		var item = item_scene.instantiate()
		item.position = Vector2(600 + (i * 300), 350)
		add_child(item)

	# 8. CREAR SALA DE PUZZLE (Pressure Plate -> Door)
	_build_puzzle_room()

	# 9. SPAWN COMPAÑERO
	var companion = companion_scene.instantiate()
	companion.position = player.position + Vector2(-50, -50)
	add_child(companion)

	# 10. SPAWN NPC
	var npc = npc_scene.instantiate()
	npc.position = Vector2(1500, 450)
	add_child(npc)

