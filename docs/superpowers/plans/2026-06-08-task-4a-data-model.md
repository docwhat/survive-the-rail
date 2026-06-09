# Task 4a: Data Model Migration Plan

## Goal

Replace the current `TrackSegment` (pos + connections array) model with the new 3-level normalized data model: **Data Table** (cell grid → `SegmentID`), **Segment Table** (`SegmentID` → `SegmentTypeID` + `Orientation`), **SegmentType** (readonly catalog).

## Context & Constraints

- Current `TrackSegment` stores `grid_position: Vector2i` and `connections: Array[Vector2i]` — an immutable model with an `initialize()` method.
- `Track` currently manages an `Array[TrackSegment]` plus an `occupied_cells: Dictionary[Vector2i, TrackSegment]`.
- The new model separates _placement data_ (which grid cell has what) from _segment definition_ (what type of segment is it, how is it oriented, what are its entrance pairs).
- Test functions must use `-> void` return type.
- Use GdUnit4 assertions: `assert_bool()`, `assert_int()`, `assert_float()`.
- All train movement math must migrate to `Path2D`/`PathFollow2D` — this plan is the data model foundation.

## Dependency Chain

This is the first task. Tasks 4b, 4c, and 4d depend on its output.

## Subtasks

### Subtask 4a-1: Create `segment_type.gd` (SegmentType catalog)

**File:** `segment_type.gd` (new)

**Goal:** Read-only segment type catalog with patterns and entrance-pair definitions.

**Implementation:**

1. Create `class_name SegmentType` extending `RefCounted`.
2. Define segment type constants: `STRAIGHT_H`, `STRAIGHT_V`, `CURVE_1X1`, `CURVE_2X2`, `CROSSING_90`.
3. Store `pattern: Array[Vector2i]` — relative cell positions for this segment type's visual footprint.
4. Store `entrance_pairs: Array[Array[Vector2i]]` — pairs of directions that form valid entrances.
5. Implement `static func get_type_by_name(name: String) -> int` for catalog lookup.
6. Implement `func has_valid_entrance(dir: Vector2i) -> bool` to check if a direction is covered by any entrance pair.

**Tests:** `test/segment_type_test.gd` (new)

- `test_get_type_by_name_straight_h()` → returns correct constant
- `test_get_type_by_name_curve_1x1()` → returns correct constant
- `test_straight_h_pattern_two_cells()` → pattern has 2 cells
- `test_curve_1x1_pattern_one_cell()` → pattern has 1 cell
- `test_straight_h_entrance_pairs_h_and_v()` → both horizontal and vertical entrances
- `test_has_valid_entrance_right()` → returns true for RIGHT on straight
- `test_has_valid_entrance_up()` → returns true for UP on straight
- `test_has_invalid_entrance()` → returns false for unsupported direction

---

### Subtask 4a-2: Create `segment_table.gd` (Segment registry)

**File:** `segment_table.gd` (new)

**Goal:** Maps `SegmentID` → `SegmentTypeID` + `Orientation`, supports orientation rotation.

**Implementation:**

1. Create `class_name SegmentTable` extending `RefCounted`.
2. Internal `Dictionary[int, Dictionary]` mapping `SegmentID` → `{ type_id: int, orientation: int }`.
3. Implement `func add_segment(id: int, type_id: int, orientation: int = 0) -> void`.
4. Implement `func get_segment_type(id: int) -> int` with error handling for missing IDs.
5. Implement `func get_orientation(id: int) -> int` with error handling.
6. Implement `func rotate_segment(id: int, degrees: int) -> void` — rotates orientation by 90° multiples.
7. Implement `func remove_segment(id: int) -> void`.
8. Implement `func contains(id: int) -> bool`.
9. Orientation values: 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°.

**Tests:** `test/segment_table_test.gd` (new)

- `test_add_segment()` → adds and can retrieve type and orientation
- `test_get_missing_segment_returns_error()` → push_error for missing ID
- `test_get_missing_orientation_returns_error()` → push_error for missing ID
- `test_rotate_segment_90_degrees()` → orientation goes 0→1
- `test_rotate_segment_180_degrees()` → orientation goes 0→2
- `test_rotate_segment_wraps_at_360()` → orientation wraps 3→0
- `test_remove_segment()` → removal then contains returns false
- `test_contains_after_add_and_remove()` → correct boolean after add+remove

---

### Subtask 4a-3: Create `data_table.gd` (Grid placement table)

**File:** `data_table.gd` (new)

**Goal:** Maps `Vector2i` grid cells → `SegmentID`, the primary placement interface.

**Implementation:**

1. Create `class_name DataTable` extending `RefCounted`.
2. Internal `Dictionary[Vector2i, int]` mapping cell position → segment ID.
3. Implement `func set_cell(pos: Vector2i, segment_id: int) -> void`.
4. Implement `func get_cell(pos: Vector2i) -> int` with error for empty cells.
5. Implement `func remove_cell(pos: Vector2i) -> void`.
6. Implement `func contains(pos: Vector2i) -> bool`.
7. Implement `func get_cell_count() -> int`.
8. Implement `func get_cells() -> Array[Vector2i]` returning all occupied cells.
9. Implement `func get_cells_by_segment_id(segment_id: int) -> Array[Vector2i]` grouping cells by segment.
10. Implement `func find_free_cell(neighbor_pos: Vector2i) -> bool` — checks if a position is unoccupied.

**Tests:** `test/data_table_test.gd` (new)

- `test_set_and_get_cell()` → sets cell, retrieves correct segment ID
- `test_get_empty_cell_returns_error()` → push_error for empty cell
- `test_contains_returns_true_after_set()` → correct boolean
- `test_contains_returns_false_for_empty()` → false for never-set position
- `test_remove_cell_and_contains_after_remove()` → cell removed, contains returns false
- `test_get_cell_count_for_empty_table()` → returns 0
- `test_get_cell_count_after_placement()` → returns correct count
- `test_get_cells_returns_all_occupied()` → returns all set positions
- `test_get_cells_by_segment_id_groups_correctly()` → cells grouped by ID
- `test_find_free_cell_on_free_position()` → returns true for unoccupied cell
- `test_find_free_cell_on_occupied_position()` → returns false for occupied cell

---

### Subtask 4a-4: Extend `track.gd` with new data model

**File:** `track.gd` (existing — modify)

**Goal:** Replace the `Array[TrackSegment]` model with `DataTable` + `SegmentTable`, integrate with `SegmentType` catalog.

**Implementation:**

1. Add private members: `_data_table: DataTable`, `_segment_table: SegmentTable`, `_segment_counter: int`, `_next_id: int`.
2. Initialize `_data_table` and `_segment_table` in `_ready()` or the existing `initialize()` method.
3. Create factory methods:
   - `func create_segment(type_id: int, orientation: int = 0, cells: Array[Vector2i] = []) -> int` — returns new `SegmentID`, allocates from `_next_id`, adds to `_segment_table`, returns the ID.
   - `func get_segment_id_at(pos: Vector2i) -> int` → delegates to `_data_table.get_cell(pos)`.
   - `func get_cells_for_segment_id(id: int) -> Array[Vector2i]` → delegates to `_data_table.get_cells_by_segment_id(id)`.
4. Replace `try_place_segment()` logic to:
   - Look up existing cells for the segment ID in `_segment_table`.
   - Place cells from the segment pattern at the given grid position in `_data_table`.
   - Validate continuity: for each placed cell, check neighboring cells already in `_data_table` have matching entrance pairs.
5. Replace `get_valid_placement_positions()`:
   - For each cell in `_data_table`, compute its neighbor positions.
   - For each neighbor, check if `_data_table` is empty there AND if the neighbor would satisfy the entrance pair constraints.
6. Replace `get_segments()` → return `Array[int]` of all segment IDs.
7. Keep existing resource/length tracking logic.
8. Keep `get_resources()`, `set_max_length()`, `get_max_length()` as-is.

**Tests:** Add to existing `test/test_track.gd`:

- `test_place_segment_uses_data_table()` → verifies cell placement in data table
- `test_place_segment_uses_segment_table()` → verifies segment type stored
- `test_data_table_gets_empty_at_init()` → empty data table
- `test_segment_table_has_no_segments()` → empty segment table
- `test_place_segment_with_next_id()` → first segment gets ID 0
- `test_place_multiple_segments_incremental_ids()` → IDs increment
- `test_place_at_occupied_cell_fails()` → occupied cells reject placement
- `test_get_valid_positions_from_data_table()` → positions derived from data table cells
- `test_continuity_validation_entrance_pairs()` → validates entrance pair matching
- `test_continuity_fails_invalid_entrance()` → rejects placement with mismatched entrances

---

### Subtask 4a-5: Add rotation support and entrance math

**File:** `track.gd` (continue modifying)

**Goal:** Implement 90° rotation math and entrance pair validation for the new model.

**Implementation:**

1. Add rotation constants: `const ROTATION_0 = 0`, `const ROTATION_90 = 1`, `const ROTATION_180 = 2`, `const ROTATION_270 = 3`.
2. Implement `func rotate_direction(dir: Vector2i, rotation: int) -> Vector2i` — rotates a direction vector by 90° × rotation steps.
   - E.g., RIGHT(1,0) rotated 90° → DOWN(0,1), rotated 180° → LEFT(-1,0), etc.
3. Implement `func get_effective_directions(type_id: int, orientation: int) -> Array[Vector2i]` — takes base entrance pairs from `SegmentType` and rotates them by the segment's orientation.
4. Update `try_place_segment()` continuity validation to use rotated directions:
   - For each cell of the new segment, look at neighbor cells already placed.
   - Compute the direction from the new cell to the neighbor.
   - Check if the neighbor's segment type has an entrance pair covering that direction (rotated by neighbor's orientation).
   - Check if the new segment's entrance pair covers the opposite direction.
5. Update `get_valid_placement_positions()` to use entrance pair math instead of raw connection arrays.

**Tests:** Add to `test/test_track.gd`:

- `test_rotate_direction_right_0_degrees()` → RIGHT stays RIGHT
- `test_rotate_direction_right_90_degrees()` → RIGHT becomes DOWN
- `test_rotate_direction_right_180_degrees()` → RIGHT becomes LEFT
- `test_rotate_direction_right_270_degrees()` → RIGHT becomes UP
- `test_get_effective_directions_with_no_rotation()` → returns base directions
- `test_get_effective_directions_with_90_rotation()` → returns rotated directions
- `test_continuity_entrance_matches_rotation()` → placement succeeds when rotated entrances align
- `test_continuity_entrance_mismatch_fails()` → placement fails when rotated entrances don't align
- `test_placement_at_curve_aligns_with_neighbor()` → curve placement validates rotated entrances

---

### Subtask 4a-6: Deprecate old `TrackSegment` model with backward compatibility

**File:** `track_segment.gd` (existing — modify)
**File:** `track.gd` (continue modifying)

**Goal:** Keep `TrackSegment` for transitional compatibility but mark deprecated. Update `main.gd` to use new API.

**Implementation:**

1. Add `@deprecated` annotation to `TrackSegment` class.
2. Add `@deprecated` annotation to `Track.create_straight_segment()` and `Track.create_curve_segment()`.
3. Create new API methods on `Track`:
   - `func try_place_segment_by_id(segment_id: int, cell_position: Vector2i) -> bool` — direct placement using segment ID.
   - `func try_place_segment_by_type(type_id: int, cell_position: Vector2i, orientation: int = 0) -> bool` — convenience wrapper.
4. Update `main.gd._place_initial_track()` to use new API methods.
5. Verify existing tests still pass (old `TrackSegment` API still works).
6. Document the deprecation timeline: keep old API for one more sprint, remove in next major refactor.

**Tests:** Add to `test/test_track.gd`:

- `test_try_place_segment_by_id_basic()` → placement by segment ID
- `test_try_place_segment_by_type_basic()` → placement by type ID
- `test_old_api_still_works()` → deprecated methods still function
- `test_main_place_initial_track_uses_new_api()` → `main.gd` compiles and runs

---

### Subtask 4a-7: Integration smoke test

**File:** `test/test_track_data_model.gd` (new)

**Goal:** End-to-end smoke test verifying the new data model works together.

**Implementation:**

- Create a scenario: place a straight horizontal segment, then a curve, then a vertical straight.
- Verify all data table cells are populated correctly.
- Verify all segment IDs are tracked.
- Verify valid placement positions include expected neighbors.
- Verify placement failures for occupied cells and invalid entrances.
- Verify segment removal (if implemented) cleans up both tables.

**Tests:**

- `test_integration_place_horizontal_straight()` → full lifecycle: place, verify data table, verify segment table, verify positions
- `test_integration_add_curve_after_straight()` → multi-segment placement with entrance validation
- `test_integration_fail_placement_in_invalid_direction()` → placement blocked by entrance mismatch
- `test_integration_get_valid_positions_after_complex_layout()` → complex track, verify all positions

---

## File Summary

### New Files

- `segment_type.gd` — Segment type catalog
- `segment_table.gd` — Segment ID registry
- `data_table.gd` — Grid placement table
- `test/segment_type_test.gd` — SegmentType unit tests
- `test/segment_table_test.gd` — SegmentTable unit tests
- `test/data_table_test.gd` — DataTable unit tests
- `test/test_track_data_model.gd` — Integration smoke tests

### Modified Files

- `track.gd` — Replace internal storage, add new API, deprecate old methods
- `track_segment.gd` — Mark deprecated
- `main.gd` — Update `_place_initial_track()` to new API

## Estimated Test Count: ~50 test functions

## Acceptance Criteria

- All data table / segment table / segment type operations work correctly.
- Continuity validation via entrance pairs works with 90° rotations.
- `try_place_segment_by_id()` and `try_place_segment_by_type()` work as replacement APIs.
- Existing tests for old `TrackSegment` API still pass.
- No runtime errors in headless GUT mode.
