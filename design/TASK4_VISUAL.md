# Task 4 - Visual Layer Implementation Plan

## Goal

Make the game visible and playable. The data models (`Train`, `Car`, `Track`, `TrackSegment`) are complete. We need scene nodes + renderers to display them.

## Architecture Principle

- **Data models** (`Train`, `Car`, `Track`, `TrackSegment`): Pure classes, no Godot dependencies, fully testable with GUT.
- **Renderer nodes**: Extend `Node2D`, read data from models, draw using Godot primitives (`DrawAction`, `CanvasItem.draw_circle`, `CanvasItem.draw_line`).
- **No scene-to-scene references**: Renderers hold references to data models, not scenes.

## Scene Structure

````gdscript
main.tscn (Node2D)
├── Camera2D (follows train)
├── TrainRenderer (Node2D, extends train_renderer.gd)
│   ├── EngineSprite (Sprite2D, or use draw() via Draw node)
│   └── Cars (Array of CarSprite nodes)
├── TrackRenderer (Node2D, extends track_renderer.gd)
│   └── (draws via _draw())
└── UIDisplay (CanvasLayer)
    └── speed label, health bar, resources
```gdscript

## Files to Create/Modify

### 1. `train_renderer.gd` (NEW)

- Extends `Node2D`
- Holds reference to `Train` data model
- `_draw()` renders the train:
  - Engine: rectangle with direction indicator
  - Cars: smaller rectangles behind engine, with pivot rotation
  - Orientation rotates the entire sprite
- Connects to train's `position`, `speed`, `health` changes
- Computes car pivot angles from current segment curve

### 2. `track_renderer.gd` (NEW)

- Extends `Node2D`
- Holds reference to `Track` data model
- `_draw()` renders track segments:
  - Straight segments: gray rectangles
  - Curve segments: curved shapes
  - Grid lines for reference
- Uses `CELL_SIZE = 64` to map grid positions to pixels

### 3. `main.tscn` (MODIFY)

- Scene root: `Node2D` named "Main"
  - `Camera2D` child
  - `TrainRenderer` child (script: `train_renderer.gd`)
  - `TrackRenderer` child (script: `track_renderer.gd`)
  - `CanvasLayer` with `UIDisplay` child
- `main.gd` (MODIFY)
  - In `_ready()`: connect scene nodes to data models
  - In `_process()`: call renderer update methods
  - Camera follows train position

### 4. `ui_renderer.gd` (NEW)

- Extends `CanvasLayer` or `Control`
- Displays: speed, health, resources, phase
- Uses labels and a progress bar

## Visual Style

- Simple placeholder graphics using `CanvasItem.draw_*` methods
- Train engine: red rectangle, 32x16 pixels, arrow pointing in travel direction
- Cars: blue rectangles, 24x12 pixels
- Track: gray lines/blocks on green background
- HUD: white text overlay showing speed (km/h), health bar

## Godot Primitives Approach

Use `CanvasItem._draw()` for rendering. No sprite textures needed — use:

- `draw_rect()` for rectangles
- `draw_line()` for lines
- `draw_circle()` for circles
- `draw_string()` for text (or use Label nodes)

This keeps everything self-contained with no external assets.

## Acceptance Criteria

- Running Godot shows a visible train on a visible track
- W/Up throttle makes the train accelerate visually
- S/Down/Space brake slows it down
- Train rotation matches track segment orientation
- Cars pivot when entering curves
- HUD shows speed and health
- Game is playable with keyboard alone
````
