# MVP v1 — User Stories

> Each story produces a runnable game. Every 1–2 stories, we pause for a planning session: review, write new stories, delete duplicates, re-order.

---

## Story 1: Project scaffolding

**As Chris, the developer,**
**I want** a Go project scaffolded with Ebitengine, proper package structure, and a buildable binary
**So that** I have a working foundation on which to build the game.

**Notes:**
- Go module, Ebitengine setup, `.gitignore`
- Structure: `cmd/main.go`, `pkg/game/`, `pkg/entity/`, `pkg/render/`, `pkg/input/`, `test_integration/`
- Window opens at 1280×720, renders gray background, exits on Escape
- Builds on macOS, Linux, Windows

---

## Story 2: Main menu

**As Fred, the player,**
**I want** a simple main menu with a "Start" button and a "Quit" button that can be summoned at any time with ESC.
**So that** I can begin a run or exit the game.

**Notes:**
- Menu screen: title, "Start" button, and "Quit" button (with text).
- ESC (at any time) $\rightarrow$ Menu screen.
- "Quit" button $\rightarrow$ Exit application.
- Clean state reset between runs.
- Input: mouse click or Enter for "Start".
- Menu can be pulled up at any time during a run.

---

## Story 3: Train movement

**As Fred, the player,**
**I want** to accelerate, decelerate, brake, and reverse direction with keyboard input
**So that** I have full control over the train's movement.

**Notes:**
- Train = colored rectangle (placeholder art)
- Controls: W/↑ = power up, S/↓ = power down, Space = brakes, R = engage reverse
- Velocity changes smoothly (acceleration + braking curves)
- Unit tests for velocity changes

---

## Story 4: Track palette

**As Fred, the player,**
**I want** a visible palette showing available track types (Straight, H-V Cross, Curve, 64-Curve)
**So that** I can select and drag the track piece I want to place.

**Notes:**
- Track palette UI at screen edge (visible when not actively dragging)
- Drag-and-drop from palette onto canvas
- Track segment entity data model
- Types: 32×32 Straight, 32×32 H-V Cross, 32×32 Curve, 64×64 Curve
- Render track as colored lines/shapes (placeholder art)

---

## Story 5: Track placement + undo

**As Fred, the player,**
**I want** to drag track from the palette onto the game world, with undo support for just-placed track
**So that** I can experiment freely when planning my route.

**Notes:**
- Validates connection to existing track before placement
- Undo: backspace or click undos newly placed track only (previous runs' track is fixed)
- Track is free in MVP
- On canvas update, track persists
- Track graph: connected, no junctions/switches in MVP

---

## Story 6: Train follows track

**As Fred, the player,**
**I want** the train to snap to and follow my placed track, stopping at dead ends
**So that** my track-laying effort actually creates a drivable route.

**Notes:**
- Train "snaps" to track as it moves along it
- Train stops dead at track end
- Reverse direction works along existing track
- Camera follows the train

---

## Story 7: Auto-fire system

**As Fred, the player,**
**I want** the Pistol Car and MG Car to automatically fire at nearby enemies
**So that** I can focus on driving and track-laying while the train defends itself.

**Notes:**
- Pistol Car: slow fire rate, decent damage
- MG Car: fast fire rate, low damage
- Both have similar DPS despite different trade-offs
- Bullet entity: speed, range, damage, color-coded
- Firing logic: target nearest enemy
- Shield Car: separate shield HP bar, absorbs damage before train health
- Shield doubles effective HP available

---

## Story 8: Config tables

**As Chris, the developer,**
**I want** a central configuration table for all enemy stats, car stats, bullet stats, and upgrade values
**So that** I can quickly tweak numbers to balance the game without hunting through code.

**Notes:**
- `pkg/config/` — data tables for everything tunable
- YAML or inline struct — easy to edit at runtime or reload
- Unit tests for config validation
- Enemy stats: HP, speed, damage, fire rate
- Car stats: fire rate, damage, range, DPS
- Upgrade stat ranges and scaling

---

## Story 9: Enemy spawning

**As Fred, the player,**
**I want** enemies of different types to spawn from off-screen edges and attack me
**So that** I have something to shoot and survive against.

**Notes:**
- Config-driven: Chaser, Speedy, Shooty
- Chaser: ~3 pistol hits, medium speed, dmg ≈ pistol
- Speedy: ~2 MG hits / ~1 pistol hit, fast (keeps up at max train speed), dmg ≈ 1/3 pistol
- Shooty: slow, ~2 pistol hits, shoots back at 1/2 rate, 1/6 damage
- Spawn from off-screen edges, rate scales over time
- Collision: bullets kill enemies, enemies hit train (shield first, then health)
- Config-driven table for all tuning (Story 8 feeds this)

---

## Story 10: XP, leveling, and upgrades

**As Fred, the player,**
**I want** to collect XP from kills, level up, and choose from 3-4 upgrade options
**So that** I can customize my train's performance as the run progresses.

**Notes:**
- XP per kill (config-driven from Story 8)
- Level-up triggers when XP threshold reached
- Brief pause, show 3-4 upgrade options from pool
- Pool: train max health ↑, shield max ↑, pistol rate/dmg/range ↑, MG rate/dmg/range ↑, train max speed ↑, train max braking ↑
- Apply upgrade, resume
- Stackable indefinitely

---

## Story 11: Game over screen

**As Fred, the player,**
**I want** a death screen showing stats and a "Return to Menu" button
**So that** I can see how I performed and decide whether to try again.

**Notes:**
- Health reaches 0 → game over
- Display stats: enemy count, distance, level reached (can fake some for MVP)
- "Return to Menu" button
- Full state reset for new run

---

## Story 12: Audio

**As Fred, the player,**
**I want** synthesized beeps and boops for key actions
**So that** the game has basic audio feedback without needing art assets.

**Notes:**
- Ebitengine sound API: sine wave oscillator
- Sounds for: fire, hit, kill, level up, death, menu clicks
- Volume toggle (ESC secondary function?)

---
