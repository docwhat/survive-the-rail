# Task 4d: Train Migration to PathFollow2D Plan

## Goal

Migrate `train.gd` from manual segment index + progress tracking to `PathFollow2D`-based movement. The train engine uses `PathFollow2D` to follow the track path; cars follow at their respective coupling offsets.

## Context & Constraints

- Current `Train` class tracks `position: Vector2`, `segment_index: int`, `segment_progress: float`, and `direction: Vector2`.
- `update_position(track, delta)` moves the train along segments using manual math.
- `update_orientation(track)` calculates rotation angle from segment connections.
- `Car` classes have `bogie_offset`, `body_rotation`, and `coupling_offset` for visual pivot animation.
- `TrainRenderer` draws engine + cars with manual positioning math for curves.
- The migration must preserve the invariant: **Mode switch (including undo) does not change the train's position on the track.**
- `PathFollow2D` has `progress` (float, distance along path) and `progress_offset` (float, local offset along path).
- When switching from manual tracking to `PathFollow2D`, convert the current position/progress to a path progress value.
- Test functions: `-> void` return type required.

## Dependency Chain

Depends on: **Task 4a** (data model), **Task 4b** (path builder), **Task 4c** (renderer update).
This is the final task in the sequence.

## Subtasks

### Subtask 4d-1: Create `train_path_follower.gd` — PathFollow2D wrapper

**File:** `train_path_follower.gd` (new)

**Goal:** A `RefCounted` class that wraps `PathFollow2D` management for the train engine.

**Implementation:**

1. Create `class_name TrainPathFollower` extending `RefCounted`.
2. Internal `PathFollow2D` node reference (created dynamically or assigned from scene).
3. Method `func initialize(path: Path2D) -> void` — creates/configures the `PathFollow2D`.
4. Method `func get_path_follow_node() -> PathFollow2D` — exposes the node for parent access.
5. Method `func get_progress() -> float` — returns current progress along the path.
6. Method `func set_progress(progress: float) -> void` — sets progress along the path.
7. Method `func get_position() -> Vector2` — returns the PathFollow2D's world position.
8. Method `func get_angle() -> float` — returns the angle of the PathFollow2D at its current position.
9. Method `func update_path(new_path: Path2D) -> void` — replaces the underlying path, preserves progress proportionally.

**Tests:** `test/test_train_path_follower.gd` (new)

- `test_initialize_with_path()` → PathFollow2D created and configured
- `test_get_progress_returns_zero_initially()` → starts at 0
- `test_set_progress_changes_position()` → progress affects position
- `test_get_angle_returns_correct_angle()` → angle follows path direction
- `test_update_path_preserves_progress()` → path replacement keeps relative position
- `test_update_path_empty_path()` → handles empty path gracefully

---

### Subtask 4d-2: Create `car_path_follower.gd` — Car PathFollow2D wrapper

**File:** `car_path_follower.gd` (new)

**Goal:** A `RefCounted` class that wraps `PathFollow2D` for a single car, offset from the engine.

**Implementation:**

1. Create `class_name CarPathFollower` extending `RefCounted`.
2. Internal `PathFollow2D` node reference (one per car).
3. Method `func initialize(path: Path2D, coupling_offset: Vector2) -> void` — creates/configures, sets `progress_offset` based on `coupling_offset`.
4. Method `func get_coupling_offset() -> Vector2` — returns the car's coupling offset.
5. Method `func set_coupling_offset(offset: Vector2) -> void` — updates `progress_offset` when coupling changes.
6. Method `func get_position() -> Vector2` — returns the car's world position.
7. Method `func get_angle() -> float` — returns the car's angle.

**Tests:** `test/test_car_path_follower.gd` (new)

- `test_initialize_with_path_and_offset()` → PathFollow2D created with offset
- `test_get_coupling_offset_returns_value()` → offset accessible
- `test_set_coupling_offset_changes_progress()` → offset update reflects in path
- `test_get_position_returns_offset_position()` → position accounts for coupling
- `test_get_angle_follows_path_at_offset()` → angle follows path at car's position

---

### Subtask 4d-3: Migrate `train.gd` — replace segment_index/progress with path follower

**File:** `train.gd` (existing — modify)

**Goal:** Replace manual segment tracking with `TrainPathFollower`.

**Implementation:**

1. Add private member `_path_follower: TrainPathFollower`.
2. Remove `segment_index: int` and `segment_progress: float` public properties.
3. In `initialize()`:
   - Create `_path_follower`.
   - Set `speed = 0.0`, `position = Vector2.ZERO`.
4. Replace `update_position(track, delta)`:
   - Get `Path2D` from `track.get_path_2d()`.
   - Call `_path_follower.update_path(path_2d)`.
   - Calculate movement distance: `delta * speed`.
   - Add to `_path_follower.progress` (accounting for direction).
   - Update `position = _path_follower.get_position()`.
5. Replace `update_orientation(track)`:
   - Return `_path_follower.get_angle()`.
6. Keep all physics methods (`update_speed`, `resolve_collision`, `take_damage`, etc.) unchanged.
7. Keep all getters (`get_momentum`, `get_stopping_distance`, etc.) unchanged.

**Tests:** Add to `test/test_train.gd`:

- `test_update_position_uses_path_follower()` → train moves along path
- `test_update_position_zero_speed_no_movement()` → zero speed doesn't move
- `test_update_position_empty_track_no_movement()` → empty path, no movement
- `test_update_position_advances_along_path()` → progress increases with speed
- `test_update_orientation_returns_path_angle()` → angle follows path
- `test_update_orientation_curved_track()` → angle changes on curves
- `test_speed_update_still_works()` → speed physics unaffected
- `test_collision_still_works()` → collision resolution unaffected
- `test_damage_still_works()` → damage system unaffected
- `test_get_state_still_works()` → serialization still captures position/speed

---

### Subtask 4d-4: Migrate `car.gd` — replace manual positioning with car path follower

**File:** `car.gd` (existing — modify)
**File:** `train.gd` (continue modifying)

**Goal:** Cars use `CarPathFollower` instead of manual position calculation.

**Implementation:**

1. In `Car`:
   - Add private member `_path_follower: CarPathFollower`.
   - Remove manual `position` calculation based on `bogie_offset` and `body_rotation`.
   - Keep `coupling_offset` and `bogie_offset` for data/model purposes.
2. In `Train`:
   - Each car gets a `CarPathFollower` on `add_car()`.
   - On `remove_car()`, dispose of the car's `CarPathFollower`.
3. Update `Car.initialize(car_type, weight, coupling_offset)`:
   - Initialize `_path_follower` with the path reference (injected from train).
   - Set coupling offset on the follower.
4. Cars should not have their own position tracking — they derive position from the `CarPathFollower` which derives it from the shared `Path2D` + `progress_offset`.

**Tests:** Add to `test/test_train.gd` and new `test/test_car_path_follower.gd`:

- `test_add_car_creates_path_follower()` → car gets its own follower
- `test_remove_car_disposes_path_follower()` → follower cleaned up on removal
- `test_car_position_from_path_follower()` → car position matches follower
- `test_car_angle_from_path_follower()` → car angle matches follower
- `test_car_coupling_offset_affects_position()` → offset changes car position
- `test_multiple_cars_have_independent_followers()` → each car tracks independently
- `test_car_remove_does_not_affect_other_cars()` → removing one car doesn't affect others

---

### Subtask 4d-5: Migrate `train_renderer.gd` — draw from path followers

**File:** `train_renderer.gd` (existing — modify)

**Goal:** Update renderer to draw from `PathFollow2D` positions instead of manual math.

**Implementation:**

1. Update `func update(train: Train, track: Track, cam_offset: Vector2)` → `void`.
2. Get engine position from the train's path follower (access via getter or direct reference).
3. For each car:
   - Get position from the car's path follower.
   - Draw the car sprite at the follower's position.
4. Remove manual curve positioning math (`_draw_curve_position()`, etc.).
5. Draw coupling lines from engine to each car using follower positions.
6. Keep pivot/body animation — the car's `body_rotation` can still be used as an overlay transform.

**Tests:** Add to `test/test_train_renderer.gd`:

- `test_draw_engine_at_path_follower_position()` → engine drawn at correct position
- `test_draw_cars_at_path_follower_positions()` → cars drawn at follower positions
- `test_draw_couple_lines_between_engine_and_cars()` → coupling lines rendered
- `test_draw_tracks_rotated_segment()` → rotated segments drawn correctly
- `test_draw_simple_track_no_rotation()` → simple track draws without rotation
- `test_draw_complex_layout()` → complex layout renders correctly
- `test_draw_with_cars_multiple_cars()` → multiple cars render correctly
- `test_update_with_empty_train()` → renderer handles empty train
- `test_update_with_empty_track()` → renderer handles empty track

---

### Subtask 4d-6: Mode switch invariant — position preservation on undo/path rebuild

**File:** `train.gd` (continue modifying)

**Goal:** Ensure mode switches (including undo) preserve the train's physical position on the track.

**Implementation:**

1. Add method `func get_path_progress() -> float` — returns the current path progress value.
2. Add method `func set_path_progress(progress: float) -> void` — sets the progress, used for undo.
3. When track is modified (placement/removal/undo):
   - If the train is on a segment that was affected, recalculate its progress along the new path.
   - Use the original position (in world coordinates) to find the closest point on the new path.
   - Set the path follower's progress to match that closest point.
4. For undo operations:
   - Before the undo, snapshot the current path progress.
   - After the path rebuild, set progress to the closest point on the rebuilt path from the old position.
5. Edge cases: track completely removed under train → reset to start, train on removed segment → nearest valid position.

**Tests:** Add to `test/test_train.gd`:

- `test_get_path_progress_returns_current_progress()` → getter returns correct value
- `test_set_path_progress_changes_position()` → setter affects position
- `test_mode_switch_preserves_position()` → switching modes doesn't change train position
- `test_undo_after_segment_placement_preserves_position()` → undo preserves train position
- `test_path_rebuild_after_track_modification()` → path rebuild keeps train at correct position
- `test_track_removed_under_train()` → train handled when track removed underneath
- `test_track_shortened_before_train()` → train on shortened track handled correctly

---

### Subtask 4d-7: Integration smoke test

**File:** `test/test_train_migration_integration.gd` (new)

**Goal:** End-to-end test: create a train on a placed track, verify movement along Path2D.

**Implementation:**

- Create a track with straights and curves.
- Create a train and place it on the track.
- Simulate movement (throttle) and verify the train follows the path correctly.
- Test with multiple cars.
- Test undo/rebuild path scenario.

**Tests:**

- `test_integration_train_follows_straight_path()` → train moves along straight track
- `test_integration_train_follows_curved_path()` → train follows curves correctly
- `test_integration_train_with_cars_follows_path()` → cars follow the path
- `test_integration_undo_preserves_position()` → undo preserves train position
- `test_integration_full_gameplay_loop()` → complete gameplay: place track, move train, undo, move again

---

## File Summary

### New Files

- `train_path_follower.gd` — Train engine PathFollow2D wrapper
- `car_path_follower.gd` — Car PathFollow2D wrapper
- `test/test_train_path_follower.gd` — TrainPathFollower unit tests
- `test/test_car_path_follower.gd` — CarPathFollower unit tests
- `test/test_train_migration_integration.gd` — Integration smoke tests

### Modified Files

- `train.gd` — Replace segment_index/progress with path follower, add progress getters/setters
- `car.gd` — Replace manual positioning with CarPathFollower
- `train_renderer.gd` — Draw from path follower positions
- `main.gd` — May need minor updates for train/car node references

## Estimated Test Count: ~55 test functions

## Acceptance Criteria

- Train engine moves along `Path2D` via `PathFollow2D`.
- Cars follow the path at their coupling offsets via individual `CarPathFollower` instances.
- Mode switches (including undo) preserve the train's physical position on the track.
- Renderer draws from path follower positions.
- All physics calculations (speed, momentum, collision, damage) remain unaffected.
- No runtime errors in headless GUT mode.
- Full gameplay loop works: place track → move train → undo → move again.
