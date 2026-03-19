# Conflict Resolution Engine (CRE) v2.0

Full RPG rules system WoW addon for the **Iron Circle** RP guild.

---

## Overview

The **Conflict Resolution Engine** (CRE) is a World of Warcraft addon that implements a complete tabletop-style RPG rules system on top of WoW's social/RP layer. It provides:

- **Character Profiles** — per-character saved profiles with attributes, class, armor, and traits
- **Dice Roller** — standard dice (d4–d100), custom expressions (`2d6+3`, `4d6k3`), advantage/disadvantage
- **Combat Tracker** — initiative, attack rolls, damage reduction, strike (HP) bar, ability use tracking
- **Traits Browser** — searchable list of all 32 passive and active traits; add/remove to profile
- **Quick Reference** — in-game browser for classes, armor table, attributes, and combat rules

---

## Installation

1. Download or clone the repository.
2. Copy the `ConflictResolutionEngine/` folder into your WoW `Interface/AddOns/` directory.
3. Reload WoW or type `/reload`.

---

## Slash Commands

| Command | Action |
|---------|--------|
| `/cre` or `/conflictengine` | Toggle the main window |
| `/cre roll <expr>` | Quick roll (e.g., `/cre roll 2d6+3`) |
| `/cre attack <melee\|ranged> [vs <defense>]` | Roll attack with active profile |
| `/cre init` | Roll initiative with active profile |
| `/cre dr [armor]` | Roll damage reduction |
| `/cre profile` | Print active profile summary to chat |
| `/cre reset` | Reset encounter (restore all ability uses) |
| `/cre export` | Export current profile string to chat |
| `/cre help` | Show command reference |

---

## Rules System

### Character Creation — The Nine Pillars

Characters distribute **10 attribute points** across nine attributes. No attribute may exceed **+6** at creation.

| Category | Attribute | Purpose |
|----------|-----------|---------|
| Physical | **Might** | Melee attacks, strength checks |
| Physical | **Finesse** | Defense, ranged attacks, stealth |
| Physical | **Endurance** | Inventory slots, poison/disease saves |
| Mental | **Insight** | Knowledge rolls, literacy |
| Mental | **Resolve** | Fear/morale/mind saves, tracking |
| Social | **Presence** | Reaction, persuasion, hirelings |
| Divine/Arcane | **Faith** | Divine abilities, saves vs malevolent |
| Divine/Arcane | **Magick** | Spellcasting, saves vs magical |
| Fortune | **Luck** | Favorable uncertain outcomes |

### Defense & Combat

- **Defense Score** = Finesse + 5 + Armor Defense Bonus
- **Attack Roll** = d20 + Might (melee) or Finesse (ranged) vs Defense
- **Damage Reduction** = Roll d6 after being hit; if result ≤ armor DR range, reduce by 1 Strike
- **Initiative** = d20 + Finesse (+ 1 if Tactician trait)

### Armor Table

| Armor | Defense Bonus | DR Range | Notes |
|-------|-------------|----------|-------|
| None | +0 | — | No protection |
| Leather | +1 | 1 | Light, no penalties |
| Chain | +2 | 1–2 | Disadvantage on stealth |
| Plate | +3 | 1–3 | Disadvantage on stealth, −1 Finesse checks |
| Shield | +1 | — | Enables Shield Bash, off-hand |

### WoW Classes (13)

Warrior, Rogue, Hunter, Paladin, Priest, Mage, Warlock, Druid, Shaman, Death Knight, Evoker, Demon Hunter, Monk — each with unique flavor, strike count, and 3 signature abilities.

### Traits (32 total)

**16 Passive** (always active) and **16 Active** (limited uses per encounter). See the Traits tab in-game for full descriptions.

---

## File Structure

```
ConflictResolutionEngine/
├── ConflictResolutionEngine.toc   — Addon manifest (Interface 120001)
├── Utils.lua                       — Color helpers, printing, string utilities
├── Data.lua                        — All rules constants
├── Profiles.lua                    — Profile CRUD, export/import
├── Dice.lua                        — Dice engine and expression parser
├── Combat.lua                      — Attack, DR, initiative, strike tracking
├── Core.lua                        — Addon init, events, slash commands
├── UI.lua                          — Main frame, tabs, minimap button
├── UI_Profile.lua                  — Profile tab
├── UI_Dice.lua                     — Dice roller tab
├── UI_Combat.lua                   — Combat tracker tab
├── UI_Traits.lua                   — Traits browser tab
└── UI_Reference.lua                — Quick reference tab
```

---

## SavedVariables

- `ConflictResolutionEngineDB` — Global/shared settings (window position, chat channel, minimap position)
- `ConflictResolutionEngineCharDB` — Per-character profiles and active profile selection

---

## Requirements

- WoW Retail (Midnight) — Interface **120001**
- No external library dependencies

