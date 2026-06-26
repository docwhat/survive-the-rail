# Product Brief

> What is being built and why.

## Overview

A bullet-heaven game where you lay track, drive a train, and your cars auto-fire at approaching enemies. Inspired by Vampire Survivors but on rails — literally.

## Genre

Bullet-heaven / train survival hybrid.

## Core Loop

1. **Lay track** — Spend resources to place track segments as money is collected.
    1. Use track layout to avoid stationary mini-boss enemies.
    1. Use track layout to reach goals in the world. Treasure, stations, repair yards, etc.
    1. Use track layout to avoid obstacles.
1. **Drive the train** — Control throttle and brakes as the train moves along your track.
    1. **Auto-fire** — Train cars shoot at enemies automatically.
    1. **Collect Money** — Earn money kills and meeting goals. Money can be used to buy track.
    1. **Kill enemies** - Killing enemies earns XP. XP is used to level up. Each level up gives the player a choice of 3-4 upgrades to the train.
    1. **Die** — Death isn't the end. You can use meta-currancy to buy permanent upgrades.

## Player Fantasy

You are a train conductor in a hostile world, building your own defensive railway empire. You have control of a mobile fortress that can defend itself.

## Audience

Gamers who enjoy bullet-heaven games (Vampire Survivors, Brotato) and train games. Primary audience is the creator, with sharing to friends/family.

## References

- **Vampire Survivors** — auto-fire, upgrade choices, wave survival
- **Trainatic** - Upgrade your cars, gather resources, and unlock powerful synergies to chug further down the track.

## MVP (v1)

Goals for the MVP:

- drive train
- lay track
- enemies spawn
- cars auto-fire
- XP can be collected
- We can choose upgrades
- Player can die

## MVP (v1) non-goals

Things we won't do for the MVP:

- Meta-currancy and permanant upgrades
- Money and track pricing
- Treasure
- Mini-bosses
- Goals
- Multiple worlds/areas
- Complex worldbuilding/story
- Big Bosses
- Non-enemy track-altering entities
- Repair Yards

## MVP (v1) Build Targets

- macOS (native binary)
- Linux (native binary)
- Windows (native binary)
- WASM (auto-deployed to GitHub Pages)

## Art & Audio

- 2D graphics
- Screen Size: 1280x720
- Based around 32x32 tiles
- For the MVP (v1) we will use placeholder graphics. Artists will be brought in later.
- For the MVP (v1) we will use simple sound effects. Sound effects will be procured later.
- Text is translation-ready from the start

## Performance

- Polish pass includes performance measurements (frame rate, memory, WASM load time)
- Target: 60 FPS minimum on target platforms, WASM page load under 5 seconds
