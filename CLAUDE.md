# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Godot 4.x 2D top-down farming and exploration game. Core loop: Farm → Explore → Find Resources & Blueprints → Build Automation → Farm Faster → Unlock New Areas.

**Main scene**: `scenes/world/World.tscn` (controlled by `scripts/world/test.gd`)

## Development Setup & Commands

There is no build script or Makefile. Development is entirely through the Godot editor:

1. Install Godot 4.x
2. Open Godot → Import Project → select this folder
3. Run with **F5** in the editor

**No CI, no tests, no linter** — changes are verified by running the game.

## Architecture

### Autoloads (Global Singletons)

Registered in `project.godot`. Access by name from any script:

| Autoload Name | Script | Purpose |
|---|---|---|
| `InventoryState` | `scripts/core/inventory_state.gd` | Item counts, slot management, selection |
| `ProgressionManager` | `scripts/core/progression_manager.gd` | Blueprint unlock tracking |
| `AutomationManager` | `scripts/systems/automation_manager.gd` | Machine registry and placement |
| `Crafting` | `scripts/systems/crafting_system.gd` | Recipe execution |
| `TimeSystem` | `scripts/core/time.gd` via scene | Day/hour tick cycle |
| `BackgroundMusic` | `scenes/background_music.tscn` | Music player |

### Signal Flow

The day cycle drives most game logic:

```
TimeSystem.day_advanced
  → FarmingSystem       (age crops, reset water)
  → AutomationManager   (DEFERRED — runs after farming tick)
      → AutoWaterer.on_new_day (water orthogonal neighbors)
  → ProgressionManager  (harvest milestone check)

FarmingSystem.crop_harvested
  → ProgressionManager._on_crop_harvested
      (3 harvests → unlocks auto_waterer blueprint)

InventoryState.inventory_changed
  → InventoryUI, CraftingMenu (refresh displays)

Crafting.craft_succeeded / craft_failed
  → CraftingMenu (status message)
```

### Farming System (`scripts/systems/farming_system.gd`)

Tile-based farm state stored in a `farm_cells` dictionary keyed by `Vector2i` cell coordinates. Each cell tracks: `tilled`, `watered`, `crop_id`, `age`. Water resets every day — crops only age if watered. TileMap atlas coords: `(0,0)` = dry tilled, `(1,0)` = watered tilled.

### Automation Machines

`AutomationMachine` (base class in `scripts/automation/automation_machine.gd`) is extended by specific machines like `AutoWaterer`. Machines must be placed on tilled, cropless, unoccupied cells. `AutomationManager` uses `CONNECT_DEFERRED` so machines run after the farming system processes the day tick.

### Crafting & Progression

Recipes are defined in `scripts/data/crafting_recipes.gd` and are gated by blueprint IDs that `ProgressionManager` unlocks. The crafting flow checks: recipe exists → blueprint unlocked → ingredients available → deduct ingredients → add result.

### TimeTick Addon (`addons/time_tick/`)

A GDExtension that provides the `TimeTick` class for precise time stepping. `TimeService` wraps it. Tick duration: 0.25 seconds. 24 hours per day. The extension binaries for all platforms are in `addons/time_tick/bin/`.

## Key Input Actions (from `project.godot`)

| Action | Keys |
|---|---|
| `interact` | Space / Gamepad A |
| `toggle_inventory` | I |
| `toggle_crafting` | K |
| `place_machine` | P |
| `cancel_placement` | Esc / RMB |

## Debug Keys (in `test.gd`)

- **1–4**: Select tool (till, water, plant, harvest)
- **N**: Advance day manually
- **F9**: Unlock auto_waterer blueprint immediately
- **P**: Enter machine placement mode

## Collaboration Notes

- Avoid editing the same `.tscn` file as another contributor simultaneously (Godot scene format causes merge conflicts)
- `main` branch is always stable/playable
- Use `feature/your-feature` branches and open PRs to merge
- Do not commit `.godot/` or `.import/` folders
- Use autoloads for global state; prefer signals over direct node references
