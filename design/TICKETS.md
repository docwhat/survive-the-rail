# Tickets

> A record of tickets (prompts) used per session or thought as being useful.

## Initial Planning

You are an expert game developer, architect and game product manager.

I have a rough concept for a new coding project, but I need a solid plan
before I ask AI to write code.

To build this plan, we will use an iterative 20-Questions-style specification
framework.

Instead of me giving you all the details at once, ask me questions we can
define the scope and requirements.

You'll ask for clarification when needed.

Once we finish answering the questions, concisely summarize our conversation by
generating the 6 files that will map out our project.

### Files

Each file should already have some minimal information at the top of each file about what each file should contain.

- `PRODUCT_BRIEF.md`
- `USER_STORIES.md`
- `ARCHITECTURE.md`
- `BUILD_PLAN.md` -- This is the ordered list of tasks that need be done one by one with an AI agent.
- `TICKETS.md`
- `TEST_PLAN.md`

### Questions

#### Round 1 - Vision and Scope

1. One-sentence description? Should include genre, core action, and unique hook.
1. Reference to a similar app, game, or tool?
1. Who is this for? What is the player fantasy? What hooks the player?
1. Minimum viable thing that proves the concept?

#### Round 2 - Tech Stack

1. Language and framework?
1. External libraries allowed? If yes, which?
1. File structure (single file or multiple)?
1. Build tools, or "just open the file"?

#### Round 3 - Mechanics and Behavior

1. Core interactions?
1. State: What data persists? What data is deleted after a session?
1. Failure modes?
1. Success conditions?
1. What should the model NOT do?

#### Round 4 - Scope Discipline

1. V1 features?
1. How do we know when we have finished V1?
1. What's in the "If I have time" pile?
1. Will there be a polish pass?

#### Round 5 - Build Discipline

1. Order of operations: what blocks what?
1. Test plan per task?
1. Escalation: What triggers a need for the task to be sent back to the architect mid-build?

## Session Tickets

### Session: Initial Planning (2026-06-01)

**Goal:** Generate 6 spec files for survive-the-rail.

**Result:** All 6 files generated. Build plan has 15 tasks.

**Key decisions:**
- Godot + GDScript
- G.U.I.D.E for input, GUT for testing
- Flat file structure, mise + trunk for tooling
- Physics → Track → Train → (Keyboard) → (G.U.I.D.E) → Cars (weapons + utilities) → Enemies → Projectiles → Damage → Upgrades → Chests → Save → Settings → UI → Audio → Build Targets → CI/CD → Polish

## Session: Build Targets Update (2026-06-01)

**Goal:** Add macOS, Linux, Windows, WASM build targets to V1. WASM auto-deploys to GitHub Pages. Polish includes performance measurements.

**Changes:**
- PRODUCT_BRIEF.md: Added "Build Targets (V1)" and "Performance" sections
- ARCHITECTURE.md: Added build targets to tech stack, added risks for WASM, cross-platform, and performance
- BUILD_PLAN.md: Added Task 15 (Build Targets), Task 16 (CI/CD Pipeline), renumbered Polish to Task 17
- TEST_PLAN.md: Added Build & CI Tests table, Performance Measurements table
- TICKETS.md: This session recorded

## Session: Train Controls Split (2026-06-01)

**Goal:** Split Task 4 (Train Controls) into keyboard-only (Task 4) and G.U.I.D.E + controllers (Task 5).

**Changes:**
- BUILD_PLAN.md: Split Task 4 into "Train Controls (Keyboard)" and "Train Controls (G.U.I.D.E + Controllers)". Renumbered Tasks 5-17 to 6-18.
- TICKETS.md: This session recorded

## Session: Build Directory & .gitignore (2026-06-01)

**Goal:** Build outputs go into `build/` directory, which is gitignored.

**Changes:**
- `.gitignore`: Created with `build/`, Godot imports, OS files, IDE files
- BUILD_PLAN.md: Updated Task 16 acceptance criteria to output to `build/{platform}/` paths
- TICKETS.md: This session recorded

## Session: Utility Cars (2026-06-01)

**Goal:** Clarify that cars can be utility (non-weapon) for bonuses like speed, power, capacity.

**Changes:**
- ARCHITECTURE.md: Added `car_category` (Weapon/Utility) to Car model, renamed "Car Weapon System" to "Car System", added utility bonuses to Upgrade model
- BUILD_PLAN.md: Task 6 updated to include utility cars (at least 2 types), `car_utility.gd`, utility bonus GUT tests
- TICKETS.md: This session recorded

## Session: Segment-Based Track (2026-06-01)

**Goal:** Track placement based on discrete segments (like a child's train set) for simpler graphics and easier train animation.

**Changes:**
- ARCHITECTURE.md: Track system now segment-based (straight, curve_left, curve_right). Added TrackSegment data model. Added "Track Segments (Graphic Assets)" section (3 base graphics). Train moves segment-by-segment, rotation snaps to segment orientation. Renumbered systems 3-8.
- BUILD_PLAN.md: Task 3 updated for grid-based segment placement with preview. Task 4 updated for segment-by-segment movement and rotation snapping.
- TICKETS.md: This session recorded

## Session: Auto-Aim & Targeting Modes (2026-06-01)

**Goal:** Cars auto-aim (not just auto-fire). Targeting modes set at car acquisition, not toggleable during gameplay.

**Decision:** No mid-game targeting mode cycling. Keeps the auto-combat fantasy intact. Targeting modes (nearest, farthest, healthiest, weakest) are chosen via upgrades when acquiring a car.

**Changes:**
- ARCHITECTURE.md: Car system updated to auto-aim. Targeting mode added to Car model and Upgrade model. "change_targeting_mode" added as an UpgradeEffect.
- BUILD_PLAN.md: Task 6 updated for auto-aim, targeting modes, and GUT tests for targeting logic.
- TICKETS.md: This session recorded

## Session: Train-Like Physics (2026-06-01)

**Goal:** The train should feel like a train — weight scaling and bogie/pivot animation.

**Key details:**
- **Weight scaling:** More cars = slower acceleration, longer braking distance. Engine-only is snappy; full train is sluggish and powerful.
- **Bogie/pivot animation:** Cars pivot over bogies (trucks) when entering curves. Each car has two bogies (near front/back, not at edges). Bogies swivel to follow track; car body rotates over bogies. Couplers transmit force but are not the pivot. This is what most train games get wrong.

**Changes:**
- ARCHITECTURE.md: Train model updated with total_weight, engine_power. Car model updated with weight, bogie_offset, body_rotation, bogie_orientation. Train Physics section expanded with weight scaling and bogie/pivot details.
- BUILD_PLAN.md: Task 2 updated with weight scaling formula and GUT tests. Task 4 updated with bogie/pivot animation, car.gd pivot fields, and escalation triggers for pivot math.
- TICKETS.md: This session recorded

## Session: Bogie Correction (2026-06-01)

**Goal:** Correct the pivot mechanic — bogies are the pivots, not couplers.

**Correction:**
- Each car has two bogies (trucks), one near front and one near back (not at edges)
- Bogies swivel to follow track curvature; car body rotates over bogies
- Couplers connect cars at ends and transmit force, but are NOT the pivot point
- This creates the characteristic train car angle on curves

**Changes:**
- ARCHITECTURE.md: Car model updated (bogie_offset, body_rotation, bogie_orientation). Pivot animation corrected.
- BUILD_PLAN.md: Task 4 updated to describe bogie/pivot correctly.
- TICKETS.md: This session recorded

## Session: Queble Weapon System Reference (2026-06-01)

**Goal:** Research Queble's modular weapon system for car/weapon design ideas.

**Reference:** Queble — "Complex (yet modular) weapon system" — https://youtu.be/a5GJcgdSEQo?si=AilvTcwI7jGYIXXA
- Modular weapon architecture
- Upgradeable weapon components and effects
- To study: how to make weapons feel complex but remain modular and composable

**Changes:**
- ARCHITECTURE.md: Added to References & Inspiration section
- TICKETS.md: This session recorded

## Session: 2D Decision (2026-06-01)

**Goal:** Decide on 2D vs 3D vs 2D-in-3D for the game engine.

**Decision: 2D (Godot's 2D engine).** Reasons:
- No Z-axis to worry about (enemy height, bullet trajectories, occlusion)
- Simpler animation — sprites, no 3D rigging
- Easier to learn for a first Godot project
- Bogie pivot can be faked in 2D (car rotates around offset pivot point)
- The bogie detail is a nice-to-have, not a core mechanic
- Bigger wins are weight scaling, auto-aim, track laying, upgrade loop — none care about 2D vs 3D

**Changes:**
- ARCHITECTURE.md: Physics section updated to specify 2D. Bogie animation simplified to 2D rotation around offset pivot. Car model simplified (removed bogie_orientation).
- BUILD_PLAN.md: Task 2 updated to specify 2D physics. Task 4 updated to describe 2D bogie pivot.
- TICKETS.md: This session recorded

## Session: Final Design Decisions (2026-06-01)

**Goal:** Resolve remaining escalation triggers before implementation.

**Decisions:**
- **Track grid:** Infinite field. Bounded only by max track length.
- **Segment connectivity:** Track must be continuous. Starts at a fixed train yard. New segments can only be added from the current track end.
- **XP collection:** Hover over XP pickups to collect (mouse or right analog stick via G.U.I.D.E).
- **Story pacing:** V1 is flavor lines only. World building/narrative beats come later if project continues.
- **Game over transition:** Pop up a dialog box with metrics. Enemies continue in slow motion (1/4 speed) in the background — the iron horse keeps beating the dead.

**Changes:**
- ARCHITECTURE.md: GameState updated with track_start. Track System updated with train yard, continuous path, infinite grid.
- BUILD_PLAN.md: Task 3 updated for train yard + continuous path. Task 9 updated for hover XP collection + game over dialog + slow-motion enemies. Task 14 updated for flavor lines only.
- TICKETS.md: This session recorded
