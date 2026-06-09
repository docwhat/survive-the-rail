# Task 4a–4d — Track Data Model & Movement Re-architecture Design

## Context

Task 4 had persistent problems with train/car rotation on curves (spinning at curve entry, cars orbiting the origin). Root cause: position and orientation were computed manually for each segment type, duplicating geometry logic between movement code and rendering code.

This design re-architects the system using a **three-level normalized data model** and **Godot's Path2D/PathFollow2D** for movement.

---

## Coordinate System

- **Grid cell origin**: `(0, 0)` is the upper-left cell.
- **Y-axis**: decreasing Y moves **right** (Godot's inverted Y-axis).
- **X-axis**: increasing X moves **down**.
- **CELL_SIZE**: 64 pixels. Each cell spans `[center - 32, center + 32]` in both axes.
- **Rotation**: always a multiple of 90° (0°, 90°, 180°, 270°).

---

## Three-Level Data Model

### Level 1: CellData (the "what's placed" table)

Maps grid positions to segment IDs. This is the actual track layout.

| Field        | Type                             |
| ------------ | -------------------------------- |
| `position`   | `Vector2i` (X, Y in grid coords) |
| `segment_id` | `int`                            |

**Storage**: `Dictionary<Vector2i, int>`

### Level 2: Segment (the "how it's oriented" table)

One row per logical piece. Groups cells and defines orientation.

| Field         | Type                            |
| ------------- | ------------------------------- |
| `segment_id`  | `int`                           |
| `type_id`     | `int`                           |
| `orientation` | `int` (0, 90, 180, 270 degrees) |

**Storage**: `Dictionary<int, Segment>` where `Segment` is a Resource or dict.

### Level 3: SegmentType (the catalog — read-only)

Defines shape, cost, and connection points. Never modified at runtime.

| Field            | Type                                   |
| ---------------- | -------------------------------------- |
| `type_id`        | `int`                                  |
| `name`           | `String`                               |
| `pattern`        | `Array[Vector2i]` (local cell offsets) |
| `base_cost`      | `float`                                |
| `entrance_pairs` | `Array[EntrancePair]`                  |

**Storage**: `Array[SegmentType]` (could be a Resource file).

### EntrancePair

| Field       | Type                                     |
| ----------- | ---------------------------------------- |
| `cell`      | `Vector2i` (local offset within pattern) |
| `direction` | `String` (north/south/east/west)         |

---

## Segment Type Catalog

| type_id | Name         | Pattern                          | EntrancePairs                                            |
| ------- | ------------ | -------------------------------- | -------------------------------------------------------- |
| 1       | 1x1 straight | `[0,0]`                          | `([0,0,west], [0,0,east])`                               |
| 2       | 1x2 straight | `[0,0], [0,-1]`                  | `([0,0,west], [0,-1,east])`                              |
| 3       | 1x4 straight | `[0,0], [0,-1], [0,-2], [0,-3]`  | `([0,0,west], [0,-3,east])`                              |
| 4       | 1x1 cross    | `[0,0]`                          | `([0,0,west], [0,0,east])`, `([0,0,north], [0,0,south])` |
| 5       | 2x2 curve    | `[0,0], [0,-1], [-1,0], [-1,-1]` | `([-1,0,south], [0,-1,east])`                            |

---

## Rotation & Entrance Math

### Rotation Formula

For a 90° clockwise rotation:

```text
local_coord (x, y) → rotated_coord (-y, -x)
```

For cardinal directions:

```text
north → west, east → north, south → east, west → south
```

90° = 1 step clockwise, 180° = 2 steps, 270° = 3 steps (or 1 step CCW).

### Mapping: Local → Rotated Local → Data Coordinate

1. **Rotate** the local cell offset using orientation.
2. **Add** the segment origin (first cell's data position).
3. **Rotate** the entrance direction using orientation.

### Example: Segment 123 (2x2 curve, 90° orientation, origin at -10,-19)

| Local Cell | Rotated Local | Data Coord | Direction | Rotated Direction |
| ---------- | ------------- | ---------- | --------- | ----------------- |
| [-1,0]     | [0,0]         | [-10,-19]  | south     | west              |
| [0,-1]     | [-1,-1]       | [-11,-20]  | east      | south             |

**Entrance pair after rotation:**

- `[-1,0,south] → [0,0,west] → [-10,-19,west]` (abuts [-10,-18,east] from segment 234)
- `[0,-1,east] → [-1,-1,south] → [-11,-20,south]` (abuts [-11,-20,south] from segment 444... self-abut)

### Example: Segment 234 (1x2 straight, 0° orientation, origin at -10,-18)

No rotation needed. Entrance pair maps directly:

- `[0,0,west] → [-10,-18,west]` (open — track start)
- `[0,-1,east] → [-10,-17,east]` (abuts [-10,-19,west] from segment 123)

### Example: Segment 444 (1x4 straight, 90° orientation, origin at -12,-20)

| Local Cell | Rotated Local | Data Coord |
| ---------- | ------------- | ---------- |
| [0,0]      | [0,0]         | [-12,-20]  |
| [0,-1]     | [-1,0]        | [-13,-20]  |
| [0,-2]     | [-2,0]        | [-14,-20]  |
| [0,-3]     | [-3,0]        | [-15,-20]  |

**Entrance pair after rotation:**

- `[0,0,west] → [0,0,north] → [-12,-20,north]` (abuts [-11,-20,south] from segment 123)
- `[0,-3,east] → [-3,0,south] → [-14,-20,south]` (open — track end)

---

## Connection Validation

Two segments are **connected** when:

1. They share an adjacent grid cell (distance 1 in either axis)
2. Their entrance directions at the shared boundary are **opposite** (west ↔ east, north ↔ south)
3. One entrance is the "open" end of the placement (new segment) and the other is already placed

---

## Path Building Strategy

When switching from PlaceMode to GameMode, `TrackPathBuilder` generates a `Path2D` from the data:

1. **Group cells by segment_id**
2. **For each segment**, look up its `type_id` and `orientation` from the Segment table
3. **Generate path geometry**:
   - **Straight**: `line_to()` from first cell's center to last cell's center
   - **1x1 curve**: `curve_to()` with a 90° arc (radius 32, centered on the curve's grid cell)
   - **2x2 curve**: `curve_to()` with a 90° arc (radius 64, centered at the inner corner of the 2x2 block)
   - **Cross**: two overlapping paths; the path builder follows one path through the crossing (game logic determines which)
4. **Join all segments** into a single continuous `Path2D` using segment order (connection chain)
5. **Validate**: path length > 0, no discontinuities at segment boundaries

**Key**: The path builder reads the data model. It does not compute positions from patterns — it uses actual cell positions from the CellData table.

---

## Rendering Strategy

### PlaceMode

`TrackRenderer` reads the CellData table directly and draws:

- Grid cells with segment graphics based on `segment_id` → `SegmentType`
- Preview of next segment being placed (ghost graphic at mouse position)
- Entrance markers at open ends (where new segments can be placed)

### GameMode

- `Path2D` is visible (for debugging)
- `TrackRenderer` continues drawing from CellData (no change)
- Train and cars move along `Path2D` using `PathFollow2D`

---

## GDScript Type Mappings

| Concept      | GDScript Type                                                                                                                                          |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| CellData     | `Dictionary<Vector2i, int>` (position → segment_id)                                                                                                    |
| Segment      | `Resource` (extends `RefCounted`): `id: int`, `type_id: int`, `orientation: int`                                                                       |
| SegmentType  | `Resource` (extends `RefCounted`): `id: int`, `name: String`, `pattern: PackedVector2Array`, `base_cost: float`, `entrance_pairs: Array[EntrancePair]` |
| EntrancePair | `Dictionary` with `cell: Vector2i`, `direction: String`                                                                                                |
| Rotation     | `int` (0, 90, 180, 270)                                                                                                                                |

**SegmentType catalog**: Stored as a `.tres` resource file loaded once at game start.

---

## Testing Strategy

### Unit Tests (GUT)

1. **Rotation math**: Verify `rotate_coord(local_coord, degrees)` for all 4 rotations
2. **Entrance mapping**: Verify `rotate_entrance(entrance, degrees)` produces correct data coords
3. **Connection validation**: Verify two segments are connected iff their entrance directions are opposite and cells are adjacent
4. **Path builder**: Verify `Path2D` is generated correctly for each segment type in isolation
5. **Mode-switch invariant**: Verify train position/orientation is unchanged when switching PlaceMode → GameMode

### Integration Tests

1. **Full track**: Build a track with straights, curves, and crossings. Verify path is continuous.
2. **Train movement**: Train moves from start to end along the generated path without jitter.
3. **Car coupling**: Cars follow the path behind the engine at correct coupling offsets.

---

## Task Breakdown

### Task 4a — Data Model

Implement the three-level data model: CellData, Segment, SegmentType, EntrancePair. Implement rotation and entrance-pair math. Tests for rotation and connection validation.

### Task 4b — Track Path Builder

Implement `TrackPathBuilder` to generate `Path2D` from the data model. Build path segments for straights, 1x1 curves, 2x2 curves, and crossings. Tests for path correctness.

### Task 4c — Renderer Update

Update `TrackRenderer` to draw from the data model in PlaceMode. Draw preview graphics, entrance markers, and ghost segments. No Path2D needed for PlaceMode visuals.

### Task 4d — Train Migration

Migrate `train.gd` to use `PathFollow2D` for movement. Cars follow the same Path2D offset by coupling distance. Tests for mode-switch invariant and smooth movement.

---

## Risks & Mitigations

| Risk                                                                       | Impact                               | Mitigation                                                                    |
| -------------------------------------------------------------------------- | ------------------------------------ | ----------------------------------------------------------------------------- |
| Path2D simplification produces discontinuous splines at segment boundaries | Jitter at segment transitions        | Use explicit line/curve segments, no automatic smoothing                      |
| PathFollow2D offset for car coupling is limited                            | Cars can't maintain correct distance | Use separate PathFollow2D per car, each with its own progress offset          |
| Mode-switch causes visible train position jump                             | Player notices train teleporting     | Store train's path progress; recalculate at mode switch but maintain progress |
| New segment types require special-casing in path builder                   | Path builder becomes complex         | SegmentType catalog drives path geometry; path builder reads type metadata    |

---

## Out of Scope

- Track editor UI (placement interface)
- Save/load for new data model
- Animation or polish on segment placement
- Tooltips or labels for segments
- Undo/redo system (planned for later tasks)
