# Build Plan

> A list of ordered tasks. Each single task will be tackled by one AI Agent run.

## Task Order & Dependencies

Each task depends on the tasks listed above it. Complete each task before moving to the next.

---

### Task 1 — Project Setup

**Description:** Initialize the Godot project with proper structure, mise.toml, trunk.toml, and AGENTS.md.

**Includes:**

- `project.godot` configured for the project
- Flat directory structure: `/test/` for GUT tests
- Basic `README.md`
- AGENTS.md (already exists)

**Acceptance Criteria:**

- `godot --headless --quit` succeeds (project file is valid)
- `mise install` provisions all tools
- `trunk check` runs without errors on empty project
- GUT is installed and can run in headless mode

**Escalation Triggers:**

- Godot version mismatch between mise and GUT compatibility

---

### Task 2 — Physics System (Foundation)

**Description:** Implement simple 2D physics: collisions, momentum, weight scaling, elastic pushes between entities.

**Includes:**

- `physics.gd` — collision detection and resolution (2D)
- Elastic push behavior for train-enemy and train-obstacle collisions (2D)
- Momentum model: `momentum = speed * total_weight`
- **Weight scaling:** acceleration and deceleration scale inversely with total train weight
  - `effective_acceleration = engine_power / total_weight`
  - `effective_deceleration = brake_force / total_weight`
  - Engine-only train: snappy response
  - Full train: sluggish, powerful, hard to stop
- GUT tests for all physics rules

**Acceptance Criteria:**

- All GUT tests pass (physics rules are deterministic and testable)
- Train can push enemies and obstacles with elastic force
- Train has momentum (can't stop instantly)
- Weight scaling works: more cars = slower acceleration, longer braking
- Physics works independently of any rendering

**Escalation Triggers:**

- GUT can't test physics without a scene context
- Elastic collision math produces unstable results
- Weight scaling formula produces unintuitive feel (needs tuning)

---

### Task 2a — Physics Polish & Hygiene

**Description:** Address the code review findings from Task 2: fix rolling friction semantics, add static return types to silence GUT warnings, and strengthen the dictionary-based collision contract.

**Includes:**

- `physics.gd` — Rename rolling friction constant: extract `-acceleration * 0.1` into a dedicated `const ROLLING_FRICTION_FACTOR: float = 0.1` and use `effective_deceleration(brake_force, total_weight) * ROLLING_FRICTION_FACTOR` for coasting slowdown
- `physics.gd` — Add `is_colliding()` wrapper around `circles_ahead()` for semantic callsites in later tasks
- `physics.gd` — Add type assertion at the top of `elastic_collision()` to validate `"mass"` and `"velocity"` keys exist before mutating
- `test/test_physics.gd` — Add `-> void` static return type to all 37 test method signatures (silences GUT "no static return type" warnings in CI)
- `test/test_physics.gd` — Rename helper `_make_body()` to `_make_body_dict()` to avoid confusion with a future `PhysicsBody` class

**Acceptance Criteria:**

- All 37 GUT tests still pass
- No `WARNING: Function ... has no static return type` messages in test output
- Rolling friction uses deceleration (brake force), not acceleration — coasting slowdown is independent of engine power
- `is_colliding()` exists and works as a clean wrapper for the 1-line circle overlap check
- `elastic_collision()` exits early with a clear error if required keys are missing (not a silent crash later)

**Escalation Triggers:**

- Refactoring dictionary keys breaks callers who rely on the loose contract
- Rolling friction formula needs tuning for actual train feel

---

### Task 3 — Track Laying System

**Description:** Pre-round track placement using discrete segments (like a child's train set). Segments snap to an infinite grid. Track has an explicit starting point (train yard) and must form a continuous path from that point. New segments can only be added from the current track end.

**Includes:**

- `track_segment.gd` — segment type (straight/curve_left/curve_right), orientation (4 cardinal directions), graphic reference, collision shape
- `track.gd` — segment placement, grid snapping, validation, path storage
- Track starts at a fixed starting point (train yard)
- Track must be continuous — new segments can only be added from the current track end
- Segment types: straight, curved left, curved right (3 base graphics)
- Track laying UI: grid-based placement with segment preview
- Resource cost tracking per segment
- Max track length (initially a fixed value, upgradable later)
- GUT tests for segment validation (overlap, continuity, connectivity)

**Acceptance Criteria:**

- Player can place track segments on the grid in track-lay phase
- Segments snap to grid cells; preview shows segment graphic before placement
- Track always starts from the train yard starting point
- New segments can only be added from the current track end (continuous path enforced)
- Track placement costs resources; insufficient resources prevents placement
- Invalid placements (overlapping, not adjacent to track end) are rejected
- GUT tests for segment validation logic pass

**Escalation Triggers:**

- UI placement feels awkward without visual feedback

---

### Task 4 — Train Controls (Keyboard) ✅ COMPLETE

**Fixes applied:** Straight/curve alignment corrected. Straights use edge-to-edge formula; curves use radius-32 arc centered on grid cell. Shared cell edges connect segments without gaps.

**Description:** Train entity with throttle/brakes using keyboard input, moving along the track with physics. Train moves segment-by-segment; rotation snaps to segment orientation. Cars pivot at couplings when turning.

**Includes:**

- `train.gd` — train entity with position, speed, acceleration, health, current segment index, total_weight, engine_power
- `car.gd` — car entity with position, coupling_offset, pivot_angle
- Keyboard throttle (e.g., W/Up) and brake (e.g., S/Down or Space)
- Train moves segment-by-segment along the track
- Train rotation snaps to segment orientation (straight = 0°, curve = segment's angle)
- **Bogie/pivot animation (2D):** When the engine enters a curve, cars rotate around a pivot offset:
  - Each car has a bogie_offset (pivot point near front/back, not at edges)
  - Car body rotates around this offset point to simulate bogie pivot
  - Creates the characteristic train car angle on curves
  - Visual only — physics still follow track segments
- Speed display in HUD
- Train health (damage from enemies)
- GUT tests for train physics behavior (independent of input method)

**Acceptance Criteria:**

- Keyboard throttle increases speed, brakes decrease it
- Train moves along the placed track segment-by-segment
- Train rotation snaps to segment orientation
- Train accelerates/decelerates with momentum (not instant)
- Cars pivot at couplings when the train enters a curve (visual)
- Train takes damage from enemies
- GUT tests for train physics behavior pass
- Train is fully playable with keyboard alone
- Additional: `train_renderer.gd`, `track_renderer.gd`, `ui_renderer.gd`, visual scene `main.tscn`

**Escalation Triggers:**

- Segment-to-segment traversal timing unclear (how long per segment?)
- Curve rotation animation: snap vs smooth interpolation
- Pivot angle calculation is mathematically complex (needs architect input)
- Pivot animation looks wrong or jittery

**Note — failure superseded by Task 4a:** The original approach of computing train and car position/orientation manually per segment type (straights, curves) produced persistent bugs: train spinning at curve entry, cars orbiting around the origin, and broken segment-to-segment transitions. The root cause was trying to manage geometry in both the movement and rendering code independently. Task 4a re-architects the system to separate data from presentation and movement (see below).

---

## Curve & Straight Alignment — Coordinate Model

A common failure mode when building a track-based train sim is getting the
transition between straight and curve segments wrong, causing the train to
leap off-track and cars to orbit erratically. The root cause is almost always
a mismatch between the coordinate systems used for different segment types.

### The coordinate model

The track uses a cell-based coordinate system:

- `CELL_SIZE = 64` pixels defines the grid cell width and height.
- Each segment's grid position `grid_position` (Vector2i) maps to world center
  `grid_position * CELL_SIZE`.
- Cell `(0,0)` center is at `(0, 0)`.
- Cell `(3,0)` center is at `(192, 0)`.
- A cell spans `[center_x - 32, center_x + 32]` horizontally and
  `[center_y - 32, center_y + 32]` vertically.
- Adjacent cells share boundaries: cell `(2,0)` right edge is at `x = 160`,
  which IS cell `(3,0)` left edge.

### Straight segments

A straight spans **edge-to-edge** within its cell — exactly `CELL_SIZE` pixels.

Position formula:

```gdscript
  center - exit_dir * 32 + exit_dir * progress * CELL_SIZE
```

- At `progress = 0`: `center - exit_dir * 32` → **entry edge** (where previous segment connects)
- At `progress = 1`: `center + exit_dir * 32` → **exit edge** (where next segment connects)
- Total travel distance: `CELL_SIZE = 64` pixels

Example: straight at grid `(2,0)` with exit direction RIGHT:

- Center: `(128, 0)`, exit_dir: `(1, 0)`
- Entry edge: `(128, 0) - (1, 0) * 32 = (96, 0)`
- Exit edge: `(128, 0) + (1, 0) * 32 = (160, 0)`

### Curve segments

A curve spans a **90° arc** within its cell, radius `CELL_SIZE / 2 = 32`,
centered on the curve cell's grid center.

- Arc center = curve cell grid center (`grid_position * CELL_SIZE`)
- Arc radius = `32`
- Entry angle = `atan2(connections[0].y, connections[0].x)`
- Exit angle = `atan2(connections[1].y, connections[1].x)`
- Arc spans from entry edge to exit edge (always ±90°)

Position formula:

```gdscript
  arc_center + Vector2(cos(entry_angle + diff * progress),
                       sin(entry_angle + diff * progress)) * 32
```

Example: curve at grid `(3,0)` with connections `[LEFT, DOWN]`:

- Arc center: `(192, 0)`, radius: `32`
- Entry angle: `atan2(0, -1) = π`
- Exit angle: `atan2(1, 0) = π/2`
- diff = `-π/2` (90° clockwise)
- Entry point at progress 0: `(192 + cos(π)*32, 0 + sin(π)*32) = (160, 0)` ← matches straight(2,0) exit ✓
- Exit point at progress 1: `(192 + cos(π/2)*32, 0 + sin(π/2)*32) = (192, 32)` ← matches straight(3,1) entry ✓

### Orientation on curves

The train's rotation interpolates along the arc:

```gdscript
  entry_angle + diff * segment_progress
```

This gives smooth heading changes through the curve.

### Travel direction on curves

The tangent direction at any point on the arc:

```gdscript
  Vector2(cos(angle), sin(angle))
  where angle = entry_angle + diff * segment_progress
```

### Why this works

The key: **straights and curves share cell edges as connection points.**

- Straight exit edge at `(160, 0)` = Curve entry point at `(160, 0)` ✓
- Curve exit point at `(192, 32)` = Straight entry edge at `(192, 32)` ✓

No gaps, no leaps. Every segment type uses `CELL_SIZE = 64` as the travel
distance within a cell. Straights travel linearly edge-to-edge; curves travel
along a radius-32 arc edge-to-edge. The shared edges are the gluing points.

### Common pitfalls to avoid

1. **Using `CELL_SIZE` as the arc radius** — should be `CELL_SIZE / 2 = 32`.
2. **Starting straight position at the cell center** — should start at the
   entry edge (`center - exit_dir * 32`).
3. **Offset-arc center tricks** — unnecessary complication. The arc is centered
   on the curve cell's grid center; the radius and angles handle everything.
4. **Treating `connections[0]` as the previous segment's direction** — it's the
   direction _from the curve cell center to the entry edge_, which is the
   direction the train enters the curve (the exit direction of the previous
   straight).

---

### Task 4a — Data Model (3-Level Normalized)

**Plan:** [`docs/superpowers/plans/2026-06-08-task-4a-data-model.md`](../docs/superpowers/plans/2026-06-08-task-4a-data-model.md)

**Description:** Implement the three-level normalized data model for track segments. Replace the flat `segments` array with CellData, Segment, and SegmentType layers. Implement rotation and entrance-pair math with 90° increments.

**Includes:**

- `cell_data.gd` (or dict in `track.gd`) — `Dictionary<Vector2i, int>` mapping grid position → segment_id
- `segment.gd` (Resource or struct) — `id: int`, `type_id: int`, `orientation: int` (0, 90, 180, 270)
- `segment_type.gd` (Resource) — `id: int`, `name: String`, `pattern: Array[Vector2i]`, `base_cost: float`, `entrance_pairs: Array[EntrancePair]`
- `entrance_pair.gd` (struct) — `cell: Vector2i`, `direction: String` (north/south/east/west)
- `segment_type_catalog.tres` — read-only catalog of all segment types (1x1 straight, 1x2 straight, 1x4 straight, 1x1 cross, 2x2 curve)
- Rotation utilities: `rotate_coord(coord, degrees)`, `rotate_direction(dir, degrees)`
- Connection validation: `is_connected(segment_a, segment_b)` checks adjacency and opposite entrance directions
- GUT tests for rotation math, entrance mapping, and connection validation

**Acceptance Criteria:**

- Segment type catalog loads as a `.tres` resource at game start
- Rotation math works correctly for all 4 rotations (0°, 90°, 180°, 270°)
- Entrance pair mapping (local → rotated → data coords) produces correct results
- Connection validation correctly identifies adjacent segments with opposite entrance directions
- All new data model classes are independent of rendering/movement
- GUT tests for rotation, entrance mapping, and connection validation pass

**Escalation Triggers:**

- GDScript `Dictionary<Vector2i, int>` has performance issues for large grids
- Rotation math produces inconsistent results for edge cases
- Segment type resource format is unclear for Godot 4.x

---

### Task 4b — Track Path Builder

**Plan:** [`docs/superpowers/plans/2026-06-08-task-4b-path-builder.md`](../docs/superpowers/plans/2026-06-08-task-4b-path-builder.md)

**Description:** Build `track_path_builder.gd` to generate a Godot `Path2D` node from the three-level data model. The path builder groups cells by segment_id, looks up type + orientation, and generates the correct path geometry for each segment type.

**Includes:**

- `track_path_builder.gd` — `build_path(track: Track) -> Path2D`
- Straight path: `line_to()` from first cell center to last cell center
- 1x1 curve path: `curve_to()` with 90° arc (radius 32, centered on curve's grid cell)
- 2x2 curve path: `curve_to()` with 90° arc (radius 64, centered at the 2x2 block's inner corner)
- Cross path: two overlapping paths; path builder follows one path through (game logic determines direction)
- Segment ordering: traverse connected segments in order (start → end) to build continuous path
- Validation: path length > 0, no discontinuities at segment boundaries
- GUT tests for path geometry correctness (straight, curve, cross)

**Acceptance Criteria:**

- `Path2D` is generated correctly for a single segment of each type in isolation
- `Path2D` is continuous for a track with multiple connected segments (straight → curve → straight)
- Path direction matches the track's logical flow (start to end)
- Path length equals the sum of individual segment lengths
- GUT tests for path geometry and continuity pass
- No manual per-segment position/rotation math — path builder reads data model only

**Escalation Triggers:**

- `Curve2D` API for arcs is complex or produces unexpected results
- Segment ordering (start → end) is ambiguous for tracks with branches or loops
- Path continuity fails at certain segment type combinations

---

### Task 4c — Renderer Update

**Plan:** [`docs/superpowers/plans/2026-06-08-task-4c-renderer-update.md`](../docs/superpowers/plans/2026-06-08-task-4c-renderer-update.md)

**Description:** Update `track_renderer.gd` to draw from the data model directly in PlaceMode. The renderer reads CellData and Segment tables to determine what to draw at each grid position. Supports preview graphics, ghost segments, and entrance markers.

**Includes:**

- `track_renderer.gd` — `draw()` iterates CellData, looks up Segment → SegmentType, and draws appropriate graphic
- PlaceMode drawing: grid cells with segment graphics, preview (ghost) of next segment, entrance markers at open ends
- GameMode drawing: same as PlaceMode (no change — renderer always reads from data model)
- Segment type lookup: `segment_id` → `Segment` → `SegmentType` → graphic + orientation
- Placement validation visual: show valid/invalid placement spots during preview
- `main.tscn` — update scene to use new renderer
- GUT tests for renderer data model integration (can draw a single segment from data)

**Acceptance Criteria:**

- Renderer draws correct graphics for all segment types from the data model
- Preview (ghost) shows where the next segment will be placed
- Entrance markers indicate where new segments can connect
- Rendering works in both PlaceMode and GameMode (no mode-specific code)
- GUT tests for renderer integration pass

**Escalation Triggers:**

- Renderer performance degrades with many segments (needs batching)
- Preview positioning doesn't align with grid cells
- Godot `CanvasItem.draw_*` API is insufficient for preview effects

---

### Task 4d — Train Migration to PathFollow2D

**Plan:** [`docs/superpowers/plans/2026-06-08-task-4d-train-migration.md`](../docs/superpowers/plans/2026-06-08-task-4d-train-migration.md)

**Description:** Migrate `train.gd` from manual segment-by-segment movement to Godot's `Path2D`/`PathFollow2D` system. The train's engine is a `PathFollow2D` that follows the path generated by Task 4b. Cars follow the same path at offset distances based on coupling length.

**Includes:**

- `train.gd` — replace manual position math with `PathFollow2D.progress` for engine position
- `PathFollow2D` setup: add to scene tree, attach to `Path2D`, set `rotate_automatically = true`
- Engine movement: `progress += speed * delta` along path
- Car movement: each car has its own `PathFollow2D` on the same path, offset by coupling distance
- Car coupling: car's `progress = engine.progress - coupling_offset` (with wrapping for path length)
- Bogie/pivot: cars rotate around their coupling point using `PathFollow2D`'s automatic rotation
- Mode switch: at PlaceMode → GameMode, build Path2D, set train's progress based on current position, no jump
- GUT tests for mode-switch invariant (train position unchanged at mode switch)
- GUT tests for car coupling offsets

**Acceptance Criteria:**

- Train engine moves smoothly along the generated Path2D
- Train orientation matches path tangent at all points (no manual rotation math)
- Cars follow the path behind the engine at correct coupling distances
- **Mode-switch invariant:** Train and cars maintain exact position and state when switching PlaceMode → GameMode
- No manual per-segment position/rotation math for curves
- GUT tests for mode-switch invariant and car coupling pass

**Escalation Triggers:**

- `PathFollow2D` progress offset for cars causes jitter or drifting
- `PathFollow2D` rotation doesn't match expected train heading
- Mode-switch causes visible train position jump despite progress recalculation
- Path length wrapping for car offsets produces incorrect positions

---

### Task 5 — Train Demo Track & Controls

**Description:** Set up a demo track showing all segment types (straight, curve, crossing) with a train that starts moving at approximately 6.4 units/s (covering the track in ~10 seconds), responds to keyboard input (W/Up = speed up, S/Down = slow down), supports reverse mode toggling with R, and has 3 attached cars.

**Includes:**

- **Example track** (`_place_initial_track()` in `main.gd`): Build a linear track (start → end) using at least one straight segment, one curve segment, and one crossing segment. The train path must go through all segment types and terminate at a clear end point.
- **Train movement** (`train.gd`, `main.gd`): Initialize train at `speed = 6.4` units/s and `max_speed = 20.0` (covers ~640-unit track in ~10 seconds). Train auto-moves along the path from game start. When the train reaches the end of the path, it comes to a dead stop (`speed = 0`).
- **Keyboard controls** (`main.gd`, `train.gd`): W key or Up Arrow = throttle (speed up). S key or Down Arrow = brake (slow down). Speed never goes below 0.
- **Reverse mode** (`train.gd`): Add `is_reversed: bool = false` flag. When train is stopped (`speed == 0`), pressing R toggles between forward (`is_reversed = false`) and reverse (`is_reversed = true`). When reversed, W/Up moves the train backward along the path (decreasing progress), S/Down moves it forward (increasing progress). R only toggles when `speed == 0`.
- **3 cars**: `main.gd` already adds 3 cars (utility, weapon, cargo) — confirmed present and functional.
- **Scene update** (`main.tscn`): No structural changes needed — same renderer nodes, just different initial state.

**Acceptance Criteria:**

- Game starts with a visible track containing straights, curves, and a crossing segment
- Train starts moving at ~6.4 units/s, covers the entire track in ~10 seconds
- Train comes to a complete stop at the end of the track
- W/Up accelerates the train, S/Down decelerates it
- When stopped, pressing R toggles reverse mode (visual indicator shown)
- In reverse mode, W/Up moves train backward along the path, S/Down moves forward
- 3 cars are attached and move correctly in both directions
- All path types (straight, curve, crossing) produce correct train pathing in both directions
- (Manual testing — GUT tests for reverse mode logic in `train.gd`)

**Escalation Triggers:**

- Track geometry doesn't produce a clean start-to-end path
- Reverse mode causes position jumps at segment transitions
- Cars don't follow correctly in reverse direction
- Train doesn't stop cleanly at the end of the path

---

### Task 6 — Switch to G.U.I.D.E Input Layer

**Description:** Replace the current InputManager (Godot InputMap-based) with G.U.I.D.E as the sole input abstraction layer. Configure both keyboard and gamepad bindings.

**Includes:**

- **GUIDE mapping context resource**: Create `mapping_contexts/gameplay.tres` (GUIDEMappingContext) with the following action mappings:
  - `throttle` action: W key + Up Arrow (keyboard) + Right Trigger (gamepad)
  - `brake` action: S key + Down Arrow (keyboard) + Left Trigger (gamepad)
  - `reverse_toggle` action: R key (keyboard) + X button (gamepad)
  - All bindings use GUIDEInputKey for keyboard and GUIDEInputJoyButton / GUIDEInputJoyAxis1D for gamepad
  - Triggers are treated as on/off (binary), not analog — same behavior as keyboard
- **Enable GUIDE addon**: Enable the GUIDE plugin in `project.godot` autoload section
- **Replace InputManager** (`main.gd`): Swap `InputManager` for GUIDE actions:
  - Replace `input_manager.get_throttle()` with `throttle_action.is_triggered()` (or `is_down()`)
  - Replace `input_manager.get_brake()` with `brake_action.is_triggered()`
  - Add reverse toggle: `reverse_toggle_action.just_triggered().connect(_toggle_reverse)`
- **Remove old input files**: Delete `input_manager.gd`, `input_action.gd`, `input_boot.gd` (no longer needed)
- **Scene update** (`main.tscn`): Export `throttle_action`, `brake_action`, `reverse_toggle_action` from the game script, wire them in the scene

**Acceptance Criteria:**

- GUIDE addon is enabled in project.godot as an autoload plugin
- Keyboard input (W, S, Up, Down, R) works identically to the previous InputManager
- Gamepad input works: Right Trigger = throttle, Left Trigger = brake, X button = reverse toggle
- Triggers act as binary on/off (not analog) — equivalent to pressing a keyboard key
- InputManager, InputAction, InputBoot classes are removed
- All existing functionality preserved (throttle, brake, reverse toggle, 3 cars, demo track)
- (Manual testing — no GUT tests needed for input hardware)

**Escalation Triggers:**

- G.U.I.D.E API unclear or undocumented for throttle/brake mapping
- G.U.I.D.E conflicts with Godot's built-in input system
- Controller feels unresponsive or too sensitive
- GUIDE context resource format unclear (must use .tres files in `mapping_contexts/` folder)

---

### Task 7 — Car System & Auto-Fire

**Description:** Train cars that auto-aim and auto-fire at enemies, plus utility cars for non-combat bonuses.

**Includes:**

- `car.gd` — car entity with type, category (Weapon/Utility), level, targeting_mode
- `car_weapon.gd` — weapon behavior (fire rate, damage, auto-aim logic, targeting mode)
- `car_utility.gd` — utility bonus behavior (speed, power, capacity)
- Cars attach to train
- Weapon cars auto-aim at enemies based on targeting mode (nearest, farthest, healthiest, weakest)
- Targeting mode is set when the car is acquired (not toggleable during gameplay)
- Utility cars provide passive bonuses
- At least 2 weapon types (e.g., cannon, machine gun) and 2 utility types (e.g., booster, cargo)

**Acceptance Criteria:**

- Weapon cars auto-aim and fire at enemies based on targeting mode
- Different weapon types have different fire rates and damage
- Different targeting modes select different enemies correctly
- Utility cars apply passive bonuses (speed, power, etc.)
- Cars can be upgraded (level system)
- GUT tests for weapon auto-aim, targeting modes, damage, and utility bonus calculations

**Escalation Triggers:**

- Auto-aim logic unclear (line of sight? range limit?)
- Car attachment to train positioning unclear
- Utility bonus stacking/interaction unclear

---

### Task 8 — Enemy Spawning & Movement

**Description:** Enemies spawn in waves and move toward the train.

**Includes:**

- `enemy.gd` — enemy entity with health, speed, type, behavior
- Enemy spawning system (waves or continuous)
- Enemies move toward the train
- At least 2 enemy types (basic + special)
- Special enemies drop chests on death

**Acceptance Criteria:**

- Enemies spawn at intervals or in waves
- Enemies move toward the train's position
- Basic enemies have lower health/speed than special enemies
- Special enemies are marked for chest drops
- GUT tests for spawn timing and enemy stats

**Escalation Triggers:**

- Enemy movement path around obstacles unclear
- Wave timing feels bad during manual testing

---

### Task 9 — Projectile System

**Description:** Projectiles from cars that travel and hit enemies.

**Includes:**

- `projectile.gd` — projectile entity with speed, damage, lifetime
- Projectiles travel from car toward target
- Collision with enemies deals damage
- Projectiles expire after lifetime or off-screen

**Acceptance Criteria:**

- Projectiles spawn from cars and travel toward targets
- Projectiles deal damage on hit
- Projectiles expire appropriately (lifetime or off-screen)
- GUT tests for projectile damage and collision

**Escalation Triggers:**

- Projectile collision detection needs physics system changes
- Performance issues with many projectiles

---

### Task 10 — Damage, Death & XP

**Description:** Enemies die when health reaches zero, dropping XP/money. Train dies when health reaches zero.

**Includes:**

- Enemy death on zero health (remove from scene, spawn XP pickup)
- XP/money collection: hover over XP pickups to collect (mouse or right analog stick via G.U.I.D.E)
- Train health display and death condition
- Game over state when train is destroyed: pop up a dialog box with metrics
- Game over: enemies continue in slow motion (1/4 speed) in the background

**Acceptance Criteria:**

- Enemies drop XP on death
- XP is collected by hovering over it (mouse or right analog stick)
- Train shows health; when zero, game over dialog appears with metrics
- Enemies slow to 1/4 speed after game over (background ambiance)
- GUT tests for damage calculation and XP accumulation

**Escalation Triggers:**

- Right analog stick as mouse needs G.U.I.D.E integration research
- Game over metrics to display unclear (what stats to show?)

---

### Task 11 — Upgrade Picker

**Description:** When player earns enough XP, present upgrade choices.

**Includes:**

- `upgrade.gd` — upgrade definitions (id, name, effect, value)
- `upgrade_picker.gd` — upgrade choice UI and selection logic
- Upgrade thresholds (e.g., every 100 XP)
- 3 upgrade options presented at a time
- Upgrade effects: improve car, add car, extend track

**Acceptance Criteria:**

- Upgrade picker appears at XP thresholds
- Player chooses from 3 options
- Selected upgrade is applied immediately
- Upgrades persist across saves
- GUT tests for upgrade selection and application

**Escalation Triggers:**

- Upgrade balance unclear (which upgrades are too strong/weak)
- Picker UI timing during gameplay feels disruptive

---

### Task 12 — Chest Drops

**Description:** Special enemies drop chests with pre-selected rewards.

**Includes:**

- `chest.gd` — chest entity, appears on special enemy death
- Chests contain pre-selected upgrades (not random)
- Chests can be collected for immediate reward

**Acceptance Criteria:**

- Special enemies drop a chest on death
- Chest contains a pre-selected upgrade
- Chest is collectible (proximity or interaction)
- GUT tests for chest drop logic

**Escalation Triggers:**

- Pre-selected reward logic unclear (how to determine the reward)

---

### Task 13 — Save System

**Description:** Save and load full game state.

**Includes:**

- `save_system.gd` — serialize/deserialize GameState
- Auto-save on quit
- Resume from save
- Save file management (slots or single save)

**Acceptance Criteria:**

- Game state is fully saved (track, train, cars, enemies, upgrades, resources)
- Quitting the game saves the state
- Loading a save restores the game to the saved state
- GUT tests for save/load round-trip (save → load → compare)

**Escalation Triggers:**

- Godot serialization of complex nested objects fails
- Save file format needs versioning for future compatibility

---

### Task 14 — Settings

**Description:** Settings management split between machine-specific and universal.

**Includes:**

- `settings.gd` — settings storage and loading
- Machine-specific: resolution, volume, fullscreen
- Universal: language, difficulty
- Settings persist across sessions

**Acceptance Criteria:**

- Settings are saved and loaded correctly
- Machine-specific and universal settings are separated
- Settings apply immediately when changed
- GUT tests for settings persistence

**Escalation Triggers:**

- Godot's `ConfigFile` vs `Resource` for settings unclear

---

### Task 15 — UI Overlay & Story Text

**Description:** HUD, upgrade picker UI, story text delivery, translation-ready text system. V1 story is flavor lines only (no narrative beats).

**Includes:**

- `ui.gd` — HUD overlay (health, speed, resources, phase indicator)
- `text_manager.gd` — translation-ready text system (key-based)
- `story_manager.gd` — story text delivery (flavor lines for V1)
- Basic placeholder graphics for entities
- Upgrade picker visual (reusable from Task 9)

**Acceptance Criteria:**

- HUD shows health, speed, resources, current phase
- Story text appears as flavor lines at appropriate moments (no narrative beats in V1)
- All text uses translation keys (not hardcoded strings)
- Upgrade picker is visually functional
- GUT tests for text key resolution

**Escalation Triggers:**

- Translation system needs a CSV/JSON file format decision

---

### Task 16 — Audio

**Description:** Basic sound effects for key events.

**Includes:**

- `audio_manager.gd` — sound effect management
- Basic SFX: fire, hit, death, upgrade, chest open
- Volume control (from settings)

**Acceptance Criteria:**

- Sound effects play at appropriate moments
- Volume control works
- Audio doesn't interfere with gameplay performance
- (No GUT tests for audio — manual verification only)

**Escalation Triggers:**

- Audio file format or loading approach unclear

---

### Task 17 — Build Targets

**Description:** Configure Godot export presets for macOS, Linux, Windows, and WASM.

**Includes:**

- Export preset for macOS (universal or arm64)
- Export preset for Linux (x86_64)
- Export preset for Windows (x86_64)
- Export preset for WASM (web export)
- Verify each export builds successfully in headless mode
- WASM build is small enough for GitHub Pages (< 10MB if possible)

**Acceptance Criteria:**

- `godot --headless --export-debug "macOS" build/macos/survive-the-rail.app` succeeds
- `godot --headless --export-debug "Linux/X11" build/linux/survive-the-rail` succeeds
- `godot --headless --export-debug "Windows Desktop" build/windows/survive-the-rail.exe` succeeds
- `godot --headless --export-debug "Web" build/web/index.html` succeeds
- WASM page loads in browser and runs the game
- `build/` is in `.gitignore`
- (Manual testing: each binary launches and renders correctly)

**Escalation Triggers:**

- Godot web export fails with required features (file access, threading)
- Export preset configuration is unclear for a target platform

---

### Task 18 — CI/CD Pipeline

**Description:** GitHub Actions for automated builds and WASM auto-deploy to GitHub Pages.

**Includes:**

- `.github/workflows/build.yml` — CI pipeline
- Build macOS, Linux, Windows binaries on push/PR
- Build WASM and auto-deploy to GitHub Pages on main branch
- Artifacts for desktop binaries (attached to release)
- GUT headless test run on every PR
- Trunk lint check on every PR

**Acceptance Criteria:**

- PR triggers: GUT tests + trunk lint + all 4 export builds
- Push to main: WASM auto-deploys to GitHub Pages
- Desktop binaries are available as release artifacts
- Pipeline fails clearly when tests or builds fail
- Local `mise install` + `trunk check` + `godot --headless --test` mirrors CI

**Escalation Triggers:**

- GitHub Pages deployment permissions unclear
- CI runner doesn't have Godot export templates
- WASM deployment needs custom domain or path

---

### Task 19 — Polish Pass (Ongoing)

**Description:** Code cleanup, refactoring for clarity, performance measurements, Godot version bump, friend playtesting feedback.

**Includes:**

- Refactor for SOLID principles and readability
- Remove dead code and simplify where possible
- Performance measurements: frame rate, memory, WASM load time
- Godot version bump if a newer stable version is available
- Address friend/family feedback
- Performance optimization if needed

**Acceptance Criteria:**

- Code is clean, simple, and follows SOLID
- No regressions from previous tasks
- Performance metrics recorded (FPS, memory, WASM load time)
- Friend feedback is triaged (addressed or filed for later)
- All GUT tests still pass after refactoring

**Escalation Triggers:**

- Refactoring introduces bugs
- Godot version bump breaks dependencies (GUT, G.U.I.D.E)
- Performance issues can't be isolated

---

## Summary

| Task | Description                     | Depends On | Testable?                                     |
| ---- | ------------------------------- | ---------- | --------------------------------------------- |
| 1    | Project setup                   | —          | Yes (headless Godot, mise, trunk)             |
| 2    | Physics system                  | —          | Yes (GUT)                                     |
| 2a   | Physics polish & hygiene        | 2          | Yes (GUT)                                     |
| 3    | Track laying                    | 2a         | Yes (GUT + manual)                            |
| 4    | Train controls (keyboard)       | 2, 3       | Yes (GUT + manual) (superseded in part by 4a) |
| 4a   | Data Model (3-level normalized) | 2, 3, 4    | Yes (GUT: rotation, entrance, connection)     |
| 4b   | Track Path Builder              | 4a         | Yes (GUT: path geometry, continuity)          |
| 4c   | Renderer Update                 | 4a         | Yes (GUT: renderer integration)               |
| 4d   | Train Migration to PathFollow2D | 4b, 4c     | Yes (GUT: mode-switch invariant, coupling)    |
| 5    | Train demo track & controls     | 4d         | Yes (GUT + manual)                            |
| 6    | Switch to G.U.I.D.E input       | 5          | Yes (manual)                                  |
| 7    | Car auto-fire                   | 2, 5       | Yes (GUT)                                     |
| 8    | Enemy spawning                  | 2          | Yes (GUT + manual)                            |
| 9    | Projectiles                     | 2, 7       | Yes (GUT)                                     |
| 10   | Damage & XP                     | 2, 8, 9    | Yes (GUT)                                     |
| 11   | Upgrade picker                  | 10         | Yes (GUT)                                     |
| 12   | Chest drops                     | 8, 10      | Yes (GUT)                                     |
| 13   | Save system                     | 10, 11     | Yes (GUT)                                     |
| 14   | Settings                        | 13         | Yes (GUT)                                     |
| 15   | UI & story                      | 5, 7, 11   | Partial (GUT for text keys)                   |
| 16   | Audio                           | 15         | No (manual)                                   |
| 17   | Build targets                   | 16         | Yes (headless export)                         |
| 18   | CI/CD pipeline                  | 17         | Yes (CI runs)                                 |
| 19   | Polish (ongoing)                | 1-18       | No (refactoring)                              |
