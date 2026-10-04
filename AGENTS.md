# Crazy Fruit - Agent Instructions

Incremental 2D fruit cutting mobile game built with Godot 4.5 (GDScript).

## Project Overview

- **Engine:** Godot 4.5, GL Compatibility renderer
- **Language:** GDScript
- **Platform:** Mobile-first (Android), 720x1280 portrait
- **Genre:** Incremental / idle with Fruit Ninja-style cutting mechanics

## Architecture

- **7 autoloads:** SaveManager, StatsManager, SoundManager, GameManager, UiTheme, SettingsManager, AchievementManager
- **Split layout:** `scripts/` and `scenes/` separated into `game/`, `ui/`, `models/`, `autoload/` subdirectories
- **Data layer:** Custom Resource-based models (FruitData, FruitDatabase, CardDatabase)
- **State machine:** Enum-based GameManager.GameState controls flow between MENU, PLAYING, CARD_SELECT, UPGRADES, STATS, RESULTS

## Conventions

- All game text is in Spanish (es)
- Comments use Spanish with English code identifiers
- Signals follow `snake_changed` / `snake_event` patterns
- Autoloads access each other directly (e.g. `StatsManager.get_final_damage()`)

## GodotPrompter

This is a Godot project with GodotPrompter skills available. Before implementing any game system, you MUST check for a matching `godot-prompter:*` skill and invoke it. This applies to all agents, subagents, and sessions working in this repository.

Key skills: `player-controller`, `state-machine`, `event-bus`, `scene-organization`, `component-system`, `resource-pattern`, `godot-ui`, `hud-system`, `ai-navigation`, `camera-system`, `audio-system`, `save-load`, `inventory-system`, `godot-testing`.

For the full skill list, invoke `godot-prompter:using-godot-prompter`.
