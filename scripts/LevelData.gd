class_name LevelData
extends Resource

# ── METADATOS DEL NIVEL ──────────────────────
@export var level_key    : String = "W1_L1"   # identificador canónico
@export var world_id     : int    = 1
@export var level_num    : int    = 1
@export var level_name   : String = "La Orilla"
@export var next_scene   : String = ""        # ruta a la siguiente escena
@export var time_par     : float  = 120.0     # segundos para medalla de oro

# ── TEMA VISUAL ───────────────────────────────
# "beach" | "city" | "tribe" | "studio" | "secret"
@export var bg_theme     : String = "beach"

# ── PINES ────────────────────────────────────
@export var pin_ids      : PackedStringArray = []
@export var pin_positions: Array[Vector2]    = []
@export var pin_colors   : Array[Color]      = []

# ── ENEMIGOS ─────────────────────────────────
# Tipo: "patrol" | "flying" | "jumper"
@export var enemy_types     : PackedStringArray = []
@export var enemy_positions : Array[Vector2]    = []
@export var enemy_speeds    : Array[float]      = []

# ── ZONAS ESPECIALES ─────────────────────────
@export var water_rects : Array[Rect2] = []
@export var light_rects : Array[Rect2] = []

# ── MECÁNICAS BLOQUEADAS ──────────────────────
@export var requires_outfit : String = ""  # "" = cualquier outfit, "surfera" etc.

# ── CHECKPOINTS ──────────────────────────────
@export var checkpoint_xs : Array[float] = []

# ── FIN DE NIVEL ─────────────────────────────
@export var level_end_x : float = 2000.0
@export var level_length: float = 2200.0

# ── PLATAFORMAS PROCEDURALES ─────────────────
@export var platform_rects : Array[Rect2] = []

# ── OBSTÁCULOS DE PARKOUR ─────────────────────
# Rect2(x, y, width, height) — la barrera bloquea al jugador de pie, no al agachado
@export var crouch_barrier_rects : Array[Rect2] = []
