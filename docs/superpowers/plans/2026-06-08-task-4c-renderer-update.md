# Task 4c: Track Renderer Update Plan

## Goal

Update `track_renderer.gd` to draw from the new data model instead of the old `TrackSegment` connection array. This includes rendering segment shapes, preview graphics for valid placement positions, and entrance direction markers.

## Context & Constraints

- Current `track_renderer.gd` is a `Control` node that receives a `Track` reference and draws segments using `_draw()` calls with line/circle/arc primitives.
- The current implementation draws each `TrackSegment` individually using its `grid_position` and `connections` array.
- It uses helper methods like `_draw_straight_segment()`, `_draw_curve_segment()`, and `_draw_valid_positions()`.
- The renderer needs to:
  1. Draw segment shapes (straights, curves, crossings) from the new data model.
  2. Render preview graphics when `PlaceMode` is active.
  3. Show entrance direction markers on preview segments.
  4. Draw valid placement positions (neighbor cells).
- No `Path2D` is needed for rendering — the renderer draws geometrically from cell positions.
- The renderer needs a reference to `SegmentType` catalog for shape data.
- Test functions: `-> void` return type required.

## Dependency Chain

Depends on: **Task 4a** (data model), **Task 4b** (path builder for rendering reference).

## Subtasks

### Subtask 4c-1: Refactor `track_renderer.gd` — accept data model

**File:** `track_renderer.gd` (existing — modify)

**Goal:** Update the renderer's `update()` method to work with the new data model.

**Implementation:**

1. Update `func update(track: Track, cam_offset: Vector2)` — keep the public API signature but change internal logic.
2. Add private member `_segment_type_ref: SegmentType` — reference to the segment type catalog.
3. In `_draw()`:
   - Iterate over `track.get_segment_ids()` instead of `track.get_segments()`.
   - For each segment ID, look up cells via `track.get_cells_for_segment_id(id)`.
   - Look up type and orientation from `track._segment_table`.
   - Dispatch to type-specific drawing methods.
4. Remove rendering of old connection arrays — draw segment shapes based on type + orientation instead.

**Tests:** `test/test_track_renderer.gd` (new)

- `test_update_empty_track_clears_canvas()` → no drawing on empty track
- `test_update_single_segment_draws_shape()` → one segment renders
- `test_update_multi_segment_draws_all()` → all segments render
- `test_update_valid_positions_drawn()` → valid positions appear on canvas

---

### Subtask 4c-2: Implement straight segment rendering

**File:** `track_renderer.gd` (continue)

**Goal:** Draw straight segments by type (1-cell, 2-cell, 4-cell) with rotation support.

**Implementation:**

1. Add method `_draw_straight_segment(cells: Array[Vector2i], type_id: int, orientation: int, cam_offset: Vector2)` → `void`.
2. For 1-cell straights: draw a rectangle/thick line centered on the cell.
3. For 2-cell straights: draw a longer shape spanning two cells.
4. For 4-cell straights: draw the longest shape spanning four cells.
5. Apply orientation rotation:
   - Horizontal straights (type 0): draw horizontal rectangles/lines.
   - Vertical straights (type 1): draw vertical rectangles/lines.
   - Rotated straights: rotate the shape by 90° × rotation value.
6. Use consistent colors: neutral gray for placed segments, matching the current visual style.

**Tests:** Add to `test/test_track_renderer.gd`:

- `test_draw_straight_1_cell_horizontal()` → shape drawn for 1-cell horizontal
- `test_draw_straight_1_cell_vertical()` → shape drawn for 1-cell vertical
- `test_draw_straight_2_cell_horizontal()` → shape spans 2 cells
- `test_draw_straight_2_cell_vertical()` → shape spans 2 vertical cells
- `test_draw_straight_4_cell_horizontal()` → shape spans 4 cells
- `test_draw_straight_4_cell_vertical()` → shape spans 4 vertical cells
- `test_draw_straight_horizontal_rotated_90()` → horizontal shape rendered vertically
- `test_draw_straight_horizontal_rotated_180()` → horizontal shape rendered horizontally (flipped)
- `test_draw_straight_horizontal_rotated_270()` → horizontal shape rendered vertically (flipped)
- `test_draw_straight_color_is_consistent()` → segments drawn in expected color

---

### Subtask 4c-3: Implement curve segment rendering

**File:** `track_renderer.gd` (continue)

**Goal:** Draw curve segments (1x1 and 2x2) with rotation support.

**Implementation:**

1. Add method `_draw_curve_segment(cells: Array[Vector2i], type_id: int, orientation: int, cam_offset: Vector2)` → `void`.
2. For 1x1 curves:
   - Determine entry and exit directions from entrance pairs (rotated by orientation).
   - Draw a thick arc from entry direction to exit direction.
   - Center the arc on the cell position.
3. For 2x2 curves:
   - Determine the four cell positions.
   - Draw an arc that spans the 2x2 area, entering from one side and exiting the other.
   - Use a larger radius arc that connects the boundary cells.
4. Apply rotation to the arc direction.
5. Use consistent colors matching the straight segment style.

**Tests:** Add to `test/test_track_renderer.gd`:

- `test_draw_curve_1x1_basic()` → arc drawn for 1x1 curve
- `test_draw_curve_1x1_entry_exit_correct()` → arc connects correct entry/exit
- `test_draw_curve_1x1_rotated_90()` → arc direction rotated
- `test_draw_curve_1x1_rotated_180()` → arc direction rotated 180°
- `test_draw_curve_1x1_rotated_270()` → arc direction rotated 270°
- `test_draw_curve_2x2_basic()` → arc spans 2x2 area
- `test_draw_curve_2x2_rotated_90()` → arc direction rotated in 2x2
- `test_draw_curve_2x2_rotated_180()` → arc direction rotated 180° in 2x2
- `test_draw_curve_color_matches_straight()` → curves drawn in same color family

---

### Subtask 4c-4: Implement crossing segment rendering

**File:** `track_renderer.gd` (continue)

**Goal:** Draw 90° crossing segments (cross shape).

**Implementation:**

1. Add method `_draw_crossing_segment(cells: Array[Vector2i], type_id: int, orientation: int, cam_offset: Vector2)` → `void`.
2. A 90° crossing has a cross shape (5 cells in a + pattern).
3. Draw thick lines for each arm of the cross.
4. Apply rotation: all arms rotate around the center cell.
5. Use consistent colors.

**Tests:** Add to `test/test_track_renderer.gd`:

- `test_draw_crossing_basic()` → cross shape rendered
- `test_draw_crossing_arms_drawn()` → all arms rendered
- `test_draw_crossing_rotated_90()` → arms rotated
- `test_draw_crossing_rotated_180()` → arms rotated 180°
- `test_draw_crossing_rotated_270()` → arms rotated 270°
- `test_draw_crossing_color_matches()` → crossing drawn in same color family

---

### Subtask 4c-5: Implement placement preview rendering

**File:** `track_renderer.gd` (continue)

**Goal:** Draw preview graphics when `PlaceMode` is active: segment shapes + entrance markers + valid positions.

**Implementation:**

1. Add method `_draw_preview(segment_id: int, cells: Array[Vector2i], position: Vector2i, cam_offset: Vector2)` → `void`.
2. Draw a semi-transparent version of the segment shape at the preview position.
3. For straights: draw dashed or lighter-colored line.
4. For curves: draw semi-transparent arc.
5. Draw entrance direction markers: small arrows/arcs at entrance cell edges indicating connection directions.
6. Continue to draw valid placement positions as small dots/circles (existing logic).

**Tests:** Add to `test/test_track_renderer.gd`:

- `test_preview_straight_horizontal()` → horizontal preview line rendered
- `test_preview_straight_vertical()` → vertical preview line rendered
- `test_preview_curve_1x1()` → preview arc rendered
- `test_preview_curve_2x2()` → preview arc rendered for 2x2
- `test_preview_crossing()` → preview cross rendered
- `test_preview_entrance_markers_drawn()` → entrance markers visible on preview
- `test_preview_valid_positions_drawn()` → valid positions on preview track
- `test_preview_semi_transparent()` → preview is visibly lighter than placed segments

---

### Subtask 4c-6: Update main.tscn to use new renderer API

**File:** `main.tscn` (existing — modify)

**Goal:** Ensure the scene tree uses the updated renderer nodes correctly.

**Implementation:**

1. Verify `TrackRenderer` node in `main.tscn` has the correct script reference.
2. Ensure no changes needed to the scene hierarchy (renderer is still a `Control` child of the main scene).
3. Verify the `update(track, cam_offset)` call signature in `main.gd._process()` is compatible.

**Tests:**

- `test_scene_loads_without_error()` → scene loads without script errors
- `test_track_renderer_node_exists()` → TrackRenderer node found in scene tree
- `test_track_renderer_update_called_with_correct_args()` → main calls update() properly

---

### Subtask 4c-7: Integration smoke test

**File:** `test/test_renderer_integration.gd` (new)

**Goal:** End-to-end test: place a complex track, verify renderer draws correctly.

**Implementation:**

- Create a `TrackRenderer` instance.
- Place multiple segments of different types.
- Call `update(track, cam_offset)`.
- Verify the canvas has drawn content (for visual inspection in GUT, check `_draw()` was called the expected number of times via stubbing or mocking).
- Test preview rendering with various segment types.

**Tests:**

- `test_integration_renderer_draws_all_segment_types()` → all types render without errors
- `test_integration_renderer_with_mixed_track()` → mixed track renders correctly
- `test_integration_renderer_preview_mode()` → preview renders alongside placed track
- `test_integration_renderer_camera_offset_applied()` → offset shifts rendered positions

---

## File Summary

### New Files

- `test/test_track_renderer.gd` — Renderer unit tests
- `test/test_renderer_integration.gd` — Integration smoke tests

### Modified Files

- `track_renderer.gd` — Replace old drawing logic with data-model-based rendering
- `main.tscn` — Verify scene compatibility (likely no changes needed)

## Estimated Test Count: ~45 test functions

## Acceptance Criteria

- All segment types render correctly from the data model (straights, curves, crossings).
- Rotated segments render with correct orientation.
- Preview graphics show semi-transparent shapes with entrance markers.
- Valid placement positions render correctly.
- No runtime errors in headless GUT mode.
- Scene loads and renders without errors in-game mode.
