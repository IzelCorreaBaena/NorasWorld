# 📜 Master Development Plan: Nora's World

## 🎯 Project Vision
A 2D physics-based platformer/adventure with the tactical "feel" of *Inside* and *Limbo*, but with a bright, luminous, and emotionally resonant aesthetic. The gameplay focuses on weight, inertia, and physical interaction with the environment to solve puzzles and navigate the world.

**Core Loop:** Explore $\rightarrow$ Interact with Environment $\rightarrow$ Solve Physics Puzzles $\rightarrow$ Emotional Progression.

---

## 🎭 Narrative & Emotional Arc (20 Hours)

| Act | World / Theme | Emotional Core | Key Mechanics |
| :--- | :--- | :--- | :--- |
| **I** | **The Awakening** | Wonder / Curiosity | Basic Movement, Dash |
| **II** | **The Rhythm of Life** | Energy / Adventure | Weighted Platforms, Rhythmic Traps |
| **III** | **The Burden** | Resilience / Effort | Combat, Heavy Objects, Physics Puzzles |
| **IV** | **The Bond** | Empathy / Connection | Companion AI, Cooperative Puzzles |
| **V** | **The Revelation** | Transcendence | All Mechanics Combined, Climactic Platforming |

---

## ⚙️ Core Systems (The Pillars)

### 1. Movement & Parkour (The "Feel")
*   **Precision Physics:** Coyote Time, Jump Buffer, variable jump height.
*   **Advanced Agility:** Wall Jump, Wall Slide, and Ledge Grab (using RayCast detection).
*   **Dash Mechanic:** High-speed bursts for traversal and combat.

### 2. Dynamic Obstacles & Puzzles
*   **Reactive Environment:** Platforms that react to player weight (Weighted Platforms).
*   **Rhythmic Challenges:** Non-lethal traps that use timing and inertia (Rhythmic Traps).
*   **Logic Puzzles:** Pressure plates, remote doors, and weight-based gates.

### 3. Physical Combat & AI
*   **Tactical Combat:** Using the environment (throwing objects, heavy props) rather than traditional weapons.
*   **State-Based AI:** Enemies with Patrol, Detect, Chase, and Attack states.

### 4. Companion System
*   **Intelligent Follower:** Navigation-based movement (`NavigationAgent2D`) to avoid getting stuck.
*   **Command System:** Ability to order the companion to "Stay" or "Activate" environmental switches.

### 5. NPCs & Dialogue
*   **Environmental Storytelling:** NPCs that interact via proximity and simple dialogue systems.
*   **UI/UX:** Clean, non-intrusive dialogue boxes.

---

## 🛠️ Technical Roadmap

## 🛠️ Technical Roadmap

### Phase 1: Foundation (Completed)
- [x] Advanced Player FSM (Movement, Dash, Ledge Grab).
- [x] Basic Interaction System (Pick up/Throw).

### Phase 2: Dynamic World (Completed)
- [x] Implement Weighted Platforms & Rhythmic Traps.
- [x] Create Pressure Plate & Remote Door system.
- [x] Build a "Puzzle Playground" test scene.

### Phase 3: Life & Intelligence (Completed)
- [x] Implement Companion AI (Navigation-based).
- [x] Implement Enemy AI (State-machine based).
- [x] Implement NPC & Dialogue UI.

### Phase 4: Polishing & Content (In Progress)
- [ ] Asset integration (Animations, VFX, SFX).
- [ ] Level design for all 5 Acts.
- [ ] Final QA and optimization.
