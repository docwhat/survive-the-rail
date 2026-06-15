# Task 6 — Car System & Auto-Fire Design

**Date:** 2026-06-10
**Status:** Approved
**Related Tasks:** Task 7 (Enemies), Task 8 (Projectiles), Task 10 (Upgrade Picker)

## 1. Architecture

Three classes split by responsibility:

```text
car.gd         — base car: stats, weight, health, category, level
car_weapon.gd  — weapon behavior: fire rate, damage, range, targeting mode
car_utility.gd — utility bonus: passive stat boost, stacking support
```

**`car.gd`** holds `car_type`, `category`, `level`, `weight`, `health`, `bogie_offset`. It gains optional `weapon: CarWeapon` or `utility: CarUtility` references.

**`car_weapon.gd`** defines weapon parameters and targeting logic. The Car holds one instance.

**`car_utility.gd`** defines a bonus type and value. The Car holds one instance. The Train queries all utility cars to compute total bonuses.

**`train.gd`** gains `process_cars(delta)` (weapon fire) and `_apply_utility_bonuses()` (utility stacking).

---

## 2. Component Design

### car.gd (updated)

Additions:

- `weapon: CarWeapon` — null for utility cars
- `utility: CarUtility` — null for weapon cars
- `targeting_mode: String` — for weapon cars
- `has_weapon() -> bool` / `has_utility() -> bool` convenience methods

Updated `initialize(type, weight, bogie_offset)` also accepts weapon/utility config.

Removed `body_rotation` — rotation handled by `CarPathFollower` (Task 4d).

### car_weapon.gd (new)

Properties: `weapon_type` ("cannon"/"machine_gun"), `damage`, `fire_rate`, `range`, `targeting_mode` ("nearest"/"farthest"/"healthiest"/"weakest"), `cooldown`, `fire_angle`.

Key methods:

- `initialize(type, damage, fire_rate, range)`
- `update_cooldown(delta)` — tick down, fire when ready
- `get_fire_angle() -> float` — computed from target selection
- `reset_cooldown() -> void`

Firing logic:

1. Each frame, check `cooldown <= 0`
2. If ready, scan for eligible enemies, select target by mode
3. Compute `fire_angle`, fire (instant raycast damage), reset cooldown to `fire_rate`
4. If no targets, continue decrementing cooldown

Two weapon configurations:

- **Cannon:** damage=8.0, fire_rate=2.0s, range=150.0
- **Machine Gun:** damage=2.0, fire_rate=0.1s, range=250.0

### car_utility.gd (new)

Properties: `bonus_type` ("speed"/"capacity"), `bonus_value` (float).

Key methods:

- `initialize(type, value)`
- `apply_to_train(train: Train)` — modify train stats
- `get_bonus_type()`, `get_bonus_value()`

Stacking: Additive. Two Boosters of +10 each = +20 max_speed.

Two utility configurations:

- **Booster:** bonus_type="speed", bonus_value=10.0
- **Cargo:** bonus_type="capacity", bonus_value=5.0

---

## 3. Data Flow & Integration

### `Train.process_cars(delta)`

```gdscript
for car in cars:
    if car.has_weapon():
        weapon = car.weapon
        weapon.update_cooldown(delta)
        if weapon.cooldown <= 0:
            target = _find_target(weapon)
            if target != null:
                weapon.fire_at(target)
                weapon.reset_cooldown()
```

### Target selection (`_find_target(weapon)`)

- Iterate all enemies (represented as dictionaries: `{"position": Vector2, "health": float}`)
- Filter: within `weapon.range` AND ahead of train (dot product with travel direction > 0)
- Sort by `targeting_mode`:
  - **nearest:** by distance ascending
  - **farthest:** by distance descending
  - **healthiest:** by health descending
  - **weakest:** by health ascending
- Return first match, or null

### Enemy interface (forward-compatible)

Weapons query enemy dictionaries for `position` and `health`. No dependency on enemy class — this decouples weapon logic from future enemy implementation (Task 7).

### `Train._apply_utility_bonuses()`

```gdscript
for car in cars:
    if car.has_utility():
        bonus = car.utility
        if bonus.type == "speed": max_speed += bonus.value
        if bonus.type == "capacity": capacity += bonus.value
```

---

## 4. Testing Plan

~43 tests across 5 suites:

### car_weapon_test.gd (~16 tests)

- Initialization: type, damage, fire_rate, range, targeting_mode
- Cooldown: decreases, doesn't fire until ready, resets after fire, disabled stays
- Target selection: nearest, farthest, healthiest, weakest modes
- Edge cases: no target, enemies out of range, enemies behind train
- Fire angle computation toward target

### car_utility_test.gd (~8 tests)

- Initialization: bonus type and value
- Bonus types: speed positive, capacity positive
- Apply to train: speed increases max_speed, capacity increases capacity
- Stacking: multiple same type additive, different types independent

### car_test (updated) (~10 tests)

- Weapon car: has_weapon=true, category="Weapon"
- Utility car: has_utility=true, category="Utility"
- Regular car: has_neither, category="Cargo"
- Weapon initialized for cannon and machine gun
- Utility initialized for booster and cargo
- Level weight scaling preserved

### train_cars_integration_test.gd (~5 tests)

- Weapon car selects nearest from multiple targets
- Utility cars add speed bonuses correctly
- Mixed train has both weapon and utility cars
- Weapon cooldown timing matches fire rate
- Full mixed car scenario

---

## 5. Decisions Summary

| Decision         | Choice                                       | Rationale                                      |
| ---------------- | -------------------------------------------- | ---------------------------------------------- |
| Firing model     | Proximity + travel direction                 | Simple, tactical, fits forward-moving gameplay |
| Targeting modes  | 4 fixed: nearest/farthest/healthiest/weakest | Covers distinct tactical choices               |
| Weapon types     | Cannon + Machine Gun                         | Classic contrast, clear tradeoffs              |
| Utility types    | Booster + Cargo                              | Speed vs capacity tradeoffs                    |
| Damage flow      | Instant-hit raycasts                         | Simplest to implement/test now                 |
| Utility stacking | Additive                                     | Clear strategic value to collecting            |
| Car acquisition  | Post-run selection                           | Player agency, strategic build                 |
| Enemy interface  | Dictionary `{position, health}`              | Decouples weapons from future enemy system     |
