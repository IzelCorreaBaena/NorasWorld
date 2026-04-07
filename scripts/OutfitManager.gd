extends Node

# ── DATOS DE OUTFITS ─────────────────────────
const OUTFITS := {
	"default": {
		"name"       : "Exploradora",
		"description": "El outfit base. Lista para cualquier aventura.",
		"color"      : Color(0.6, 0.8, 1.0),
		"ability"    : "Ninguna habilidad pasiva — outfit base",
	},
	"surfera": {
		"name"       : "Surfera",
		"description": "Caída más lenta sobre el agua.",
		"color"      : Color(0.1, 0.75, 0.9),
		"ability"    : "Caída lenta en agua y plataformas acuáticas",
	},
	"fashion_week": {
		"name"       : "Fashion Week",
		"description": "El dash deja rastro de estrellas y rompe bloques decorativos.",
		"color"      : Color(1.0, 0.3, 0.6),
		"ability"    : "Dash con rastro de estrellas — rompe bloques decorativos",
	},
	"tribal": {
		"name"       : "Tribal",
		"description": "Wall jump con mucho estilo.",
		"color"      : Color(1.0, 0.55, 0.2),
		"ability"    : "Wall Jump habilitado",
	},
	"estilista_pro": {
		"name"       : "Estilista Pro",
		"description": "Doble dash — la máxima movilidad.",
		"color"      : Color(0.65, 0.3, 0.9),
		"ability"    : "Doble dash disponible",
	},
}

# ── QUERY ────────────────────────────────────
static func get_outfit_name(outfit_id: String) -> String:
	return OUTFITS.get(outfit_id, {}).get("name", outfit_id)

static func get_color(outfit_id: String) -> Color:
	return OUTFITS.get(outfit_id, {}).get("color", Color.WHITE)

static func get_description(outfit_id: String) -> String:
	return OUTFITS.get(outfit_id, {}).get("description", "")

static func get_ability(outfit_id: String) -> String:
	return OUTFITS.get(outfit_id, {}).get("ability", "")

# ── PASSIVE ABILITY CHECK ────────────────────
# Llama esto desde Player o Level para saber si el outfit activo otorga algo
static func has_water_slow_fall() -> bool:
	return GameManager.current_outfit == "surfera"

static func has_star_dash() -> bool:
	return GameManager.current_outfit == "fashion_week"

static func has_double_dash() -> bool:
	return GameManager.current_outfit == "estilista_pro"
