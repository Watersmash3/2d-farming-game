# 🌱 Project Title (Working Name)

A 2D top-down farming and exploration game where players restore a forgotten land by growing crops, exploring nearby areas, and unlocking machines and limited vehicles that automate their farm over time.

## 🎮 Game Overview

Players begin with a small manual farm and gradually expand their operation by discovering new resources, blueprints, and tools through exploration. Automation becomes a key form of progression, allowing players to transition from individual tile interactions to machine-assisted farming.

**Genre:** 2D Top-Down Farming / Exploration
**Engine:** Godot 4.x
**Platform:** PC

## 🔁 Core Gameplay Loop

Farm → Explore → Find Resources & Blueprints → Build Automation → Farm Faster → Unlock New Areas

## ⭐ Key Features

- Tile-based top-down movement
- Farming system (till, plant, grow, harvest)
- Time/day progression
- Simple inventory system
- Automation machines (auto-waterer, seeder, harvester, etc.)
- Limited-use farming vehicle (tractor-style tool)
- Exploration zones (forest, caves, ruins)

## 📁 Project Structure
```
assets/        → Art, audio, tilesets
scenes/        → Godot scenes (player, world, UI, farm, etc.)
scripts/       → Game logic
  core/        → Autoload singletons (TimeSystem, Inventory, GameState)
  systems/     → Farming, automation, interaction, etc.
data/          → JSON or resources for crops, items, machines
```

## 🛠️ Setup Instructions

1. Install Godot 4.x
2. Clone the repository:
```
git clone https://github.com/YOURNAME/REPO_NAME.git
```
3. Open Godot → Import Project → Select the folder → Open
4. Run the project

## 🌿 Git Workflow
### Branching

main → Always stable/playable

### Feature branches:

```
feature/player-movement
feature/farming-core
feature/time-system
feature/automation-poc
```
### Creating a Branch
```
git checkout -b feature/your-feature
```
### Pushing Changes
```
git add .
git commit -m "Short description of change"
git push origin feature/your-feature
```

Open a Pull Request to merge into main.

## 🔒 Merge Rules

- Project opens without errors
- Feature works as described
- No committing directly to main
- One person owns each scene to avoid conflicts

## ⚠️ Godot Collaboration Tips

- Avoid multiple people editing the same .tscn scene
- Use small, focused commits
- Don’t commit .godot/ or .import/ folders
- Store global systems as Autoloads
- Prefer signals over hard references

## 👥 Team Roles (Milestone 1)

- Player Movement & Input
- World & TileMaps
- Farming System
- Time, Inventory, & Automation

## 🚧 Current Milestone Goal

- Deliver a playable prototype where the player can:
- Move
- Till soil
- Plant and grow crops
- Advance time
- Harvest crops
- Place one automation object

## 📌 Future Ideas (Stretch)

- NPCs and dialogue
- More machines
- Crafting system
- Story elements
- Map expansion