# Test Plan

> A description of how we prove the app works as expected.

## Testing Philosophy

- **Automated tests first:** GUT tests for all deterministic game rules (physics, upgrades, damage, XP).
- **Minimal manual testing:** Only for things that can't be automated (UI feel, audio, controls).
- **Per-task acceptance:** Each BUILD_PLAN task has its own test criteria. No task is done until its tests pass.
- **Refactor safety:** After refactoring, all existing tests must still pass.

## Test Categories

### 1. GUT Unit Tests (Automated, Deterministic)

These tests verify game rules in isolation, without scenes or rendering.

| System           | What to Test                                                  | File                   |
| ---------------- | ------------------------------------------------------------- | ---------------------- |
| **Physics**      | Collision detection, elastic push force, momentum calculation | `test_physics.gd`      |
| **Track**        | Valid/invalid placement, overlap detection, bounds checking   | `test_track.gd`        |
| **Train**        | Acceleration/deceleration, speed limits, momentum behavior    | `test_train.gd`        |
| **Car Weapon**   | Targeting logic (nearest enemy), fire rate, damage output     | `test_car_weapon.gd`   |
| **Enemy**        | Health calculation, death threshold, XP drop amount           | `test_enemy.gd`        |
| **Projectile**   | Damage on hit, lifetime expiry, collision resolution          | `test_projectile.gd`   |
| **Upgrade**      | Upgrade selection, effect application, stacking behavior      | `test_upgrade.gd`      |
| **Chest**        | Drop on special enemy death, pre-selected reward logic        | `test_chest.gd`        |
| **XP/Resource**  | Accumulation, threshold triggers for upgrades                 | `test_xp.gd`           |
| **Save/Load**    | Round-trip serialization (save → load → compare state)        | `test_save.gd`         |
| **Settings**     | Persistence, machine vs universal separation                  | `test_settings.gd`     |
| **Text Manager** | Key resolution, missing key handling                          | `test_text_manager.gd` |

### 2. Integration Tests (Automated, Semi-Deterministic)

These tests verify systems working together.

| Integration             | What to Test                                          | Approach                  |
| ----------------------- | ----------------------------------------------------- | ------------------------- |
| **Track + Train**       | Train follows placed track, respects track boundaries | Headless Godot test scene |
| **Train + Physics**     | Train pushes enemies with correct force               | Headless test scene       |
| **Car + Enemy**         | Auto-fire hits enemies, deals correct damage          | Headless test scene       |
| **Damage + Upgrade**    | Upgrades affect damage output correctly               | Headless test scene       |
| **XP + Upgrade Picker** | Upgrade choices appear at correct thresholds          | Headless test scene       |

### 3. Manual Test Cases (Minimal, Non-Repetitive)

These are one-time verification checklists, not regression tests.

| System             | Checklist                                                                       |
| ------------------ | ------------------------------------------------------------------------------- |
| **Track Laying**   | Place track → verify it appears → try invalid placement → verify rejection      |
| **Train Controls** | Throttle → verify acceleration → Brakes → verify deceleration → Verify momentum |
| **Car Auto-Fire**  | Spawn enemies → verify cars fire → verify targeting nearest                     |
| **Enemy Spawning** | Verify enemies spawn at correct intervals                                       |
| **Upgrade Picker** | Reach XP threshold → verify 3 options appear → select one → verify applied      |
| **Chest Drops**    | Kill special enemy → verify chest appears → collect → verify reward             |
| **Save/Load**      | Play a round → quit → reload → verify state matches                             |
| **Settings**       | Change resolution → verify applies → change volume → verify applies             |
| **Game Over**      | Destroy train → verify game over screen → verify restart option                 |
| **Audio**          | Play through a round → verify SFX at appropriate moments                        |
| **Story Text**     | Play through → verify story text appears at right moments                       |

## Per-Task Test Strategy

Refer to the BUILD_PLAN.md for per-task acceptance criteria. Each task's tests should be written **before** or **alongside** the implementation, not after.

**Rule for AI agents:** If a task changes core game logic, write a GUT test first that fails, then implement the fix so the test passes.

## Build & CI Tests

| Build Target | Test            | How                                                    |
| ------------ | --------------- | ------------------------------------------------------ |
| macOS        | Export builds   | `godot --headless --export-debug "macOS"`              |
| Linux        | Export builds   | `godot --headless --export-debug "Linux/X11"`          |
| Windows      | Export builds   | `godot --headless --export-debug "Windows Desktop"`    |
| WASM         | Export + deploy | `godot --headless --export-debug "Web"` + GitHub Pages |
| CI           | Pipeline runs   | GUT headless + trunk lint + all exports on every PR    |

## Performance Measurements (Task 17)

Record these metrics during the polish pass:

| Metric              | Tool                      | Target                         |
| ------------------- | ------------------------- | ------------------------------ |
| Frame rate          | Godot built-in profiler   | 60 FPS stable                  |
| Memory usage        | Godot profiler / OS stats | Reasonable for target platform |
| WASM load time      | Browser DevTools          | < 5 seconds                    |
| Object count        | Godot profiler            | Minimal scene tree             |
| GUT test suite time | GUT output                | < 30 seconds                   |

## Escalation for Testing

Send a task back to the architect if:

- GUT can't test a system without a full scene context (needs architect's design input)
- Test results are inconsistent (flaky tests indicate unclear rules)
- Integration tests reveal system conflicts (needs architectural decision)
- Manual test checklist items feel ambiguous (needs design clarification)
