# Graphics Decision

> Resolution, format, sizing, and placeholder strategy for Survive the Rail.

## Summary

**Procedural vector graphics with text labels.** All rendering done via Godot CanvasItem `_draw()` calls. No image files needed. Placeholder graphics are visually distinct by shape, color, and label so a human with eyeballs can instantly tell what's what.

## Resolution

- **Viewport:** 1280×720 (16:9, landscape) — set in `project.godot`
- **Internal resolution:** Same as viewport. No pixel-shrink approach at this stage.
- **Stretch mode:** `canvas_items`, aspect = `expand` (letterbox/pillarbox as needed)

## Format

**Vector / procedural.** All game entities are drawn at runtime via `CanvasItem.draw_*()` methods. No PNG, SVG, or other image files.

- **Track segments:** Lines and filled rectangles forming rails and sleepers
- **Train engine:** Rounded rectangle with smokestack textural marks
- **Cars:** Colored rectangles with text labels ("G" for gun, "C" for cannon, "B" for booster)
- **Enemies:** Distinct shapes (circle = basic, diamond = special)
- **Projectiles:** Small filled circles
- **XP pickups:** Diamond shapes with "XP" label
- **Chests:** Rounded rectangles with "C" label

## Scale & World Units

The physics system uses abstract world units (the same units used in `physics.gd`). Graphics scale 1:1 with these units.

- **Grid cell size:** 64 units per cell (track segment length)
- **Track segment visual:** ~60×24 (body with rail lines)
- **Train engine:** 48×32
- **Car:** 32×20
- **Enemy basic:** 24×24 (circle radius ~12)
- **Enemy special:** 28×28 (diamond diagonal ~28)
- **Projectile:** 6×6 (circle radius ~3)
- **XP pickup:** 8×8 (diamond radius ~4)
- **Chest:** 20×16

These dimensions give a comfortable view on a 1280×720 screen — entities are large enough to see and interact with at a glance.

## Color Palette (Distinct by Role)

| Entity          | Fill Color                                 | Stroke Color | Shape                    | Text Label  |
| --------------- | ------------------------------------------ | ------------ | ------------------------ | ----------- |
| Track (placed)  | `#2a2a2a` (dark gray)                      | `#888888`    | Rail lines + filled ties | None needed |
| Track (preview) | `#4a4a4a` (lighter gray, semi-transparent) | `#aaaaaa`    | Same as placed           | "PLACE?"    |
| Train engine    | `#2266cc` (blue)                           | `#114488`    | Rounded rect             | "E"         |
| Car (gun)       | `#cc2222` (red)                            | `#881111`    | Rect                     | "G"         |
| Car (cannon)    | `#cc6622` (orange)                         | `#884411`    | Rect                     | "C"         |
| Car (booster)   | `#22cc66` (green)                          | `#118844`    | Rect                     | "B"         |
| Car (cargo)     | `#888822` (yellow)                         | `#555511`    | Rect                     | "R"         |
| Enemy basic     | `#cc2266` (pink)                           | `#881144`    | Circle                   | "E"         |
| Enemy special   | `#cc22cc` (magenta)                        | `#881188`    | Diamond                  | "S"         |
| Projectile      | `#ffff22` (yellow)                         | `#aaaa11`    | Circle                   | None        |
| XP pickup       | `#22cccc` (cyan)                           | `#118888`    | Diamond                  | "XP"        |
| Chest           | `#cc8822` (gold)                           | `#885511`    | Rounded rect             | "C"         |

The palette is deliberately high-contrast and color-differentiated. Even if someone is playing without color vision, the shapes and text labels disambiguate everything.

## Text Labels

Each entity that benefits from identification gets a short, single-character or abbreviated label drawn in white (or dark on light backgrounds), centered on the entity:

- **Engine:** "E"
- **Car — gun:** "G"
- **Car — cannon:** "C"
- **Car — booster:** "B"
- **Car — cargo (resource):** "R"
- **Enemy basic:** "E"
- **Enemy special:** "S"
- **Track preview:** "PLACE?"
- **XP pickup:** "XP"
- **Chest:** "C"

Labels are drawn at a fixed font size (scaled to fit the entity). We use Godot's built-in font — no custom font files needed.

## Replacing Placeholders Later

When real art arrives, each game scene node has a `_is_placeholder: bool` field. Set it to `false` and load the corresponding `Texture2D` resource. The `_draw()` methods check this flag:

```gdscript
func _draw() -> void:
	if not _is_placeholder:
		# Sprite-based rendering (replaced by artist)
		return
	# Procedural draw calls ...
```

No structural changes to the scene tree are needed — just swap the rendering path.

## References

- `design/BUILD_PLAN.md` — Task 3 (track) and Task 14 (UI/entities)
- `design/ARCHITECTURE.md` — "Track Segments (Graphic Assets)" section
- `design/PRODUCT_BRIEF.md` — "Art & Audio" section
