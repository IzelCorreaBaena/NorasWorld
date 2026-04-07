## PROYECTO
- Nombre: NorasWorld
- Objetivo: Platformer 2D indie "Nora's World" - regalo para Nora, 16-20h de juego, móvil
- Estado: CONTINUE → BUILD ACTIVO

## STACK
- Motor: Godot 4.6
- Lenguaje: GDScript
- Resolución: 480x270 (canvas_items stretch, expand)
- Target: Android (móvil) + PC

## ARQUITECTURA DEL SISTEMA

### Autoloads
- GameManager.gd: save/load, salud, pines, outfits, mundos, niveles, NG+
- OutfitManager.gd: 5 outfits con habilidades pasivas
- SceneTransition.gd: fade negro entre escenas
- NGPlusManager.gd: escalado de enemigos/jefes en NG+

### Sistema de Niveles (DATA-DRIVEN)
- LevelData.gd (Resource): define todo el contenido de un nivel
- ProceduralLevel.gd: lee LevelData y construye el nivel en runtime
- Cada nivel = .tscn (escena) + .tres (LevelData resource)
- platform_rects: Array[Rect2] → plataformas spawneadas proceduralmente

### Tipos de Enemigos
- patrol: Enemy.gd, patrulla horizontal, gira en paredes
- flying: EnemyFlying.gd, movimiento senoidal
- jumper: EnemyJumper.gd, salta hacia el jugador

### Jefes (todos heredan de Boss.gd)
- BossWave.gd (W1): scroll lateral, el jugador debe llegar al final
- BossMannequin.gd (W2): copia movimientos de Nora con delay
- BossShadow.gd (W3): persigue a Nora, se daña con light_zones
- BossMirror.gd (W4): 7 fragmentos que romper en orden
- BossFinal.gd (W5): combina ataques de los 4 anteriores, 9 HP

## MUNDOS Y NIVELES (25 total)

### Mundo 1 - "Ola Grande" (Beach) → double jump + surfera
- W1_L1: La Orilla (tutorial)
- W1_L2: Marea Baja (intro agua)
- W1_L3: El Arrecife
- W1_L4: La Tormenta
- W1_Boss: La Ola Perfecta (BossWave)

### Mundo 2 - "Pasarela Infinita" (City) → dash + fashion_week
- W2_L1: El Backstage
- W2_L2: Tejados
- W2_L3: La Pasarela
- W2_L4: Noche de Moda
- W2_Boss: El Maniquí (BossMannequin)

### Mundo 3 - "La Tribu" (Tribe) → wall jump + tribal
- W3_L1: La Fogata
- W3_L2: Bosque Tribal
- W3_L3: Las Ruinas
- W3_L4: El Ritual
- W3_Boss: La Sombra (BossShadow)

### Mundo 4 - "El Estudio" (Studio) → estilista_pro
- W4_L1: El Taller
- W4_L2: Sueño de Diseño
- W4_L3: El Espejo
- W4_L4: La Colección Final
- W4_Boss: El Espejo Roto (BossMirror)

### Mundo 5 - "El Otro Mundo" (Secret) → se desbloquea con 2 mundos al 100%
- W5_L1: El Umbral
- W5_L2: Vacío
- W5_L3: Recuerdos
- W5_L4: El Núcleo
- W5_Boss: La Nora Perdida (BossFinal)

## PINES
- 5 pines por nivel × 5 niveles × 5 mundos = 125 pines
- GameManager.total_pins_in_world() = 25 pines por mundo
- IDs: pin_WX_LY_0Z (ej: pin_W1_L1_01)
- Boss pins: pin_worldX_05 (formato legacy mantenido)

## DURACIÓN ESTIMADA
- Campaña principal (25 niveles × 15min avg): ~6h
- 100% pines: +4h
- NG+: +5h
- Boss Rush + no-damage: +3h
- Mundo 5 secreto: +2h
- Total: ~20h

## OUTFITS
- default: "Exploradora" - sin habilidad pasiva
- surfera: caída lenta en agua (W1 reward)
- fashion_week: dash con estrellas (W2 reward)
- tribal: wall jump style (W3 reward)
- estilista_pro: doble dash (W4 reward)

## DECISIONES
- Sistema data-driven: LevelData .tres + ProceduralLevel.gd
- Plataformas spawneadas en runtime desde platform_rects
- EnemyFlying y EnemyJumper como escenas separadas
- WorldHub.gd maneja pantalla de selección de nivel por mundo
- Title screen va antes del WorldMap
- PauseMenu.gd como CanvasLayer, activado con ESC o botón ⏸

## ARCHIVOS CREADOS (por agentes en progreso)
### scripts/
- EnemyFlying.gd ← agente godot-2d-mechanic-builder
- EnemyJumper.gd ← agente godot-2d-mechanic-builder
- BossFinal.gd ← agente godot-2d-mechanic-builder
- WorldHub.gd ← agente game-integration-builder
- Title.gd ← agente game-integration-builder
- PauseMenu.gd ← agente game-integration-builder

### scenes/
- EnemyFlying.tscn ← agente godot-2d-mechanic-builder
- EnemyJumper.tscn ← agente godot-2d-mechanic-builder
- Title.tscn ← agente game-integration-builder
- PauseMenu.tscn ← agente game-integration-builder
- World1-5.tscn (WorldHub) ← agente game-integration-builder

### scenes/levels/
- W1_L1.tscn ... W5_L4.tscn (20 niveles normales) ← agente 2d-physics-engineer
- W1_Boss.tscn ... W5_Boss.tscn (5 boss scenes) ← agente godot-2d-mechanic-builder

### data/levels/
- W1_L1.tres ... W5_L4.tres (20 LevelData resources) ← agente 2d-physics-engineer

## MODIFICACIONES A ARCHIVOS EXISTENTES
- LevelData.gd: +platform_rects: Array[Rect2]
- ProceduralLevel.gd: +_spawn_platforms(), actualizar _spawn_enemies() para tipos flying/jumper, +pause menu
- Main.gd: ir a Title.tscn en lugar de WorldMap.tscn
- WorldMap.gd: añadir Mundo 5 al WORLD_DATA

## ERRORES CONOCIDOS
-

## ÚLTIMA ACCIÓN
- 2026-04-07: BUILD COMPLETADO — 3 agentes finalizados + correcciones manuales

### RESUMEN DEL BUILD
✅ LevelData.gd + platform_rects añadido
✅ ProceduralLevel.gd + _spawn_platforms(), _spawn_enemies() actualizado, PauseMenu
✅ EnemyFlying.gd + EnemyFlying.tscn
✅ EnemyJumper.gd + EnemyJumper.tscn
✅ BossFinal.gd (jefe secreto W5, 3 fases, 9 HP)
✅ 5 boss scenes (W1-W5): Player.tscn instancia, HUD.tscn instancia, WorldBoundaryShape2D
✅ 20 LevelData .tres (W1_L1 a W5_L4) con plataformas, pines, enemigos, checkpoints
✅ 20 level .tscn (W1_L1 a W5_L4) con ProceduralLevel + Floor + TouchControls
✅ Title.gd + Title.tscn (menú principal animado)
✅ WorldHub.gd + WorldHub1-5.tscn (selección de nivel por mundo)
✅ PauseMenu.gd + PauseMenu.tscn (ESC o botón ⏸)
✅ Main.gd → Title.tscn
✅ WorldMap.gd → 5 mundos, World5 a x=440
✅ project.godot → 4 autoloads: GameManager, OutfitManager, SceneTransition, NGPlusManager

### PARA PERSONALIZAR (pendiente - segunda fase)
- Añadir sprites reales de Nora en nora_sheet.png al AnimatedSprite2D
- Ajustar colores/nombres a la persona real
- Personalizar diálogos en DialogSystem con mensajes personales
- Añadir música (AudioStreamPlayer en cada mundo)
- Testear y balancear niveles
