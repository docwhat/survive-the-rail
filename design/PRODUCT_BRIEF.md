# Product Brief

> What is being built and why.

## Overview

A bullet-heaven game where you lay track, drive a train, and your cars auto-fire at approaching enemies. Inspired by Vampire Survivors but on rails — literally.

## Genre

Bullet-heaven / train survival hybrid.

## Core Loop

1. **Lay track** — Spend resources to place track segments before each round.
2. **Drive the train** — Control throttle and brakes as the train moves along your track.
3. **Auto-fire** — Train cars shoot at enemies automatically.
4. **Collect & upgrade** — Earn XP/money from kills to choose upgrades (improve cars, add cars, extend track).
5. **Survive** — Special enemies drop chests with pre-selected rewards. Obstacles can derail you.
6. **Die or continue** — Train destroyed = game over, or save and continue.

## Player Fantasy

You are a train conductor in a hostile world, building your own defensive railway empire. You have control of a mobile fortress that can defend itself.

## Audience

Gamers who enjoy bullet-heaven games (Vampire Survivors, Brotato) and train games. Primary audience is the creator, with sharing to friends/family.

## References

- **Vampire Survivors** — auto-fire, upgrade choices, wave survival

## MVP

A playable round: lay track → drive train → enemies spawn → cars auto-fire → collect XP → choose upgrades → survive or die → restart.

## Build Targets (V1)

- macOS (native binary)
- Linux (native binary)
- Windows (native binary)
- WASM (auto-deployed to GitHub Pages)

## Non-Goals (V1)

- Multiple worlds/areas
- Complex worldbuilding/story
- Bosses
- Non-enemy track-altering entities
- Multiplayer
- iOS/Android builds (post-V1)

## Art & Audio

- Minimal placeholder graphics (for an artist to fill in later)
- Basic sound effects (to be improved later)
- Text is translation-ready from the start
- Beginnings of a story woven into gameplay

## Performance

- Polish pass includes performance measurements (frame rate, memory, WASM load time)
- Target: 60 FPS on target platforms, WASM page load under 5 seconds
