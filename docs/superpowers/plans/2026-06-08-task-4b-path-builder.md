# Task 4b: Track Path Builder Plan

## Goal

Build a `TrackPathBuilder` that converts the new data model (DataTable + SegmentTable + SegmentType) into a `Path2D` for rendering. The path builder iterates cells grouped by `SegmentID`, looks up type + orientation, and generates `Path2D` segments from actual cell positions.

## Context & Constraints

- `Path2D` in Godot 4.x is a container for `PathSeg*` child nodes: `PathSegLine`, `PathSegCurve`, etc.
- `PathFollow2D` follows a `Path2D` and can be used for train movement.
- The path builder is a pure computation layer — it takes data model state and produces geometry. No rendering logic.
- All segment types must be supported: straight (1-cell, 2-cell), curve 1x1, curve 2x2, crossing 90°.
- Segments may be rotated; the path must reflect the rotated geometry.
- Multiple segments are drawn in rendering order (by segment ID placement order).
- Test functions: `-> void` return type required.

## Dependency Chain

Depends on: **Task 4a** (data model).
Feeds into: **Task 4c** (renderer uses path builder output), **Task 4d** (train movement uses path).

## Subtasks

### Subtask 4b-1: Create `track_path_builder.gd` — cell iteration & grouping

**File:** `track_path_builder.gd` (new)

**Goal:** Core utility that iterates over the data model and groups cells by segment ID.

**Implementation:**

1. Create `class_name TrackPathBuilder` extending `RefCounted`.
2. Method `func group_cells_by_segment(data_table: DataTable) -> Dictionary[int, Array[Vector2i]]` — returns a map of segment ID → array of cell positions.
3. Method `func sort_cells_in_path_order(cells: Array[Vector2i]) -> Array[Vector2i]` — sorts cells into a drawing order that traces a logical path.
   - For straight segments: sort along the dominant axis.
   - For curves: determine entry/exit direction, order cells to trace the curve.
4. Method `func get_neighbors_in_group(cells: Array[Vector2i], cell: Vector2i) -> Array[Vector2i]` — finds adjacent cells within the same group (4-connectivity).

**Tests:** `test/test_path_builder.gd` (new)

- `test_group_cells_empty_data_table()` → returns empty dict
- `test_group_cells_single_cell()` → dict with one entry
- `test_group_cells_two_cells_same_segment()` → cells grouped together
- `test_group_cells_two_cells_different_segments()` → cells in separate entries
- `test_group_cells_multi_segment_track()` → correct grouping for mixed track
- `test_sort_cells_horizontal_straight_in_order()` → cells sorted left-to-right
- `test_sort_cells_vertical_straight_in_order()` → cells sorted top-to-bottom
- `test_sort_cells_single_cell()` → single cell returns as-is
- `test_sort_cells_curve_cells_ordered()` → curve cells traced in order

---

### Subtask 4b-2: Create `track_path_builder.gd` — straight segment path generation

**File:** `track_path_builder.gd` (continue)

**Goal:** Generate `PathSegment` geometry for straight segment types.

**Implementation:**

1. Add method `func build_straight_path(cells: Array[Vector2i], type_id: int, orientation: int, data_table: DataTable) -> Path2D`.
2. For 1-cell straights: generate a single line segment centered on the cell.
3. For 2-cell straights: generate a line from the center of the first cell to the center of the second cell.
4. Account for orientation rotation — a horizontal straight rotated 90° becomes vertical.
5. Use a consistent cell-to-screen coordinate mapping (e.g., cell center at `cell_pos * CELL_SIZE`).
6. For multi-cell straights: compute start position (first cell center) and end position (last cell center), build a `PathSegLine` for each consecutive pair.

**Tests:** Add to `test/test_path_builder.gd`:

- `test_build_straight_path_1_cell_horizontal()` → single line segment
- `test_build_straight_path_1_cell_vertical()` → single vertical line
- `test_build_straight_path_2_cell_horizontal()` → line spanning two cells
- `test_build_straight_path_2_cell_vertical()` → line spanning two vertical cells
- `test_build_straight_path_1_cell_rotated_90()` → horizontal cell rendered vertically
- `test_build_straight_path_2_cell_rotated_180()` → two cells rendered as reversed line
- `test_build_straight_path_cell_count_varies()` → paths for 1-cell, 2-cell, 4-cell straights
- `test_build_straight_path_no_path_for_missing_type()` → error/empty path for unknown type

---

### Subtask 4b-3: Create `track_path_builder.gd` — curve segment path generation

**File:** `track_path_builder.gd` (continue)

**Goal:** Generate `PathSegCurve2D` geometry for curve segment types.

**Implementation:**

1. Add method `func build_curve_path(cells: Array[Vector2i], type_id: int, orientation: int) -> Path2D`.
2. For 1x1 curves:
   - Determine entry and exit directions from the segment's entrance pairs (rotated by orientation).
   - Generate a quadratic curve from entry cell center, through the cell center, to exit cell center.
   - Use `PathSegCurve2D` with control points.
3. For 2x2 curves:
   - Determine the four cell positions.
   - Trace the curve across all four cells in the proper order.
   - Build multiple curve segments that form a smooth arc.
4. Use a consistent radius for curve arcs (e.g., `CELL_SIZE / 2`).
5. Handle rotation: a curve entering from LEFT and exiting DOWN (in base orientation) should trace accordingly when rotated.

**Tests:** Add to `test/test_path_builder.gd`:

- `test_build_curve_path_1x1_entry_exit()` → correct entry/exit point calculation
- `test_build_curve_path_1x1_shape_generated()` → Path2D contains curve segment
- `test_build_curve_path_2x2_shape_generated()` → Path2D contains multi-segment arc
- `test_build_curve_path_1x1_rotated_90()` → curve traced in rotated direction
- `test_build_curve_path_1x1_rotated_180()` → curve traced in opposite direction
- `test_build_curve_path_1x1_rotated_270()` → curve traced in third direction
- `test_build_curve_path_2x2_has_multiple_segments()` → 2x2 curve generates multiple PathSegCurve2D
- `test_build_curve_path_2x2_cell_count_different_types()` → different rendering for 1-cell vs 2-cell

---

### Subtask 4b-4: Create `track_path_builder.gd` — crossing segment path generation

**File:** `track_path_builder.gd` (continue)

**Goal:** Generate geometry for 90° crossing segments.

**Implementation:**

1. Add method `func build_crossing_path(cells: Array[Vector2i], type_id: int, orientation: int) -> Path2D`.
2. A 90° crossing has cells forming a cross shape (e.g., 5 cells in a + pattern).
3. Generate lines for each arm of the cross.
4. Use `PathSegLine` for straight arms meeting at the center cell.
5. Handle rotation: all arms rotate around the center cell.

**Tests:** Add to `test/test_path_builder.gd`:

- `test_build_crossing_path_basic()` → generates cross-shaped path
- `test_build_crossing_path_arms_count()` → correct number of line segments
- `test_build_crossing_path_rotated_90()` → arms rotate correctly
- `test_build_crossing_path_rotated_180()` → arms rotated 180°
- `test_build_crossing_path_rotated_270()` → arms rotated 270°

---

### Subtask 4b-5: Create `track_path_builder.gd` — unified path assembly

**File:** `track_path_builder.gd` (continue)

**Goal:** Top-level method that takes the full data model state and produces a complete `Path2D`.

**Implementation:**

1. Add method `func build_full_path(track: Track) -> Path2D` — the main entry point.
2. Step 1: Group cells by segment ID via `_group_cells_by_segment()`.
3. Step 2: For each segment ID (in placement order):
   - Look up `SegmentTypeID` and `Orientation` from `SegmentTable`.
   - Sort cells into path order via `_sort_cells_in_path_order()`.
   - Dispatch to the appropriate build method based on `SegmentTypeID`:
     - Straight → `_build_straight_path()`
     - Curve 1x1 → `_build_curve_path()`
     - Curve 2x2 → `_build_curve_path()`
     - Crossing 90° → `_build_crossing_path()`
4. Step 3: Add all generated `PathSeg*` nodes to the `Path2D` root.
5. Step 4: Return the complete `Path2D`.
6. Handle edge cases: empty track returns empty `Path2D`, single segment, disconnected segments.

**Tests:** Add to `test/test_path_builder.gd`:

- `test_build_full_path_empty_track()` → returns empty Path2D
- `test_build_full_path_single_segment()` → Path2D has one segment's geometry
- `test_build_full_path_multi_segment_straight()` → Path2D has all straight segments
- `test_build_full_path_multi_segment_with_curve()` → Path2D has mixed straight+curve
- `test_build_full_path_full_layout()` → complex track from `main.gd` layout produces correct path
- `test_build_full_path_cell_count_varies()` → handles straights of different cell counts
- `test_build_full_path_preserves_segment_order()` → segments in Path2D match placement order
- `test_build_full_path_mixed_types()` → straight+curve+crossing in one path

---

### Subtask 4b-6: Integration with track.gd — expose path builder

**File:** `track.gd` (continue modifying)

**Goal:** Expose the path builder as a method on `Track` and provide access to segment IDs.

**Implementation:**

1. Add private member `_path_builder: TrackPathBuilder` to `Track`.
2. Initialize `_path_builder` in `initialize()`.
3. Add method `func get_path_2d() -> Path2D` — delegates to `_path_builder.build_full_path()`.
4. Add method `func get_segment_ids() -> Array[int]` — returns all segment IDs (from segment table).
5. Add method `func try_place_segment_by_id(id: int, cell_pos: Vector2i) -> bool` — delegate to data table + continuity check.
6. Add method `func try_place_segment_by_type(type_id: int, cell_pos: Vector2i, orientation: int = 0) -> bool` — convenience wrapper that creates/lookup segment ID.

**Tests:** Add to `test/test_track.gd`:

- `test_get_path_2d_returns_path_node()` → returns a Path2D node
- `test_get_segment_ids_for_empty_track()` → returns empty array
- `test_get_segment_ids_for_single_segment()` → returns one ID
- `test_get_segment_ids_for_multi_segment()` → returns all IDs
- `test_try_place_segment_by_id()` → placement by segment ID works
- `test_try_place_segment_by_type()` → placement by type ID works

---

### Subtask 4b-7: Integration smoke test

**File:** `test/test_path_builder_integration.gd` (new)

**Goal:** End-to-end test: place a complex track, verify the generated Path2D has correct geometry.

**Implementation:**

- Place the same layout as `main.gd._place_initial_track()`.
- Call `track.get_path_2d()`.
- Verify the returned `Path2D` has the expected number of path segments.
- Verify the path geometry matches the expected positions (straight line segments + curve arcs).

**Tests:**

- `test_integration_full_layout_path()` → main.gd layout produces correct Path2D
- `test_integration_path_matches_cell_positions()` → path geometry matches original cell positions
- `test_integration_path_works_for_all_segment_types()` → test all segment types individually
- `test_integration_path_for_non_contiguous_segments()` → handles non-connected tracks

---

## File Summary

### New Files

- `track_path_builder.gd` — Path builder implementation
- `test/test_path_builder.gd` — Unit tests for path builder
- `test/test_path_builder_integration.gd` — Integration smoke tests

### Modified Files

- `track.gd` — Add path builder member and exposed methods

## Estimated Test Count: ~55 test functions

## Acceptance Criteria

- `TrackPathBuilder` produces correct `Path2D` geometry for all segment types (straight 1/2/4-cell, curve 1x1, curve 2x2, crossing 90°).
- Rotated segments produce correctly oriented paths.
- Multi-segment tracks produce concatenated paths in placement order.
- Empty and single-segment edge cases handled gracefully.
- No runtime errors in headless GUT mode.
