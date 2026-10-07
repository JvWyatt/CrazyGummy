# Crazy Gummy - Agent Instructions

Juego móvil incremental de procesar cubos de gelatina y producir gomitas, en Godot 4.x (GDScript).
Leer `docs/INFORME_GLOBAL.md` antes de trabajar: informe global único con arquitectura,
terminología oficial, pantallas, balance, sistema visual de cartas, referencias históricas
y la sección «Migración desde Crazy Fruit».

## Project Overview

- **Engine:** Godot 4.x (project.godot declara 4.7), GL Compatibility renderer
- **Language:** GDScript
- **Platform:** Mobile-first (Android), 720x1280 portrait
- **Genre:** Incremental por negocios/días con golpes mediante trazos

## Architecture

- **7 autoloads:** SaveManager, StatsManager, SoundManager, GameManager, UiTheme, SettingsManager, AchievementManager
- **Split layout:** `scripts/` and `scenes/` separated into `game/`, `ui/`, `models/`, `autoload/` subdirectories
- **Data layer:** RecipeData, RecipeDatabase, ToolData, CardDatabase; catálogo en data/recipes/ y data/tools/
- **State machine:** GameManager.GameState + is_round_active + visibilidad controlada por Main; ver enum real y navegación en la guía

## Conventions

- All game text is in Spanish (es)
- Comments use Spanish with English code identifiers
- Signals follow `snake_changed` / `snake_event` patterns
- Autoloads access each other directly (e.g. `StatsManager.get_final_damage()`)
- Nombres visibles: Potencia, Dureza (cubo), Resistencia (jugador), Ritmo (cubos/s), Recetas y Gomitas.
- Arquitectura activa: GummyBlock, BlockSpawner, Projectile3D/Projectile3DWorld, recetas y herramientas con IDs canónicos.
- Guardado versionado: crazy_gummy_save.json (v2). Los aliases anteriores están aislados en scripts/models/SaveMigration.gd; no reintroducirlos en lógica activa.
- Conservar balance, IDs canónicos, señales, UID y referencias; cambios persistentes futuros requieren migración compatible. Ver sección «Migración desde Crazy Fruit» de `docs/INFORME_GLOBAL.md`.

## GodotPrompter

This is a Godot project with GodotPrompter skills available. Before implementing any game system, you MUST check for a matching `godot-prompter:*` skill and invoke it. This applies to all agents, subagents, and sessions working in this repository.

Key skills: `player-controller`, `state-machine`, `event-bus`, `scene-organization`, `component-system`, `resource-pattern`, `godot-ui`, `hud-system`, `ai-navigation`, `camera-system`, `audio-system`, `save-load`, `inventory-system`, `godot-testing`.

For the full skill list, invoke `godot-prompter:using-godot-prompter`.
