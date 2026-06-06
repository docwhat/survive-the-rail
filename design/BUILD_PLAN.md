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

### Task 4 — Train Controls (Keyboard)

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

**Escalation Triggers:**

- Segment-to-segment traversal timing unclear (how long per segment?)
- Curve rotation animation: snap vs smooth interpolation
- Pivot angle calculation is mathematically complex (needs architect input)
- Pivot animation looks wrong or jittery

---

### Task 5 — Train Controls (G.U.I.D.E + Controllers)

**Description:** Extend train input to support controllers via G.U.I.D.E.

**Includes:**

- Integrate G.U.I.D.E for input abstraction
- Controller mapping for throttle/brake
- Keyboard input still works (G.U.I.D.E fallback or dual support)
- Verify controller input feels right (dead zones, sensitivity)

**Acceptance Criteria:**

- G.U.I.D.E is installed and configured in the project
- Controller throttle/brake input works
- Keyboard input still works alongside G.U.I.D.E
- Controller dead zones and sensitivity are reasonable
- (Manual testing — no GUT tests needed for input hardware)

**Escalation Triggers:**

- G.U.I.D.E API unclear or undocumented for throttle/brake mapping
- G.U.I.D.E conflicts with Godot's built-in input system
- Controller feels unresponsive or too sensitive

---

### Task 6 — Car System & Auto-Fire

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

### Task 7 — Enemy Spawning & Movement

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

### Task 8 — Projectile System

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

### Task 9 — Damage, Death & XP

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

### Task 10 — Upgrade Picker

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

### Task 11 — Chest Drops

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

### Task 12 — Save System

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

### Task 13 — Settings

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

### Task 14 — UI Overlay & Story Text

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

### Task 15 — Audio

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

### Task 16 — Build Targets

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

### Task 17 — CI/CD Pipeline

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

### Task 18 — Polish Pass (Ongoing)

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

| Task | Description                | Depends On | Testable?                         |
| ---- | -------------------------- | ---------- | --------------------------------- |
| 1    | Project setup              | —          | Yes (headless Godot, mise, trunk) |
| 2    | Physics system             | —          | Yes (GUT)                         |
| 2a   | Physics polish & hygiene   | 2          | Yes (GUT)                         |
| 3    | Track laying               | 2a         | Yes (GUT + manual)                |
| 4    | Train controls (keyboard)  | 2, 3       | Yes (GUT + manual)                |
| 5    | Train controls (G.U.I.D.E) | 4          | Yes (manual)                      |
| 6    | Car auto-fire              | 2, 4       | Yes (GUT)                         |
| 7    | Enemy spawning             | 2          | Yes (GUT + manual)                |
| 8    | Projectiles                | 2, 6       | Yes (GUT)                         |
| 9    | Damage & XP                | 2, 7, 8    | Yes (GUT)                         |
| 10   | Upgrade picker             | 9          | Yes (GUT)                         |
| 11   | Chest drops                | 7, 10      | Yes (GUT)                         |
| 12   | Save system                | 9, 10      | Yes (GUT)                         |
| 13   | Settings                   | 12         | Yes (GUT)                         |
| 14   | UI & story                 | 4, 6, 10   | Partial (GUT for text keys)       |
| 15   | Audio                      | 14         | No (manual)                       |
| 16   | Build targets              | 15         | Yes (headless export)             |
| 17   | CI/CD pipeline             | 16         | Yes (CI runs)                     |
| 18   | Polish (ongoing)           | 1-17       | No (refactoring)                  |
