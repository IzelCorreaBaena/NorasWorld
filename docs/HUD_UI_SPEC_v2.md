# NORA'S WORLD -- Especificaciones de UI/HUD v2

Viewport: 480x270 | Todo procedural (ColorRect + Label + StyleBoxFlat + Panel + Tween)
Archivo destino: `scripts/HUD.gd` (extender el existente)

---

## RESUMEN DEL HUD ACTUAL

```
┌─────────────────────────────────────────────────────────────┐
│ [♥♥♡] [📍 3] [La Orilla]                    [0:42.15]      │
│                                                             │
│                     AREA DE JUEGO                           │
│                        480x270                              │
│                                                             │
│     [══════════ BOSS BAR (solo en boss) ══════════]         │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. NOTIFICACION DE ITEM RECOGIDO

### Contexto
Cuando el jugador recoge un item (health, speed_boost, shield), aparece una notificacion
flotante breve que confirma la accion y el tipo de item.

### Wireframe

```
┌─────────────────────────────────────────────────────────────┐
│ [TopBar...]                                   [Timer]       │
│                                                             │
│                              ┌──────────────────┐           │
│                              │ [icono] +1 Vida  │ ← y=40   │
│                              └──────────────────┘           │
│                                                             │
│                     AREA DE JUEGO                           │
└─────────────────────────────────────────────────────────────┘
```

### Posicion y Tamano
- **Anchor**: PRESET_TOP_RIGHT
- **offset_right**: -8px
- **offset_top**: 34px (justo debajo del timer)
- **offset_left**: -140px
- **offset_bottom**: 54px
- **Tamano resultante**: 132 x 20px

### Colores por tipo de item
| Item         | Icono | Color texto          | Color fondo (StyleBoxFlat)    |
|--------------|-------|----------------------|-------------------------------|
| health       | `+♥`  | `#F24B6A` (rosa)     | `#330A12` alpha 0.85          |
| speed_boost  | `⚡`  | `#FFD966` (amarillo) | `#332B00` alpha 0.85          |
| shield       | `🛡`  | `#66CCFF` (celeste)  | `#002233` alpha 0.85          |

Colores hex exactos:
- health texto: `Color(0.95, 0.29, 0.42)`
- health fondo: `Color(0.20, 0.04, 0.07, 0.85)`
- speed_boost texto: `Color(1.0, 0.85, 0.4)`
- speed_boost fondo: `Color(0.20, 0.17, 0.0, 0.85)`
- shield texto: `Color(0.4, 0.8, 1.0)`
- shield fondo: `Color(0.0, 0.13, 0.20, 0.85)`

### Estilo visual
- Panel con StyleBoxFlat
- corner_radius: 6px en las 4 esquinas
- content_margin: 4px horizontal, 2px vertical
- font_size: 10
- Alineacion horizontal: CENTER

### Animacion (Tween)
1. **Estado inicial**: modulate.a = 0.0, position.y desplazado +12px desde su posicion base
2. **Fase IN** (0.2s): modulate.a -> 1.0, position.y -> base (EASE_OUT, TRANS_BACK)
3. **Hold** (1.2s): sin cambios
4. **Fase OUT** (0.3s): modulate.a -> 0.0, position.y -> base - 8px (sube al desaparecer)
5. **Duracion total**: 1.7s

### Cola de notificaciones
Si el jugador recoge multiples items rapidamente:
- Las notificaciones se apilan verticalmente con 24px de separacion
- Maximo 3 visibles simultaneamente
- Si hay mas de 3, la mas antigua se descarta inmediatamente

### Codigo GDScript

```gdscript
# === Variables nuevas (agregar al inicio de HUD.gd) ===
var _item_notifications: Array[Control] = []
const MAX_ITEM_NOTIFS := 3

const ITEM_CONFIG := {
    "health": {
        "icon": "+♥",
        "text_color": Color(0.95, 0.29, 0.42),
        "bg_color": Color(0.20, 0.04, 0.07, 0.85),
        "label": "Vida"
    },
    "speed_boost": {
        "icon": "⚡",
        "text_color": Color(1.0, 0.85, 0.4),
        "bg_color": Color(0.20, 0.17, 0.0, 0.85),
        "label": "Velocidad"
    },
    "shield": {
        "icon": "🛡",
        "text_color": Color(0.4, 0.8, 1.0),
        "bg_color": Color(0.0, 0.13, 0.20, 0.85),
        "label": "Escudo"
    },
}

# === Funcion publica: llamar desde la logica de items ===
func show_item_pickup(item_type: String) -> void:
    var cfg = ITEM_CONFIG.get(item_type)
    if cfg == null:
        return

    # Limitar cola
    if _item_notifications.size() >= MAX_ITEM_NOTIFS:
        var old = _item_notifications.pop_front()
        if is_instance_valid(old):
            old.queue_free()

    # Crear panel
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    var slot := _item_notifications.size()
    panel.offset_right  = -8.0
    panel.offset_left   = -140.0
    panel.offset_top    = 34.0 + slot * 24.0
    panel.offset_bottom = 54.0 + slot * 24.0

    var style := StyleBoxFlat.new()
    style.bg_color = cfg["bg_color"]
    style.corner_radius_top_left     = 6
    style.corner_radius_top_right    = 6
    style.corner_radius_bottom_left  = 6
    style.corner_radius_bottom_right = 6
    style.content_margin_left   = 4.0
    style.content_margin_right  = 4.0
    style.content_margin_top    = 2.0
    style.content_margin_bottom = 2.0
    panel.add_theme_stylebox_override("panel", style)

    var lbl := Label.new()
    lbl.text = "%s %s" % [cfg["icon"], cfg["label"]]
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.add_theme_font_size_override("font_size", 10)
    lbl.add_theme_color_override("font_color", cfg["text_color"])
    panel.add_child(lbl)

    panel.modulate.a = 0.0
    add_child(panel)
    _item_notifications.append(panel)

    # Animacion
    var base_y := panel.offset_top
    panel.offset_top    += 12.0
    panel.offset_bottom += 12.0

    var tw := create_tween()
    tw.tween_property(panel, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(panel, "offset_top", base_y, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tw.parallel().tween_property(panel, "offset_bottom", base_y + 20.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tw.tween_interval(1.2)
    tw.tween_property(panel, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
    tw.parallel().tween_property(panel, "offset_top", base_y - 8.0, 0.3)
    tw.parallel().tween_property(panel, "offset_bottom", base_y + 12.0, 0.3)
    tw.tween_callback(func():
        _item_notifications.erase(panel)
        panel.queue_free()
    )
```

### Notas de implementacion
- **Prioridad**: MUST HAVE
- Necesita una senal nueva en GameManager o que el item llame directamente a `HUD.show_item_pickup()`
- Alternativa: crear senal `item_picked_up(type: String)` en GameManager y conectar en `_ready()`

---

## 2. INDICADOR DE ESTADO ACTIVO (Buffs)

### Contexto
Cuando speed_boost o shield estan activos, el jugador necesita ver:
(a) que el efecto esta activo y (b) cuanto tiempo le queda.

### Wireframe

```
┌─────────────────────────────────────────────────────────────┐
│ [♥♥♡] [📍 3] [La Orilla]                    [0:42.15]      │
│                                                             │
│                                    ┌───────────────┐        │
│                                    │ ⚡ ████░░ 3.2s│ ← y=34 │
│                                    │ 🛡 █████░ 5.1s│ ← y=48 │
│                                    └───────────────┘        │
│                                                             │
│                     AREA DE JUEGO                           │
└─────────────────────────────────────────────────────────────┘
```

Nota: Los indicadores de estado se posicionan debajo del timer. Si hay item notifications
activas simultaneamente, los estados se desplazan debajo de estas.

### Posicion y Tamano
- **Anchor**: PRESET_TOP_RIGHT
- **offset_right**: -8px
- **offset_top**: 34px (primer buff), +16px por cada buff adicional
- **offset_left**: -120px
- Cada barra: 112 x 14px

### Estructura interna de cada indicador
```
[Icono Label 12px] [Barra fondo 60x8px [Barra fill Nx8px]] [Tiempo Label 10px]
```

Distribucion horizontal dentro del contenedor:
- Icono: 14px de ancho (Label, font_size 10)
- Barra fondo: 60px de ancho, 8px de alto, centrado verticalmente
- Barra fill: ancho = 60 * (tiempo_restante / tiempo_total)
- Texto tiempo: 30px de ancho, alineado derecha

### Colores
| Buff         | Icono | Color barra fill        | Color barra fondo       | Color texto tiempo     |
|--------------|-------|-------------------------|-------------------------|------------------------|
| speed_boost  | `⚡`  | `Color(1.0, 0.85, 0.2)` | `Color(0.15, 0.12, 0.0, 0.7)` | `Color(1.0, 0.9, 0.5)` |
| shield       | `🛡`  | `Color(0.3, 0.7, 1.0)`  | `Color(0.0, 0.1, 0.15, 0.7)` | `Color(0.6, 0.85, 1.0)` |

### Animaciones
- **Aparicion**: modulate.a 0->1 en 0.15s + scale.x 0.5->1.0 en 0.2s (EASE_OUT, TRANS_BACK)
- **Barra vaciandose**: actualizar anchor_right cada frame via _process
- **Ultimo 25%**: barra parpadea (modulate.a oscila entre 0.5 y 1.0, frecuencia 4Hz)
- **Desaparicion**: modulate.a 1->0 en 0.3s + scale.x 1.0->0.5 en 0.3s

### Codigo GDScript

```gdscript
# === Variables nuevas ===
var _active_buffs: Dictionary = {}  # {"speed_boost": {panel, fill, label, duration, remaining}}

# === Construir indicador de buff ===
func _build_buff_indicator(buff_type: String, duration: float) -> void:
    # Remover si ya existe
    if buff_type in _active_buffs:
        var old_data = _active_buffs[buff_type]
        if is_instance_valid(old_data["panel"]):
            old_data["panel"].queue_free()

    var is_speed := buff_type == "speed_boost"
    var icon_text := "⚡" if is_speed else "🛡"
    var fill_color := Color(1.0, 0.85, 0.2) if is_speed else Color(0.3, 0.7, 1.0)
    var bg_color := Color(0.15, 0.12, 0.0, 0.7) if is_speed else Color(0.0, 0.1, 0.15, 0.7)
    var time_color := Color(1.0, 0.9, 0.5) if is_speed else Color(0.6, 0.85, 1.0)

    var slot := _active_buffs.size()

    # Contenedor principal
    var panel := Control.new()
    panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    panel.offset_right  = -8.0
    panel.offset_left   = -120.0
    panel.offset_top    = 34.0 + slot * 16.0
    panel.offset_bottom = 48.0 + slot * 16.0

    # Icono
    var icon_lbl := Label.new()
    icon_lbl.text = icon_text
    icon_lbl.position = Vector2(0, 0)
    icon_lbl.size = Vector2(14, 14)
    icon_lbl.add_theme_font_size_override("font_size", 10)
    panel.add_child(icon_lbl)

    # Barra fondo
    var bar_bg := ColorRect.new()
    bar_bg.position = Vector2(16, 3)
    bar_bg.size = Vector2(60, 8)
    bar_bg.color = bg_color
    panel.add_child(bar_bg)

    # Barra fill
    var bar_fill := ColorRect.new()
    bar_fill.position = Vector2(16, 3)
    bar_fill.size = Vector2(60, 8)
    bar_fill.color = fill_color
    panel.add_child(bar_fill)

    # Texto tiempo
    var time_lbl := Label.new()
    time_lbl.position = Vector2(80, 0)
    time_lbl.size = Vector2(32, 14)
    time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    time_lbl.add_theme_font_size_override("font_size", 8)
    time_lbl.add_theme_color_override("font_color", time_color)
    panel.add_child(time_lbl)

    panel.modulate.a = 0.0
    add_child(panel)

    # Animacion de entrada
    var tw := create_tween()
    tw.tween_property(panel, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)

    _active_buffs[buff_type] = {
        "panel": panel,
        "fill": bar_fill,
        "label": time_lbl,
        "duration": duration,
        "remaining": duration,
    }

# === Actualizar buffs en _process (agregar al _process existente) ===
func _update_buffs(delta: float) -> void:
    var to_remove: Array[String] = []
    for key in _active_buffs:
        var d = _active_buffs[key]
        if not is_instance_valid(d["panel"]):
            to_remove.append(key)
            continue
        d["remaining"] -= delta
        if d["remaining"] <= 0.0:
            to_remove.append(key)
            var tw := create_tween()
            tw.tween_property(d["panel"], "modulate:a", 0.0, 0.3)
            tw.tween_callback(d["panel"].queue_free)
            continue
        # Actualizar barra
        var pct: float = d["remaining"] / d["duration"]
        d["fill"].size.x = 60.0 * pct
        d["label"].text = "%.1fs" % d["remaining"]
        # Parpadeo ultimo 25%
        if pct < 0.25:
            d["fill"].modulate.a = 0.5 + 0.5 * sin(d["remaining"] * 25.0)

    for key in to_remove:
        _active_buffs.erase(key)

# === Funcion publica ===
func activate_buff(buff_type: String, duration: float) -> void:
    _build_buff_indicator(buff_type, duration)
```

Agregar al `_process()` existente:
```gdscript
# Dentro de _process(_delta):
_update_buffs(_delta)
```

### Notas de implementacion
- **Prioridad**: MUST HAVE
- El item de speed_boost/shield debe llamar `HUD.activate_buff("speed_boost", 5.0)` al recogerse
- La logica del efecto real (velocidad aumentada, invulnerabilidad) vive en Player.gd, no en HUD
- Si ambos buffs estan activos, se muestran apilados

---

## 3. BARRA DE PROGRESO DEL NIVEL

### Contexto
Los niveles miden entre 2200 y 3450px de largo. El jugador necesita saber
cuanto ha avanzado sin un minimapa complejo. Una barra horizontal simple es la
solucion optima para este viewport reducido.

### Wireframe

```
┌─────────────────────────────────────────────────────────────┐
│ [♥♥♡] [📍 3] [La Orilla]                    [0:42.15]      │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│                     AREA DE JUEGO                           │
└─────────────────────────────────────────────────────────────┘
```

La barra va inmediatamente debajo de la TopBar, ocupando todo el ancho con margenes.

### Posicion y Tamano
- **Anchor**: PRESET_TOP_WIDE
- **offset_top**: 22px (justo debajo de TopBar que termina en ~20px)
- **offset_bottom**: 25px (3px de alto la barra)
- **offset_left**: 8px
- **offset_right**: -8px
- **Alto total de la barra**: 3px (minimalista, no intrusiva)

### Colores
- Fondo barra: `Color(1.0, 1.0, 1.0, 0.1)` -- blanco muy transparente
- Fill 0%-50%: `Color(1.0, 1.0, 1.0, 0.3)` -- blanco suave
- Fill 50%-80%: `Color(1.0, 0.9, 0.4, 0.4)` -- dorado suave
- Fill 80%-100%: `Color(0.4, 1.0, 0.5, 0.5)` -- verde suave
- Marcadores de checkpoint: `Color(1.0, 1.0, 1.0, 0.5)` -- lineas verticales de 1px ancho, 5px alto

### Calculo del porcentaje
```
porcentaje = clamp(player.global_position.x / level_end_x, 0.0, 1.0)
```

Donde `level_end_x` se obtiene del LevelData.level_end_x del nivel actual.

### Animaciones
- Fill se actualiza via _process, NO con tween (para suavidad constante)
- Aplicar lerp al ancho para evitar saltos: `fill.size.x = lerp(fill.size.x, target_width, 0.1)`
- Al llegar al 100%: flash blanco momentaneo (modulate.a sube a 0.8 por 0.3s, luego baja)
- Marcadores de checkpoint: aparecen como puntitos fijos en la barra

### Codigo GDScript

```gdscript
# === Variables nuevas ===
var _progress_bg   : ColorRect
var _progress_fill : ColorRect
var _progress_target : float = 0.0
var _level_end_x   : float = 2000.0

# === Construir en _ready() ===
func _build_progress_bar() -> void:
    _progress_bg = ColorRect.new()
    _progress_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
    _progress_bg.offset_top    = 22.0
    _progress_bg.offset_bottom = 25.0
    _progress_bg.offset_left   = 8.0
    _progress_bg.offset_right  = -8.0
    _progress_bg.color = Color(1.0, 1.0, 1.0, 0.1)
    add_child(_progress_bg)

    _progress_fill = ColorRect.new()
    _progress_fill.position = Vector2.ZERO
    _progress_fill.size = Vector2(0, 3)
    _progress_fill.color = Color(1.0, 1.0, 1.0, 0.3)
    _progress_bg.add_child(_progress_fill)

func set_level_end(end_x: float, checkpoint_xs: Array = []) -> void:
    _level_end_x = end_x
    # Dibujar marcadores de checkpoint
    var bar_width := 480.0 - 16.0  # offset_left + offset_right
    for cx in checkpoint_xs:
        var pct: float = cx / _level_end_x
        var marker := ColorRect.new()
        marker.size = Vector2(1, 5)
        marker.position = Vector2(bar_width * pct, -1)
        marker.color = Color(1.0, 1.0, 1.0, 0.5)
        _progress_bg.add_child(marker)

# === Actualizar en _process (agregar al _process existente) ===
func _update_progress() -> void:
    if _progress_fill == null:
        return
    var bar_width := _progress_bg.size.x
    if bar_width <= 0:
        bar_width = 464.0  # fallback: 480 - 16
    var target_w := bar_width * _progress_target
    _progress_fill.size.x = lerp(_progress_fill.size.x, target_w, 0.1)
    _progress_fill.size.y = 3.0
    # Color gradual
    if _progress_target < 0.5:
        _progress_fill.color = Color(1.0, 1.0, 1.0, 0.3)
    elif _progress_target < 0.8:
        _progress_fill.color = Color(1.0, 0.9, 0.4, 0.4)
    else:
        _progress_fill.color = Color(0.4, 1.0, 0.5, 0.5)

func set_progress(pct: float) -> void:
    _progress_target = clamp(pct, 0.0, 1.0)
```

### Integracion con ProceduralLevel.gd
En `_spawn_hud()` de ProceduralLevel.gd, agregar despues de `_hud.set_world_name(...)`:
```gdscript
_hud.set_level_end(data.level_end_x, data.checkpoint_xs)
```

En `_process()` de ProceduralLevel.gd, agregar:
```gdscript
if _hud and _player and _hud.has_method("set_progress"):
    var pct := _player.global_position.x / data.level_end_x
    _hud.set_progress(pct)
```

Y en `_process()` de HUD.gd agregar:
```gdscript
_update_progress()
```

### Notas de implementacion
- **Prioridad**: SHOULD HAVE
- 3px de alto es suficiente para ser legible sin bloquear el juego
- El lerp en size.x da una sensacion suave y organica
- No mostrar porcentaje numerico: la barra visual es suficiente a este tamano de viewport

---

## 4. DIALOGO DE NPC

### Contexto
Los NPCs aliados muestran una burbuja de dialogo cuando el jugador se acerca.
Nota: Ya existe DialogSystem.gd como CanvasLayer para popups de pines. Este nuevo
sistema es diferente: es una burbuja que aparece en el mundo del juego, posicionada
relativa al NPC, no como overlay de pantalla completa.

### Wireframe (en espacio mundo, no pantalla)

```
         ┌────────────────────────┐
         │  Hola Nora! Cuidado    │
         │  con los pinchos.      │
         └──────────┬─────────────┘
                    ▼
                 [NPC sprite]
```

### Posicion relativa al NPC
- La burbuja se posiciona como hijo del NPC en el arbol de escena
- **offset_y**: -40px (encima del sprite del NPC, asumiendo sprite de ~32px)
- **offset_x**: centrado horizontalmente respecto al NPC
- Tamano maximo: 140 x 50px (autowrap para texto largo)
- Si el NPC esta cerca del borde superior de la camara, la burbuja aparece debajo (+40px en su lugar)

### Estructura visual
```
PanelContainer (burbuja)
  └─ VBoxContainer
       └─ Label (texto del dialogo)
ColorRect (triangulo/flecha hacia abajo, 8x6px)
```

### Colores y estilo
- **Fondo burbuja (StyleBoxFlat)**:
  - bg_color: `Color(0.0, 0.0, 0.0, 0.8)`
  - corner_radius: 8px en las 4 esquinas
  - content_margin: 8px horizontal, 6px vertical
  - border_width: 1px
  - border_color: `Color(1.0, 1.0, 1.0, 0.15)`
- **Texto**:
  - font_size: 8 (legible a 480x270 sin ocupar mucho espacio)
  - font_color: `Color(1.0, 1.0, 1.0, 0.95)`
  - autowrap_mode: AUTOWRAP_WORD_SMART
- **Flecha triangular** (simular con ColorRect rotado):
  - ColorRect 8x6px color `Color(0.0, 0.0, 0.0, 0.8)`, rotado 45 grados
  - Posicion: centrado horizontal, justo debajo del panel

### Animaciones
- **Aparicion** (jugador entra en rango de 60px del NPC):
  1. modulate.a: 0 -> 1 en 0.2s
  2. scale: Vector2(0.8, 0.8) -> Vector2(1.0, 1.0) en 0.25s, EASE_OUT, TRANS_BACK
- **Desaparicion** (jugador sale del rango de 80px -- 20px de histeresis):
  1. modulate.a: 1 -> 0 en 0.2s
  2. scale: Vector2(1.0, 1.0) -> Vector2(0.8, 0.8) en 0.2s
- **Auto-dismiss**: la burbuja desaparece automaticamente despues de 5 segundos si el
  jugador sigue en rango (para no saturar la pantalla)
- **Cooldown**: el mismo NPC no vuelve a mostrar la burbuja hasta 10 segundos despues

### Trigger
- El NPC debe tener un Area2D con collision de radio 60px
- Cuando `body_entered` detecta al jugador -> mostrar burbuja
- Cuando `body_exited` o distancia > 80px -> ocultar burbuja

### Codigo GDScript (para el NPC, no para HUD.gd)

```gdscript
# === Agregar como funcion del NPC o como componente reutilizable ===
# Este codigo va en el script del NPC (ej: AllyNPC.gd)

var _bubble: PanelContainer
var _bubble_label: Label
var _bubble_arrow: ColorRect
var _bubble_visible := false
var _bubble_cooldown := 0.0
var _bubble_timer := 0.0
var _dialog_text := "Hola Nora!"

func _build_dialog_bubble() -> void:
    _bubble = PanelContainer.new()
    _bubble.position = Vector2(-70, -40)
    _bubble.size = Vector2(140, 0)  # auto-height

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.0, 0.0, 0.0, 0.8)
    style.corner_radius_top_left     = 8
    style.corner_radius_top_right    = 8
    style.corner_radius_bottom_left  = 8
    style.corner_radius_bottom_right = 8
    style.content_margin_left   = 8.0
    style.content_margin_right  = 8.0
    style.content_margin_top    = 6.0
    style.content_margin_bottom = 6.0
    style.border_width_left   = 1
    style.border_width_right  = 1
    style.border_width_top    = 1
    style.border_width_bottom = 1
    style.border_color = Color(1.0, 1.0, 1.0, 0.15)
    _bubble.add_theme_stylebox_override("panel", style)

    _bubble_label = Label.new()
    _bubble_label.text = _dialog_text
    _bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _bubble_label.add_theme_font_size_override("font_size", 8)
    _bubble_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
    _bubble_label.custom_minimum_size = Vector2(124, 0)
    _bubble.add_child(_bubble_label)

    # Flecha (cuadrado pequeno como punta)
    _bubble_arrow = ColorRect.new()
    _bubble_arrow.size = Vector2(6, 6)
    _bubble_arrow.position = Vector2(67, 0)  # centrado, se reposiciona despues
    _bubble_arrow.color = Color(0.0, 0.0, 0.0, 0.8)
    _bubble_arrow.rotation_degrees = 45.0

    _bubble.modulate.a = 0.0
    add_child(_bubble)
    add_child(_bubble_arrow)
    _bubble_arrow.modulate.a = 0.0

func show_dialog(text: String = "") -> void:
    if _bubble_cooldown > 0.0:
        return
    if text != "":
        _bubble_label.text = text
    _bubble_visible = true
    _bubble_timer = 5.0
    var tw := create_tween()
    tw.tween_property(_bubble, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(_bubble, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tw.parallel().tween_property(_bubble_arrow, "modulate:a", 1.0, 0.2)
    _bubble.scale = Vector2(0.8, 0.8)

func hide_dialog() -> void:
    if not _bubble_visible:
        return
    _bubble_visible = false
    _bubble_cooldown = 10.0
    var tw := create_tween()
    tw.tween_property(_bubble, "modulate:a", 0.0, 0.2)
    tw.parallel().tween_property(_bubble, "scale", Vector2(0.8, 0.8), 0.2)
    tw.parallel().tween_property(_bubble_arrow, "modulate:a", 0.0, 0.2)

# Agregar al _process del NPC:
func _process_dialog(delta: float) -> void:
    if _bubble_cooldown > 0.0:
        _bubble_cooldown -= delta
    if _bubble_visible:
        _bubble_timer -= delta
        if _bubble_timer <= 0.0:
            hide_dialog()
```

### Notas de implementacion
- **Prioridad**: SHOULD HAVE
- Este componente NO vive en HUD.gd sino en cada NPC, porque la burbuja sigue al NPC en el mundo
- Se puede extraer como componente generico `DialogBubble.gd` para reutilizar
- Los textos de dialogo por NPC se pueden definir como @export var en el NPC
- Considerar histeresis de 20px (aparece a 60px, desaparece a 80px) para evitar parpadeo

---

## 5. PANTALLA DE RESULTADO DE NIVEL

### Contexto
Al completar un nivel, en lugar de transicionar directamente, se muestra un resumen
de rendimiento por 3 segundos (o hasta input del jugador).

### Wireframe

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│              ┌───────────────────────────┐                  │
│              │     ✓ NIVEL COMPLETADO    │                  │
│              │                           │                  │
│              │   Tiempo:  1:23.45        │                  │
│              │   Pines:   3/5  📍📍📍    │                  │
│              │   Medalla: 🥇 ORO         │                  │
│              │   Sin daño: ✓             │                  │
│              │                           │                  │
│              │      [ Continuar ]        │                  │
│              └───────────────────────────┘                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Posicion y Tamano
- **Panel central**: centrado en pantalla
- **Anchor**: PRESET_CENTER
- **Tamano**: 200 x 140px
- **offset_left**: -100, offset_right: 100, offset_top: -70, offset_bottom: 70

### Estructura de nodos
```
PanelContainer (fondo oscuro)
  └─ VBoxContainer (separation: 4)
       ├─ Label "NIVEL COMPLETADO" (titulo)
       ├─ HSeparator visual (ColorRect 1px)
       ├─ Label "Tiempo: X:XX.XX"
       ├─ Label "Pines: N/5 📍📍..."
       ├─ Label "Medalla: [emoji] [TIER]"
       ├─ Label "Sin dano: [check/x]"
       ├─ ColorRect (separador, 1px)
       └─ Label "[ Continuar ]"
```

### Colores
- **Fondo panel (StyleBoxFlat)**:
  - bg_color: `Color(0.03, 0.03, 0.08, 0.92)`
  - corner_radius: 10px
  - border_width: 2px
  - border_color: `Color(1.0, 0.85, 0.3, 0.6)` (dorado)
  - content_margin: 16px horizontal, 12px vertical
- **Titulo "NIVEL COMPLETADO"**:
  - font_size: 14
  - font_color: `Color(1.0, 0.9, 0.3)` (dorado)
  - horizontal_alignment: CENTER
- **Textos de stats**:
  - font_size: 10
  - font_color: `Color(0.9, 0.9, 0.95)`
- **Valores destacados**:
  - Tiempo mejor personal: `Color(0.4, 1.0, 0.5)` (verde)
  - Sin dano logrado: `Color(0.4, 1.0, 0.5)` (verde)
  - Sin dano fallido: `Color(0.6, 0.6, 0.6)` (gris)
- **"Continuar"**:
  - font_size: 10
  - font_color: `Color(1.0, 1.0, 1.0, 0.7)` -- pulsa suavemente (alpha 0.5 a 1.0)
- **Separadores**:
  - Color: `Color(1.0, 1.0, 1.0, 0.1)`
  - Alto: 1px
- **Overlay detras del panel**: ColorRect full-screen `Color(0.0, 0.0, 0.0, 0.5)`

### Colores de medalla (reutilizar los ya existentes del HUD)
- Gold: `Color(1.0, 0.85, 0.0)`
- Silver: `Color(0.75, 0.75, 0.85)`
- Bronze: `Color(0.8, 0.5, 0.2)`
- None: `Color(0.5, 0.5, 0.5)` (texto "---")

### Animacion
1. **Overlay fade in**: modulate.a 0 -> 1 en 0.3s
2. **Panel entrada**: scale Vector2(0.7, 0.7) -> Vector2(1.0, 1.0) en 0.4s, EASE_OUT, TRANS_BACK
   - Simultaneo con modulate.a 0 -> 1 en 0.3s
3. **Stats aparecen secuencialmente**: cada linea con 0.15s de delay, fade in 0.2s
4. **"Continuar" parpadea**: modulate.a oscila entre 0.5 y 1.0, ciclo de 1.5s (sin -> coseno)
5. **Salida** (al presionar cualquier input despues de 1s): panel scale 1.0 -> 0.9 en 0.15s, fade out 0.2s

### Codigo GDScript

```gdscript
# === Este codigo va en HUD.gd como funcion publica ===

var _result_overlay: ColorRect
var _result_panel: PanelContainer

func show_level_result(time_elapsed: float, pins_found: int, pins_total: int,
                       medal_tier: String, no_damage: bool, is_best_time: bool) -> void:
    # Pausar el juego
    get_tree().paused = true

    # Overlay oscuro
    _result_overlay = ColorRect.new()
    _result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _result_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
    _result_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_result_overlay)

    # Panel central
    _result_panel = PanelContainer.new()
    _result_panel.set_anchors_preset(Control.PRESET_CENTER)
    _result_panel.offset_left   = -100.0
    _result_panel.offset_right  = 100.0
    _result_panel.offset_top    = -70.0
    _result_panel.offset_bottom = 70.0
    _result_panel.process_mode  = Node.PROCESS_MODE_ALWAYS

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.03, 0.03, 0.08, 0.92)
    style.corner_radius_top_left     = 10
    style.corner_radius_top_right    = 10
    style.corner_radius_bottom_left  = 10
    style.corner_radius_bottom_right = 10
    style.border_width_left   = 2
    style.border_width_right  = 2
    style.border_width_top    = 2
    style.border_width_bottom = 2
    style.border_color = Color(1.0, 0.85, 0.3, 0.6)
    style.content_margin_left   = 16.0
    style.content_margin_right  = 16.0
    style.content_margin_top    = 12.0
    style.content_margin_bottom = 12.0
    _result_panel.add_theme_stylebox_override("panel", style)

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 4)
    _result_panel.add_child(vbox)

    # Titulo
    var title_lbl := Label.new()
    title_lbl.text = "NIVEL COMPLETADO"
    title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_lbl.add_theme_font_size_override("font_size", 14)
    title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
    title_lbl.modulate.a = 0.0
    vbox.add_child(title_lbl)

    # Separador
    var sep1 := ColorRect.new()
    sep1.custom_minimum_size = Vector2(0, 1)
    sep1.color = Color(1.0, 1.0, 1.0, 0.1)
    vbox.add_child(sep1)

    # Tiempo
    var mins := int(time_elapsed) / 60
    var secs := int(time_elapsed) % 60
    var ms   := int((time_elapsed - int(time_elapsed)) * 100)
    var time_lbl := Label.new()
    var time_str := "Tiempo:  %d:%02d.%02d" % [mins, secs, ms]
    if is_best_time:
        time_str += " *MEJOR*"
    time_lbl.text = time_str
    time_lbl.add_theme_font_size_override("font_size", 10)
    time_lbl.add_theme_color_override("font_color",
        Color(0.4, 1.0, 0.5) if is_best_time else Color(0.9, 0.9, 0.95))
    time_lbl.modulate.a = 0.0
    vbox.add_child(time_lbl)

    # Pines
    var pin_lbl := Label.new()
    var pin_icons := ""
    for i in pins_total:
        pin_icons += "📍" if i < pins_found else "  "
    pin_lbl.text = "Pines:   %d/%d %s" % [pins_found, pins_total, pin_icons]
    pin_lbl.add_theme_font_size_override("font_size", 10)
    pin_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
    pin_lbl.modulate.a = 0.0
    vbox.add_child(pin_lbl)

    # Medalla
    var medal_lbl := Label.new()
    match medal_tier:
        "gold":
            medal_lbl.text = "Medalla: ORO"
            medal_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
        "silver":
            medal_lbl.text = "Medalla: PLATA"
            medal_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
        "bronze":
            medal_lbl.text = "Medalla: BRONCE"
            medal_lbl.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
        _:
            medal_lbl.text = "Medalla: ---"
            medal_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
    medal_lbl.add_theme_font_size_override("font_size", 10)
    medal_lbl.modulate.a = 0.0
    vbox.add_child(medal_lbl)

    # Sin dano
    var dmg_lbl := Label.new()
    dmg_lbl.text = "Sin dano: %s" % ("SI" if no_damage else "no")
    dmg_lbl.add_theme_font_size_override("font_size", 10)
    dmg_lbl.add_theme_color_override("font_color",
        Color(0.4, 1.0, 0.5) if no_damage else Color(0.6, 0.6, 0.6))
    dmg_lbl.modulate.a = 0.0
    vbox.add_child(dmg_lbl)

    # Separador
    var sep2 := ColorRect.new()
    sep2.custom_minimum_size = Vector2(0, 1)
    sep2.color = Color(1.0, 1.0, 1.0, 0.1)
    vbox.add_child(sep2)

    # Continuar
    var cont_lbl := Label.new()
    cont_lbl.text = "[ Continuar ]"
    cont_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cont_lbl.add_theme_font_size_override("font_size", 10)
    cont_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
    cont_lbl.modulate.a = 0.0
    vbox.add_child(cont_lbl)

    _result_panel.modulate.a = 0.0
    _result_panel.scale = Vector2(0.7, 0.7)
    add_child(_result_panel)

    # === ANIMACION ===
    var tw := create_tween()
    tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    # Overlay
    tw.tween_property(_result_overlay, "color:a", 0.5, 0.3)
    # Panel
    tw.parallel().tween_property(_result_panel, "modulate:a", 1.0, 0.3)
    tw.parallel().tween_property(_result_panel, "scale", Vector2(1.0, 1.0), 0.4)\
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

    # Stats secuenciales
    var stats := [title_lbl, time_lbl, pin_lbl, medal_lbl, dmg_lbl, cont_lbl]
    for i in stats.size():
        tw.tween_interval(0.15)
        tw.tween_property(stats[i], "modulate:a", 1.0, 0.2)

    # Parpadeo del "Continuar"
    var pulse_tw := create_tween()
    pulse_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    pulse_tw.set_loops()
    pulse_tw.tween_property(cont_lbl, "modulate:a", 0.5, 0.75)
    pulse_tw.tween_property(cont_lbl, "modulate:a", 1.0, 0.75)

    # Esperar input para cerrar (despues de 1s minimo)
    await get_tree().create_timer(1.5).timeout
    set_meta("_result_ready", true)

func _close_result_and_continue(next_scene: String) -> void:
    get_tree().paused = false
    if is_instance_valid(_result_overlay):
        _result_overlay.queue_free()
    if is_instance_valid(_result_panel):
        _result_panel.queue_free()
    SceneTransition.go_to(next_scene)
```

Agregar al `_input` o `_process` del HUD:
```gdscript
# En _process o _unhandled_input del HUD:
if has_meta("_result_ready") and get_meta("_result_ready"):
    if Input.is_anything_pressed():
        set_meta("_result_ready", false)
        # ProceduralLevel conectara esto con la escena siguiente
        emit_signal("result_dismissed")
```

Agregar senal al HUD:
```gdscript
signal result_dismissed
```

### Integracion con ProceduralLevel.gd
Reemplazar la transicion directa en `_finish()`:
```gdscript
func _finish() -> void:
    if _level_finished: return
    _level_finished = true
    GameManager.clear_checkpoint()

    var medal := "none"
    if _timer_node:
        medal = _timer_node.stop()

    var elapsed := _timer_node.elapsed if _timer_node else 0.0
    var is_best := false
    var prev_best := GameManager.get_best_time(data.level_key)
    if prev_best <= 0 or elapsed < prev_best:
        is_best = true

    if _no_damage:
        GameManager.set_no_damage(data.level_key)
    GameManager.complete_level(data.level_key)

    # Contar pines del nivel actual encontrados en esta sesion
    var pins_found := 0
    for pid in data.pin_ids:
        if GameManager.has_pin(pid):
            pins_found += 1

    _hud.show_level_result(elapsed, pins_found, data.pin_ids.size(), medal, _no_damage, is_best)
    _hud.result_dismissed.connect(func():
        SceneTransition.go_to(data.next_scene)
    , CONNECT_ONE_SHOT)
```

### Notas de implementacion
- **Prioridad**: MUST HAVE
- Usa `process_mode = ALWAYS` para que funcione durante pausa
- El tween tambien necesita `TWEEN_PAUSE_PROCESS` para animar durante pausa
- El jugador debe poder presionar cualquier boton para continuar despues de 1.5s

---

## 6. MEJORAS AL TOPBAR EXISTENTE

### Analisis del TopBar actual

El TopBar actual tiene:
- HeartRow: corazones regenerados dinamicamente (funciona bien)
- PinCount: "📍 N" -- solo muestra cantidad absoluta
- WorldLabel: nombre del nivel (funciona bien)

### Problema 1: PinCount sin contexto
"📍 3" no dice nada. Son 3 de 5? De 25? Del nivel o del mundo?

**Solucion**: Mostrar pines del nivel actual vs total del nivel.

### Problema 2: No hay separacion visual entre grupos
Los 3 elementos estan juntos sin jerarquia clara.

**Solucion**: Micro-separadores y opacidad diferenciada.

### Problema 3: Vida sin max_health visible
Si el jugador tiene 2 corazones de 5 posibles, es claro. Pero si algun dia
max_health cambia, no es evidente.

**Solucion**: El sistema actual ya muestra corazones vacios. Mantener asi.

### Cambios especificos

#### 6A. PinCount contextual

Cambiar de `"📍 3"` a `"📍 2/5"` donde 2 son los pines encontrados en el nivel
actual y 5 es el total de pines del nivel.

```gdscript
# Reemplazar _update_pins:
var _level_pin_ids: Array[String] = []

func set_level_pins(pin_ids: Array) -> void:
    _level_pin_ids = pin_ids
    _update_pins("")

func _update_pins(_id: String) -> void:
    if _level_pin_ids.is_empty():
        pin_label.text = "📍 %d" % GameManager.pins_collected.size()
    else:
        var found := 0
        for pid in _level_pin_ids:
            if GameManager.has_pin(pid):
                found += 1
        pin_label.text = "📍 %d/%d" % [found, _level_pin_ids.size()]
```

En ProceduralLevel._spawn_hud():
```gdscript
_hud.set_level_pins(data.pin_ids)
```

#### 6B. Pines como iconos individuales

Alternativa mas visual: en lugar de "📍 2/5", mostrar 5 circulitos donde los
encontrados estan llenos y los pendientes estan vacios. Similar a los corazones.

```gdscript
# Crear un PinRow similar a HeartRow
var _pin_row: HBoxContainer

func _build_pin_row() -> void:
    _pin_row = HBoxContainer.new()
    _pin_row.add_theme_constant_override("separation", 2)
    # Posicionar junto al pin_label existente o reemplazarlo
    # Posicion: despues de HeartRow, con 8px de margen

func _update_pin_icons() -> void:
    for child in _pin_row.get_children():
        child.queue_free()
    for i in _level_pin_ids.size():
        var found := GameManager.has_pin(_level_pin_ids[i])
        var dot := Label.new()
        dot.text = "●" if found else "○"
        dot.add_theme_font_size_override("font_size", 8)
        dot.add_theme_color_override("font_color",
            Color(1.0, 0.8, 0.1) if found else Color(0.5, 0.5, 0.5, 0.4))
        _pin_row.add_child(dot)
```

**Recomendacion**: Usar la opcion 6A (texto) por simplicidad. Es mas legible en un
viewport de 480x270 y no requiere un nuevo contenedor. Si en testing se siente
aburrido, escalar a 6B.

#### 6C. Animacion de corazon al recibir dano

Actualmente los corazones simplemente se reconstruyen. Agregar un micro-feedback:

```gdscript
func _update_hearts(hp: int) -> void:
    for child in heart_row.get_children():
        child.queue_free()
    for i in GameManager.nora["max_health"]:
        var lbl := Label.new()
        lbl.text = "♥" if i < hp else "♡"
        lbl.add_theme_font_size_override("font_size", 18)
        lbl.add_theme_color_override("font_color",
            Color(0.95, 0.2, 0.3) if i < hp else Color(0.5, 0.5, 0.5, 0.6))
        heart_row.add_child(lbl)

        # Animacion de "sacudida" al corazon que acaba de perderse
        if i == hp and hp < GameManager.nora["max_health"]:
            lbl.modulate.a = 0.3
            var tw := create_tween()
            tw.tween_property(lbl, "modulate:a", 0.6, 0.1)
            tw.tween_property(lbl, "modulate:a", 0.3, 0.1)
            tw.tween_property(lbl, "modulate:a", 0.6, 0.15)
```

#### 6D. Flash rojo de pantalla al recibir dano

Overlay rojo momentaneo para reforzar el feedback de dano:

```gdscript
var _damage_flash: ColorRect

func _build_damage_flash() -> void:
    _damage_flash = ColorRect.new()
    _damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    _damage_flash.color = Color(0.8, 0.05, 0.05, 0.0)
    _damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_damage_flash)

func _on_damage_flash() -> void:
    var tw := create_tween()
    tw.tween_property(_damage_flash, "color:a", 0.25, 0.05)
    tw.tween_property(_damage_flash, "color:a", 0.0, 0.3)
```

Conectar en `_ready()`:
```gdscript
GameManager.health_changed.connect(func(hp):
    if hp < GameManager.nora["max_health"]:
        _on_damage_flash()
)
```

Nota: Necesita trackear el HP anterior para saber si fue dano o curacion.
Mejor implementacion:

```gdscript
var _prev_health: int = 3

func _ready() -> void:
    # ... (lo existente) ...
    _prev_health = GameManager.nora["health"]
    _build_damage_flash()
    _build_progress_bar()
    GameManager.health_changed.connect(func(hp):
        if hp < _prev_health:
            _on_damage_flash()
        _prev_health = hp
    )
```

### Notas de implementacion para TopBar
- **6A PinCount contextual**: MUST HAVE (cambio minimo, gran mejora informativa)
- **6B Pin icons**: NICE TO HAVE (mas visual pero puede saturar en viewport pequeno)
- **6C Animacion corazon**: SHOULD HAVE (feedback satisfactorio, poco esfuerzo)
- **6D Flash de dano**: MUST HAVE (feedback critico que falta completamente)

---

## RESUMEN DE PRIORIDADES

| # | Feature                     | Prioridad   | Complejidad | Lineas estimadas |
|---|-----------------------------|-------------|-------------|------------------|
| 1 | Notificacion item recogido  | MUST HAVE   | Baja        | ~60              |
| 2 | Indicador buffs activos     | MUST HAVE   | Media       | ~80              |
| 3 | Barra de progreso           | SHOULD HAVE | Baja        | ~40              |
| 4 | Dialogo NPC                 | SHOULD HAVE | Media       | ~70 (por NPC)    |
| 5 | Pantalla resultado nivel    | MUST HAVE   | Media-Alta  | ~120             |
| 6A| PinCount contextual         | MUST HAVE   | Minima      | ~10              |
| 6C| Animacion corazon           | SHOULD HAVE | Minima      | ~8               |
| 6D| Flash de dano               | MUST HAVE   | Baja        | ~15              |

## HUD FINAL: WIREFRAME COMPLETO

```
┌─────────────────────────────────────────────────────────────┐
│ [♥♥♡♡♡] [📍 2/5] [La Orilla]                 [0:42.15]     │
│ [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░ barra progreso ░░░░░] │
│                                    ┌───────────────┐        │
│                                    │ ⚡ ████░░ 3.2s│        │
│                                    └───────────────┘        │
│                              ┌──────────────────┐           │
│                              │ +♥ Vida          │           │
│                              └──────────────────┘           │
│                     AREA DE JUEGO                           │
│                                                             │
│     [BOSS BAR ══════════════════════════════]  (si aplica)   │
│ [DAMAGE FLASH: overlay rojo momentaneo, cubre toda la       │
│  pantalla por 0.35s al recibir dano]                        │
└─────────────────────────────────────────────────────────────┘
```

## PALETA DE COLORES UNIFICADA

| Uso                    | Color                          | Hex       |
|------------------------|--------------------------------|-----------|
| HUD texto principal    | `Color(1.0, 1.0, 1.0, 0.95)`  | #F2F2F2   |
| HUD texto secundario   | `Color(1.0, 1.0, 1.0, 0.6)`   | #999999   |
| Corazon lleno          | `Color(0.95, 0.2, 0.3)`       | #F23349   |
| Corazon vacio          | `Color(0.5, 0.5, 0.5, 0.6)`   | #808080   |
| Buff speed             | `Color(1.0, 0.85, 0.2)`       | #FFD933   |
| Buff shield            | `Color(0.3, 0.7, 1.0)`        | #4DB3FF   |
| Item health            | `Color(0.95, 0.29, 0.42)`     | #F24A6B   |
| Progreso barra fondo   | `Color(1.0, 1.0, 1.0, 0.1)`   | -         |
| Resultado borde        | `Color(1.0, 0.85, 0.3, 0.6)`  | #FFD94D   |
| Resultado fondo        | `Color(0.03, 0.03, 0.08, 0.92)`| #080814  |
| Flash dano             | `Color(0.8, 0.05, 0.05)`      | #CC0D0D   |
| Dialogo NPC fondo      | `Color(0.0, 0.0, 0.0, 0.8)`   | #000000   |
| Gold medal             | `Color(1.0, 0.85, 0.0)`       | #FFD900   |
| Silver medal           | `Color(0.75, 0.75, 0.85)`     | #BFBFD9   |
| Bronze medal           | `Color(0.8, 0.5, 0.2)`        | #CC8033   |

## TIPOGRAFIA

Todo usa la fuente por defecto de Godot (sin assets externos).

| Contexto           | font_size |
|--------------------|-----------|
| Titulo resultado   | 14        |
| Corazones HUD      | 18        |
| Timer              | 12        |
| Stats resultado    | 10        |
| Buff timer         | 8         |
| Item notification  | 10        |
| NPC dialogo        | 8         |
| Pin count          | (hereda de TopBar) |
| Progreso           | sin texto |

## SENALES NUEVAS REQUERIDAS

```gdscript
# En GameManager.gd:
signal item_picked_up(item_type: String)  # "health", "speed_boost", "shield"

# En HUD.gd:
signal result_dismissed
```

## ORDEN DE IMPLEMENTACION RECOMENDADO

1. **6D** Flash de dano (5 min, feedback critico inmediato)
2. **6A** PinCount contextual (5 min, cambio minimo)
3. **1** Notificacion item recogido (15 min)
4. **2** Indicador buffs activos (20 min)
5. **3** Barra de progreso (10 min)
6. **5** Pantalla resultado nivel (30 min)
7. **6C** Animacion corazon (5 min)
8. **4** Dialogo NPC (20 min, requiere NPC script)
