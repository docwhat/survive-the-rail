# Architecture

> App structure, data model, risks, and any other decisions about the project.

## Tech Stack

| Layer         | Technology                                             |
| ------------- | ------------------------------------------------------ |
| Engine        | Godot (latest stable)                                  |
| Build Targets | macOS, Linux, Windows, WASM (GitHub Pages auto-deploy) |
| Language      | GDScript                                               |
| Input         | G.U.I.D.E (auto-fire + train controls)                 |
| Testing       | GUT (unit tests for rules)                             |
| Console       | godot-console                                          |
| Tool Mgmt     | mise (mise.toml)                                       |
| Linting       | trunk (external to Godot)                              |

## File Structure

Flat structure (add directories only when complexity demands it):

```
project/
├── main.gd              # Entry point, scene manager
├── game_state.gd        # Central state machine (track-lay → play → upgrade → game-over)
├── track_segment.gd     # Track segment: type (straight/curve), orientation, graphic, collision
├── track.gd             # Track laying, segment placement, grid snapping, path validation
├── train.gd             # Train entity: position, speed, acceleration, momentum
├── car.gd               # Train car: type, weapon, fire rate, damage
├── car_weapon.gd        # Weapon behavior: auto-fire logic, projectile spawning
├── enemy.gd             # Enemy entity: health, speed, type, behavior
├── obstacle.gd          # Obstacle entity: health, position on track
├── upgrade.gd           # Upgrade definitions and application
├── upgrade_picker.gd    # Upgrade choice UI and selection
├── chest.gd             # Chest entity, drops on special enemy death
├── projectile.gd        # Projectile entity
├── physics.gd           # Simple physics: collisions, momentum, elastic pushes
├── save_system.gd       # Save/load game state
├── settings.gd          # Settings management (machine vs universal)
├── ui.gd                # UI overlay: HUD, upgrade picker, text
├── text_manager.gd      # Translation-ready text system
├── audio_manager.gd     # Sound effects management
├── story_manager.gd     # Story text delivery
├── project.godot        # Godot project file
├── mise.toml            # Tool version management
├── trunk.toml           # Trunk linting config
├── test/                # GUT tests (flat for now)
│   ├── test_physics.gd
│   ├── test_upgrade.gd
│   ├── test_enemy.gd
│   └── ...
└── README.md
```

## Data Model

### TrackSegment

```
TrackSegment {
    segment_type: string      # "straight", "curve_left", "curve_right"
    orientation: int          # 0, 1, 2, 3 (4 cardinal directions)
    grid_position: Vector2i   # Position on the placement grid
    graphic: Texture2D        # Fixed graphic asset for this segment type + orientation
    collision_shape: Shape2D  # Collision shape matching the visual
}
```

### GameState

```
GameState {
    phase: TrackLay | Playing | Upgrading | GameOver
    resources: float          # XP/money
    track_segments: Array[TrackSegment]
    track_start: Vector2i     # Train yard starting point (fixed)
    train: Train
    cars: Array[Car]
    enemies: Array[Enemy]
    obstacles: Array[Obstacle]
    projectiles: Array[Projectile]
    chests: Array[Chest]
    upgrades_available: Array[Upgrade]
    upgrades_applied: Array[Upgrade]
    max_track_length: int
    story_index: int
}
```

### Train

```
Train {
    position: Vector2
    speed: float              # Current speed
    max_speed: float
    acceleration: float       # Base acceleration (engine power)
    deceleration: float       # Base braking force
    momentum: float           # Current momentum (speed * total_weight)
    total_weight: float       # Sum of all car weights (affects acceleration/braking)
    engine_power: float       # Fixed engine output (doesn't scale with cars)
    health: float
    max_health: float
}
```

### Car

```
Car {
    car_type: string          # "cannon", "machine_gun", "booster", "cargo", etc.
    car_category: Weapon | Utility
    weight: float             # How much this car adds to train weight
    weapon: CarWeapon?        # Only for Weapon category
    utility_bonus: float?     # Only for Utility category (speed, power, capacity)
    level: int                # Upgrade level
    health: float
    bogie_offset: Vector2     # Pivot point offset from car center (represents bogie position)
    body_rotation: float      # Car body rotation around bogie pivot (2D)
}

### Upgrade
```

Upgrade {
id: string
name: string # Translation key
description: string # Translation key
effect: UpgradeEffect # Enum: improve_weapon_car, add_weapon_car, improve_utility_car, add_utility_car, extend_track, change_targeting_mode, etc.
target_car: string? # Which car to improve/change (if applicable)
value: float # Magnitude of effect
targeting_mode: string? # New targeting mode (nearest, farthest, healthiest, weakest)
}

```

### Settings
```

Settings {
machine: {
resolution: Vector2i
volume: float
fullscreen: bool
...
}
universal: {
language: string
difficulty: string
...
}
}

```

## Core Systems

### 1. Track System
- Track is made of discrete segments (like a child's train set)
- Segment types: straight, curved (left/right), possibly diagonal later
- Each segment type has a fixed graphic asset and fixed orientation
- Track starts at a fixed train yard starting point
- Track must be continuous — new segments can only be added from the current track end
- Player places segments in track-lay phase, snapping to a grid
- The field is infinite; max track length is the only boundary
- Track defines the path; train moves segment-by-segment
- Track has a max length (upgradable)
- Obstacles can be placed on track segments

### 2. Train Physics & Movement
- Simple physics: speed, acceleration, momentum, force (all 2D)
- Throttle increases speed, brakes decrease
- Momentum prevents instant stops
- **Weight scaling:** As cars are added, the train feels heavier:
  - More cars = slower acceleration (engine works harder)
  - More cars = longer braking distance (more momentum to stop)
  - Engine-only train: snappy acceleration and braking
  - Full train: sluggish, powerful, hard to stop
  - This is a core gameplay feel — players should feel the weight
- Train moves segment-by-segment along the track
- **Bogie/pivot animation (2D):** Cars rotate around a pivot point offset from center:
  - Each car has a pivot offset (representing bogie position, near front/back)
  - When the train enters a curve, the car body rotates around this offset point
  - Simulates the bogie pivot effect in 2D — car body angles relative to the track
  - Visual only; physics still follow track segments
  - Not as rich as 3D, but conveys the mechanic without complexity
- Train rotation snaps to segment orientation (easier animation)
- Collisions with enemies/obstacles: configurable elastic or inelastic (all 2D)
  - Elastic: enemies/obstacles fly off screen (comedic effect — goblins flying, crates spinning)
  - Inelastic: enemies/obstacles get pushed along with the train
  - Choice per enemy/obstacle type or per encounter

### 3. Track Segments (Graphic Assets)
Fixed set of segment graphics — no procedural track art:
- Straight (1): forward-facing
- Curved Left (1): 90° turn left
- Curved Right (1): 90° turn right
- Total: 3 base segment graphics (can be mirrored/rotated for direction)
- Each segment has a collision shape matching its visual

### 4. Car System
- Cars attach to the train and come in two categories:
  - **Weapon cars** — auto-aim and auto-fire at enemies (G.U.I.D.E handles input mapping for throttle/brakes)
    - Each weapon type has different fire rate, damage, range
    - Targeting mode is set when the car is acquired (not toggleable during gameplay)
    - Targeting modes: nearest, farthest, healthiest, weakest — chosen via upgrades
  - **Utility cars** — provide non-combat bonuses (speed, power, capacity, health)
- Upgrades can improve existing cars, add new cars, or change targeting modes

### 5. Enemy System
- Enemies spawn in waves or continuously
- Different enemy types with varying health/speed
- Special enemies drop chests on death
- Enemies push obstacles, can be pushed by train

### 6. Upgrade System
- XP/money collected from kills
- At thresholds, present upgrade choices (3 options)
- Chests give pre-selected rewards
- Upgrades affect cars, track capacity, or train stats

### 7. Save System
- Full game state serialization
- Auto-save on quit
- Resume from save point
- Settings split: machine-specific vs universal

### 8. Text/Story System
- All text uses translation keys
- Story delivered through text_manager
- Beginnings of narrative woven into gameplay

## References & Inspiration

- **Vampire Survivors** — auto-fire, upgrade choices, wave survival
- **Queble — "Complex (yet modular) weapon system"** — https://youtu.be/a5GJcgdSEQo?si=AilvTcwI7jGYIXXA
  - Modular weapon architecture for car weapons
  - Study for upgradeable weapon components and effects

## Risks & Unknowns

1. **G.U.I.D.E compatibility** — Need to verify it works with Godot's input system for throttle/brake mapping
2. **GUT for Godot** — GUT is mature but need to confirm it works well with GDScript for game rule testing
3. **godot-console** — Verify it's maintained and compatible with latest Godot
4. **Physics simplicity** — Elastic collisions between train and enemies need tuning for feel
5. **Track path following** — How the train follows placed track (linear, spline, etc.) needs design
6. **Save serialization** — Godot's `to_json()` / `Serialization` for complex game state
7. **WASM build** — Godot's web export may have limitations with certain features (file access, threading)
8. **Cross-platform builds** — CI needs to produce binaries for 3 desktop OSes + WASM
9. **Performance on WASM** — JavaScript VM performance may differ from native; profiling needed

## Design Decisions

- Flat file structure for V1; add directories when complexity demands
- SOLID principles in all GDScript code
- GUT tests for game rules (physics, upgrades, enemy spawning)
- Minimal manual testing; maximize automated tests
- Translation-ready text from day one
- Placeholder art/audio that an artist/musician can replace later
- **Targeting mode is not toggleable during gameplay.** Players cannot cycle through targeting modes (nearest, farthest, healthiest, weakest) while playing. The fantasy is "I drive the train, the cars handle combat." Letting players toggle targeting mid-fight breaks that fantasy with a menu action. Targeting modes are chosen once when a car is acquired via the upgrade system, and can be changed by replacing the car through an upgrade.
```
