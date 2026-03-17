## [5.1.1] - 2026-03-17  
**"The Stability Protocol"**

Version 5.1.1 is a critical stability hotfix focusing on **Engine Robustness** and **Object Synchronization**. This update eliminates "Ghost Signatures" (null-pointer crashes) that occurred during high-intensity boss encounters and ensures the Simulation Lab operates without failure.

---

### 🎯 Version 5.1.1 Focus

#### 🏗️ Architectural Integrity
- Transitioned from string-based type checking to **Strong Type Validation** (`-is [Class]`)  
- Prevents engine crashes when handling de-spawning entities  

#### 🏭 Entity Factory Synchronization
- Standardized naming conventions across **Battle Mode** and **EntityManager**  
- Ensures seamless boss summoning  

---

### 🐞 Fixed

#### 👻 The "Ghost Pride" Null-Pointer Crash
- Fixed an issue where **RealPride (Gatekeeper)** returned a null object  
- Caused by string mismatch: `"REAL PRIDE"` vs `"REALPRIDE"` when summoned via Battle Mode  

#### ⚙️ Collision Engine Desync
- Fixed error: `"You cannot call a method on a null-valued expression"` in **StageDirector**  
- Implemented **Safe-Type Checking** to filter null entities before processing boss logic  

#### 🧠 Session Memory Leak
- Resolved issue where `currentTrackedLevel` was not resetting after Game Over  
- Previously caused **Lust Swarms** to fail in new sessions  

#### 🚀 Homing Missile Firing Sequence
- Fixed mapping issue in **Inventory Manager (E-Key)**  
- `HomingMissile` class now correctly linked to `"Homing"` inventory string  

---

### 🔄 Changed

#### 🧼 Factory Sanitization
- **New-Sin factory** now supports:
  - Case-insensitive matching  
  - Automatic space stripping  
- Examples:
  - `"Real Pride"`  
  - `"RealPride"`  
  - `"realpride"`  
  → All resolve to the same entity ID  

#### ⚠️ Enhanced Warning System
- **Cataclysm Warning (RealPride)** decoupled from main update loop  
- Added **Pre-flight Null Check**  
- Prevents UI crash if boss is destroyed during beam charge  

---

### ➕ Added

#### 🛡️ Simulation Safety Net
- Added **Null-Player Guard** in `UpdateWithPlayer` for all Sin-class bosses  
- Prevents crash when boss targets a player that has been destroyed but not yet respawned  

---

> *"True power is not in the weapon, but in the stability of the hand that holds it."*  

**Patch 5.1.1 deployed. The Lab is now 100% operational.**



## [5.1.0] - 2026-03-15
### " "

Version **5.1.0** introduces a dedicated **weapon testing environment** and deeper combat balancing tools.  
This update also debuts a new **mini-boss class**, expands the **UI navigation system**, and upgrades the physics behavior of guided projectiles.

---

### Version 5.1 Focus

**Simulation Mode**  
A dedicated **Laboratory environment** for isolated monster testing and combat experiments.

**Advanced UI Systems**  
Introduces a **scrollable menu system** with directional indicators for navigating larger option lists.

**Complex Boss AI**  
Debut of the **Nephilim Class**, featuring multi-phase destruction mechanics and regenerative weapon systems.

**Projectile Overhaul**  
Guided projectiles now feature **dynamic directional rotation**, visually aligning missile orientation with flight trajectory.

---

## ➕ Added

### The Simulation Lab (Simulation Mode)

A new mode accessible from the **Main Menu** designed specifically for **weapon testing and combat experimentation**.

- Players can duel bosses **1v1**
- Bosses **auto-respawn immediately** after defeat
- Score display is replaced with **"N/A"** to clearly distinguish the mode from Story progression

---

### New Boss: Nephilim Class (`Nephilim.ps1`)

A technical mini-boss featuring a **target chain destruction sequence**:

**Laser Gun → Orbital Blades → Mother Core**

- **Regen Blades**  
  The boss regenerates spinning blades and launches them toward the player as **homing projectiles** every **1.5 seconds**.

---

### Scrolling Menu Interface

Introduced a menu system capable of handling **large option lists (10+)**.

- Maximum **6 items visible at once**
- Vertical **scroll navigation**
- **Triangular indicators** show scroll direction

---

### Homing Missile Evolution (Tracker [T])

The **Tracker** weapon has received a physics upgrade:

- **Dynamic Rotation**  
  Missile heads now smoothly rotate to match their turning direction while tracking targets.

- **Explosion Radius Increased** by **50%**

- **Boss Damage Rebalanced**  
  Deals **50–75 damage** to major bosses.

---

## 🔄 Changed

### Shield Priority System (v2.0)

Collision logic has been refined for shield interactions.

- As long as the player has **shield points (D > 0)**:
  - **All debuffs are completely blocked**
  - The shield absorbs **1 shield point per hit**

---

### Shield Shredders (New Weapon Category)

Certain enemy attacks now specialize in **destroying shields**:

- **Gluttony Blast**
  - Removes **50% of shield capacity**
  - Heals the boss

- **Nephilim Blade**
  - Removes **50 shield points instantly**

---

### Arena Integrity (Simulation Mode)

Upon death in **Simulation Mode**:

- Player instantly **respawns**
- Gains **3 seconds of invulnerability**
- The battlefield **remains intact** to allow uninterrupted testing

---

### Main Menu Polishing

Improved spacing and **visual padding** for main menu headings and options to achieve a cleaner layout.

---

## 🐞 Fixed

**Siren Debuff Inconsistency**  
Resolved an issue where directional inversion debuffs could fail to trigger due to shield collision priority absorbing the event incorrectly.

---

**RealPride Null-Pointer Crash**  
Fixed a crash in **Simulation Mode** where the boss attempted to read player coordinates before the player object was fully initialized.

---

**Overload Ambiguity Error**  
Resolved **"Multiple ambiguous overloads"** errors when generating **fonts and triangular UI shapes** in **PowerShell 5.1**.

---

**Inventory Grouping Safety**  
Improved logic for the **E key item trigger**:

- Items are now removed **only after a successful fire event**
- Prevents accidental loss of inventory items.

---

## 📊 Technical Boss Specification: Nephilim

| Part | HP | Status | Effect on Destruction |
|-----|----|--------|----------------------|
| Laser Gun | 400 | Vulnerable (Phase 0) | Disables Fatal Beam |
| Orbital Blades | 200 (x2) | Vulnerable (Phase 1) | Disables Blade Throw |
| Mother Core | 500 | Vulnerable (Phase 2) | Boss Defeated |

---

> *"Testing is the difference between a pilot and a survivor.  
> Enter the lab, master the Tracker, and conquer the Nephilim."*



## [5.0.1] - 2026-03-15
### "The Performance Sentinel Update"

Version **5.0.1** focuses on refining the **Collision Engine** for maximum performance, eliminating frame lag during high-object-density combat while also resolving critical **index management errors** that previously threatened runtime stability.

---

### Version 5.0.1 Focus

**Optimization**  
Improved object-processing speed by ensuring immediate memory release when entities are removed.

**Index Safety**  
Prevents **"Index was out of range"** errors through a fully standardized **backward iteration loop system**.

**Explosion Integrity**  
Ensures heavy weapon explosions (**Missiles / Homing**) complete their visual and damage cycles even when objects are removed during collision events.

---

## 🔄 Changed

### Backward Iteration Standard

All `for` loops within **CollisionManager.ps1** now iterate **from back to front** (`Count - 1 → 0`).  

This guarantees safe list modification when objects are removed during collision processing.

---

### Bullet Culling Refinement

Improved projectile cleanup logic in the main engine:

- Added explosion-state validation (`Y = -2000`)
- Ensures **Missile** and **HomingMissile** objects remain active until their **explosion animation fully completes**
- Prevents premature deletion during heavy combat

---

## 🐞 Fixed

**Index Out of Range (Fatal Error)**  
Resolved a crash occurring when **Nuke** or other **AOE weapons** destroyed multiple enemies simultaneously.  

Added an **Index Guard system** to validate list size before accessing elements.

---

**Invisible Homing Explosion**  
Fixed a bug where **Tracker (Homing Missile)** impacts would disappear instantly without triggering the explosion effect.  

`HomingMissile` objects are now protected from deletion during the initial explosion trigger.

---

**Sub-Part Collision Desync**  
Improved collision priority for **Lucifer's modular boss structure**.

- Projectiles now correctly damage **wings or weapon parts first**
- Core damage is prevented until the correct **boss phase** is reached
- Eliminates unintended bullet penetration through boss components

---

## 🛠️ Technical Damage Profile (Stabilized)

| Weapon Type | Target: Boss Core | Target: Boss Parts | Target: Minions |
|--------------|------------------|-------------------|----------------|
| Holy Bomb [H] | 800 Damage | 50 Damage | 5 Damage |
| Nuke [N] | 400 Damage | 200 Damage | Instant Kill |
| Homing [T] | 75 Damage | 50 Damage | 5 Damage |
| Missile [M] | 50 Damage | 1 Damage | 1 Damage |
| Laser [L] | 2 Damage / Frame | 1 Damage / Frame | Instant Kill |

---

> *"The engine is now lean, mean, and crash-proof.  
> Lucifer's end is just one clean shot away."*



## [5.0.0] - 2026-03-15
### "Chapter 2: The Fallen Angel & The Homing Protocol"

Version **5.0.0** marks a major evolution of the game's core design, transitioning from purely **procedural spawning** into a structured **scripted wave progression system**.  
This update also introduces **advanced guided weaponry**, deeper **atmospheric space rendering**, and a fully stabilized **session reset architecture**.

---

### Version 5.0 Focus

**Scripted Progression**  
Enemy waves now appear in organized **formation-based combat patterns** rather than random spawns.

**Advanced Physics**  
Introduces **homing weapon logic** with directional projectile rotation and proximity-based detonation.

**Atmospheric Rendering**  
Enhanced cosmic backgrounds and planetary visuals provide greater depth and immersion.

**Operational Stability**  
The **Reset Session system** has been rebuilt to ensure a fully clean memory reset during gameplay transitions.

---

## ➕ Added

### The Watchers Formation (Chapter 2)

A new class of **organized aerial formations** has entered the battlefield.  
Enemies now attack in **tactical flight formations** instead of falling directly from above.

- **Delta Formation**  
  A triangular attack pattern led by a missile-launching command unit.

- **Finger-Four Formation**  
  Twin assault groups approaching from opposite flanks.

- **Orbit & Ace**  
  A rotating sweep formation across the center of the screen, featuring a special **Ace fighter** moving at **double speed**.

- **Triple Pyramid**  
  A full frontal combat wall consisting of **12 enemy units**.

---

### Homing Missile (Item T)

Introduces a new weapon: **Tracker**

- Icon: **[ T ]**
- Visual: Yellow triangular missile with an orange thruster trail
- Equipped with **Auto-Targeting** and **Proximity Fuse**

The projectile dynamically curves toward the nearest target and detonates with an **AOE blast radius of 150px**.

---

### Celestial Variations

Expanded space environment visuals with new planetary types:

- **Saturn Type** — Single-ring gas giant  
- **X-Rings Type** — Crossed orbital rings

These additions enhance the **depth and cinematic quality** of the space battlefield.

---

## 🔄 Changed

### From Scores to Waves

In **Chapter 2**, score is now used **purely for statistics and records**.  
Enemy progression is now driven by **Clear-to-Spawn Logic**, meaning the next wave appears only after the previous formation has been eliminated.

---

### Enhanced Internal Shake

The screen shake system now operates **exclusively within the Play Area** using **TranslateTransform coordinate offsets**.

This prevents the **program window itself from shifting position**, ensuring a more stable visual experience.

---

### HUD 3.0 Alignment

The **Pocket Arsenal** interface has been redesigned:

- Horizontal **3-slot layout**
- Located at the bottom of the **Sidebar**
- Item quantities are now displayed in **clear black numerals inside the icon frame**

---

## 🐞 Fixed
**Index Out of Range (Nuke/Homing)**  
Added defensive checks within **CollisionManager** to prevent invalid list removals when multiple **Nuke or Homing explosions** occur simultaneously.

---

## 🚀 Technical Overview (v5.0.0)

| Weapon Class | Icon | Tech Type | Target |
|---------------|------|-----------|--------|
| Tracker | [ T ] | Homing Projectile | Single / AOE |
| Holy Bomb | [ H ] | Holy / Armor Piercing | Boss Core |
| Nuke | [ N ] | Global Wipe | Field Clear |
| Laser | [ L ] | Continuous Hitscan | Lane Clear |

---

> *"The sins are behind you. The Fallen Angels are in front of you.  
> Your arsenal is ready. Welcome to Chapter 2."*



## [4.4.4] - 2026-03-15
### "The Duelist's Refinement"

Version **4.4.4** focuses on refining the **1v1 gameplay experience**, particularly the duel against the final boss **Lucifer**, while also resolving several **critical bugs** that could cause the game to crash during intense combat scenarios.

---

### Version 4.4 Focus

**Duel Mode Balancing**  
Fine-tuned the difficulty of the 1v1 mode to ensure the fight remains challenging without becoming overly punishing.

**Kernel Stability**  
Resolved major runtime issues including **"Collection Modified"** and **"Null Expression"** errors within the main game loop.

**Logic Cleanup**  
Removed redundant enemy spawn logic from the main script to simplify and stabilize the spawning system.

---

## ➕ Added

**Cheat Code [F2]**  
Introduced a debug shortcut that instantly grants **Nuke x100** to the player's arsenal.  
This feature is intended **for testing and stress-test scenarios only**.

---

## 🔄 Changed

### Summoning Intelligence (1v1_LUCIFER)

Reworked **Lucifer's summoning behavior** in duel mode to function more like a **"supply drop system"**.

- **Dynamic Frequency**  
  In duel mode, Lucifer now summons **Wrath** more frequently (**every 1.6 seconds**) to provide the player with additional ammunition.

- **Minion Nerf (1v1 Only)**  
  Wrath units summoned by Lucifer in duel mode now have:
  - **3 HP**
  - Reduced movement speed  

  This allows players to collect dropped items more easily without disrupting their dodge rhythm against Lucifer's laser attacks.

---

### Spawn Engine Consolidation

The general enemy spawning logic in **AlienStrike.ps1** has been merged into a **single, robust control block**, preventing:

- Double-spawn issues  
- Accidental enemy spawns during **1v1 duel mode**

Duel mode now strictly allows **only the boss and its controlled summons**.

---

### Envy Duel Protection

Updated **CollisionManager.ps1** to **suppress the automatic spawning of Envy** while the player is engaged in a **boss duel**, preserving the intended fairness of the encounter.

---

## 🐞 Fixed

**Collection Modified Crash**  
Resolved a crash caused when the boss summoned new enemies while the engine was iterating over the existing collection.  
Fixed by introducing a **PendingList queue system** and **.ToArray() safe iteration**.

**Null-Pointer Safety**  
Added additional **null checks** during movement and firing calculations to prevent errors when objects are destroyed mid-frame.

**Ghost Minion Fix**  
Fixed an issue where certain **Wrath minions became indestructible** due to spawning inside Lucifer's hitbox.  
Spawn positions are now offset to ensure proper collision detection.

**Pause-Exit Memory Leak**  
Resolved a state-lock issue where the game could remain stuck in **Pause/Victory state** when exiting to the main menu via **Reset-Session**.

---

## 🛡️ Final Boss Specification: Lucifer (v4.4.4)

| Attribute | Normal Mode (Story) | Duel Mode (1v1) |
|-----------|--------------------|----------------|
| Summon Rate | 4.0 Seconds | 1.6 Seconds |
| Summon HP | Original (Variable) | Fixed (3 HP) |
| Arena Cleanliness | Minions Present | Boss & Summons Only |
| Rewards | Standard Loot | High Frequency Replenish |

---

> *"A true King provides for his subjects, even if only to extend their suffering. Fight on, Pilot."*



## [4.4.3] - 2026-03-15
# "The Visionary Layers & Rendering Refactor"

Version **4.4.3** focuses on reorganizing the **Rendering Architecture** by separating graphical processing into modular **Rendering Layers**.  
This improves drawing efficiency and makes future visual effect management significantly easier.

---

## Version 4.4 Focus

**Layered Rendering**  
Separates responsibilities for rendering **background elements**, **in-game entities**, and **user interface components**.

**Internal Shake Engine**  
Upgrades the screen-shake system to operate within the **graphics coordinate space**, making it non-intrusive to UI elements.

**Modular Render Modules**  
Marks the transition away from monolithic graphics files toward **specialized rendering modules**.

---

## ➕ Added (Render Modules)

A new directory has been introduced:
```
src\Managers\RenderModules\
```
This directory organizes rendering layers into dedicated modules:

**EnvironmentEngine.ps1 (Background Layer)**  
Handles rendering of distant elements such as:
- Twinkling **Starfield**
- **Saturn** and **X-Ring planetary visuals**

**UserInterface.ps1 (UI Layer)**  
Manages all screen-attached interface elements, including:
- Sidebar
- Boss HP Bar
- **Pocket Arsenal (3-Slot Horizontal Dock)**

**ScreenManager.ps1 (State Layer)**  
Controls all game state screens:
- Start Screen
- Menu
- Leaderboard
- Credits
- Pause Menu

---

## 🔄 Changed

### Internal Screen Shake
Reworked from **window-level movement** to **graphics-level `TranslateTransform`**.

This change allows:
- Only the **Play Area** to shake
- **UI and Sidebar remain completely stable** for better visual comfort.

---

### Rendering Orchestration

The core file **RenderManager.ps1** now acts as a strict **rendering hub**, controlling the Z-Index drawing order:

1. Environment  
2. Shake Apply  
3. Entities  
4. Shake Reset  
5. HUD  
6. Pause Menu  

---

### Pocket Arsenal Refinement

The logic for rendering weapon slots has been moved into the **UI module**, making it easier to customize:

- Colors
- Icons (**M, L, N, H**)

---

## 🛠️ Rendering Architecture Overview

| Module File | Layer | Responsibilities |
|--------------|------|------------------|
| EnvironmentEngine | Background | Stars, Planets, Parallax Effects |
| UserInterface | HUD | Sidebar, Score, Arsenal Dock, Boss HP |
| ScreenManager | Overlay | Menus, Credits, Leaderboard, Pause |
| RenderManager | Orchestrator | Layering Order, Resource Cache, Shake Logic |

---

## 😈 Sin Class Summary (v4.4.3)

| Sin | Technical Mechanic | Disruption Class |
|-----|--------------------|------------------|
| Lust | Directional Inversion | Movement Inversion |
| Gluttony | Shield Devour | Resource Stealing |
| Greed | Inventory Erasure | Arsenal Sabotage |
| Sloth | Disruption Pulse | Input Lockout (Item E) |
| Wrath | Scatter Shot | High Bullet Density |
| Envy | Weapon Jam | Primary Fire Suppression |
| Pride | Hitscan Beam | Precision Strike |
| RealPride | Absolute Annihilation | Execution / Enrage Timer |
| Lucifer | Sovereign Domination | Multi-Part Endurance Battle |

---

> **"The layers are aligned. The visuals are steady.  
> The engine now sees the galaxy with perfect clarity."**



## [4.4.2] - 2026-03-15
### "The Modular Awakening & The End of GameLogic"

Version 4.4.2 marks a major **architectural shift** for the engine.  
The long-standing **God Object** (`GameLogic.ps1`) has been officially dismantled, with its responsibilities redistributed into specialized modules under a new **Modular Architecture**.

This transformation prepares the engine for long-term scalability, allowing future content such as **Chapter 2, Chapter 3, and additional gameplay modes** to be introduced without rewriting core systems.

---

## Version 4.4 Focus

- **De-coupling Core Logic** — Separating previously intertwined logic into dedicated responsibilities
- **Scalability Foundation** — Enabling future chapter expansions without modifying legacy code
- **Logic Modules** — Introducing specialized modules for Factory, Director, Combat Response, and World Events

---

## ➕ Added (Logic Modules)

A new directory has been introduced:

```
src/Managers/LogicModules/
```

This folder now contains the core runtime systems, separated into **five primary modules**.

### `EntityManager.ps1` — *The Factory*
Responsible for creating all game entities.

Key functions:
- `New-Sin`
- `New-EnemySpawn`
- `Get-GameDifficulty`

This file acts as the **single entry point for entity creation**, making it the only location that needs modification when adding new enemy types.

---

### `StageDirector.ps1` — *The Progression Controller*
Handles boss progression and narrative transitions.

Key functions:
- `Check-BossSpawns`
- `Update-ChapterOneProgression`

This module controls **story pacing and gameplay flow**.

---

### `CombatResponse.ps1` — *The Outcome Processor*
Processes the results of combat interactions immediately after collisions occur.

Key function:
- `Handle-PostCollision`

Responsibilities include:
- Score calculation
- Reward distribution
- Combat outcome handling

---

### `PlayerSystem.ps1` — *The Player Controller*
Manages all player-related systems.

Key functions:
- `Handle-PlayerInput`
- `Add-To-Inventory`
- `Get-UIStatus`

This module centralizes **player state, controls, and inventory systems**.

---

### `WorldEvents.ps1` — *The Environment Controller*
Handles environmental events and item drops.

Key function:
- `Check-ItemDrops`

This module lays the groundwork for future systems such as:
- Dynamic weather
- Environmental hazards
- Event-driven gameplay elements

---

## 🔄 Changed

### Smart Auto-Loader Update
The automatic script loader in `AlienStrike.ps1` has been updated to scan the new **LogicModules directory**.

Dependency order between classes is still preserved, ensuring stable initialization during runtime.

---

### System Orchestration
The **game loop logic** has been refactored to call specialized modules rather than relying on a single monolithic file.

This significantly improves:

- Debugging precision
- Code readability
- System maintainability

---

## ❌ Removed

### The Retirement of `GameLogic.ps1`
The legacy `GameLogic.ps1` file has been officially removed after serving as the engine's central brain for many versions.

This change eliminates the risk of **spaghetti code** and clears the path for a cleaner, modular system architecture.

---

## 🛠️ Modular Architecture Overview

| Module File | Key Functions | Responsibility |
|-------------|--------------|---------------|
| EntityManager | New-Sin, New-EnemySpawn | Object Creation |
| StageDirector | Check-BossSpawns, Progression | Story & Mode Flow |
| CombatResponse | Handle-PostCollision | Battle Results & Rewards |
| PlayerSystem | Handle-PlayerInput, Inventory | Player State & Controls |
| WorldEvents | Check-ItemDrops | Environment & Random Events |

---

> **"Rest in peace, GameLogic.  
> Your legacy lives on in the shards of a stronger, faster, and smarter engine."**



## [4.4.1] - 2026-03-15
### "The Tactical Dock Alignment"

A small update focused on refining the **HUD interface** for improved clarity and modern UI standards.  
This update cleanly separates the **Arsenal display** from the **Active Buff system**, ensuring a more organized and readable combat interface.

---

## ➕ Added

### Horizontal Pocket Arsenal
The item display has been redesigned from a **vertical layout** to a **horizontal 3-slot dock**.

This new layout, referred to as **"The Dock"**, visually resembles a weapon tray and improves quick recognition of the player's available arsenal.

### Spatial Padding
Added additional **spacing between weapon slots** to improve visual comfort and make the weapon queue easier to distinguish during intense gameplay.

---

## 🔄 Changed

### HUD Ergonomics
The **Pocket Arsenal** has been moved to the **bottom of the Sidebar**, freeing space above for clearer **boss status and buff indicators**.

### Buff List Filtration
Improved status processing logic by **filtering weapon icons** (`M`, `L`, `N`, `H`) out of the **Active Buff list**.

This prevents duplicate visual information and keeps the buff display clean.

### Visual Prompts
The `[E]` usage indicator has been repositioned to appear **perfectly centered beneath the Active Slot**.

---

## 🐞 Fixed

### GDI+ Pen Error
Resolved the runtime error:

`[System.Drawing.Pens] does not contain a method named 'FromArgb'`

The system now creates custom **Pen objects via `New-Object`**, ensuring proper color handling in the rendering pipeline.

### Inventory Overlap
Fixed an issue where **Nuke and Missile items** could appear incorrectly in the **Active Buff display area**, causing visual overlap.

---

> **"A clear screen leads to a clear shot.  
> Your arsenal is now perfectly docked."**



## [4.4.0] - 2026-03-14
### "The Endless Rebirth & Tactical Pocket"

Version 4.4.0 consolidates several of the most complex structural and gameplay-management features so far. This update focuses on **seamless Endless Mode continuity** and a new **arsenal management system** that allows players to plan their combat strategy more effectively.

### Version 4.4 Focus
- **Endless Mode Continuity** — Seamless boss loop cycles
- **Strategic Exit Logic** — Mode-aware score saving system
- **Arsenal Pocket UI** — A 3-slot item queue system for tactical planning
- **Internal Screen Shake** — Impact-based camera shake without moving the program window

---

## ➕ Added

### Endless Loop Engine
In **Endless Mode**, defeating **Lucifer** now triggers a full **rebirth cycle of the Seven Sins**.

The system immediately resets the enemy progression back to minor enemies while the player **retains all score, level, and weapons**.

This creates a true **infinite combat loop** without interrupting gameplay flow.

---

### Pocket Arsenal UI (3-Slot)
The HUD item system has been redesigned into a **three-slot tactical pocket**.

- **Active Slot**  
  Large primary slot with `[E]` usage indicator.

- **Queue Slots**  
  Two secondary slots displaying the upcoming weapons that will rotate in when pressing `[Q]`.

- **Internal Count**  
  Item quantities are now displayed **inside the icon frame** for a cleaner interface.

---

### Internal Screen Shake
A new screen shake system implemented using **render coordinate translation (`TranslateTransform`)**.

Large impact events such as:
- **Nuke explosions**
- **Fatal laser hits**

now produce camera shake **without moving the actual Windows program window**, resulting in a more immersive impact effect.

---

## 🔄 Changed

### Exit-to-Save Logic
Pause Menu exit behavior now depends on the current mode:

- **Endless / Battle Mode**  
  Pressing **Exit** will immediately open the **name entry screen** to record the accumulated score.

- **Story Mode**  
  Pressing **Exit** resets the session and returns to the main menu **without saving score**, preventing score farming exploits.

---

### Total Session Reset
The `Reset-Session` function has been upgraded to perform a **complete memory reset**, including:

- Pause state
- Boss spawn counters
- Session variables

This ensures a **clean state** whenever changing modes or starting a new run.

---

### Add-To-Inventory Refactor
The inventory function now supports specifying **item quantity (`Amount`)** in a single command.

This enables smoother handling of **large ammo drops from bosses**.

---

## 🐞 Fixed

### Victory Logic Loop
Fixed a freeze occurring after defeating **Lucifer**.

Instead of stopping the **game timer**, the system now pauses **physics processing**, allowing the credit sequence to continue scrolling normally.

---

### Lust Spawn Inconsistency
Fixed an issue where **Lust squadrons** failed to spawn in **Endless Mode cycles beyond the second loop**.

This was resolved by resetting the internal **level tracking counter**.

---

### Global Nuke Kill Tracking
The **Nuke system** now correctly records boss eliminations and reports them back to the **Director system** with **100% accuracy**.

---

## 🛠️ Final Technical Summary (v4.4.0)

| Enemy Type | Unique Mechanic | Disruption Class |
|------------|-----------------|------------------|
| Lust | Directional Inversion | Movement |
| Gluttony | Shield Devour | Resource |
| Greed | Inventory Erasure | Arsenal |
| Sloth | Disruption Pulse | Input (Item E) |
| Wrath | Scatter Shot | Density |
| Envy | Weapon Jam | Offensive (Main Gun) |
| Pride | Hitscan Beam | Precision |
| RealPride | Absolute Annihilation | Fatal / Enrage |
| Lucifer | Sovereign Domination | Multi-Phase Boss |

---

> **"The sins will never stop coming, but neither will your will to survive.  
> Reset. Reload. Rebirth."**




## [4.3.0] - 2026-03-14
### "The Grand Director & Arcade Interface"

Version 4.3.0 focuses on elevating the **player experience** to match the feel of classic console-era games. This update introduces a **cursor-driven main menu**, multiple gameplay modes, and a smooth **in-house pause system**, replacing the traditional Windows pop-up behavior.

### Version 4.3 Focus
- **Navigation System** — Cursor-based main menu navigation using directional input
- **Multi-Mode Engine** — Support for Story Mode, Battle Mode (1v1), and Endless Mode
- **Custom Pause Logic** — A fully integrated pause menu replacing Windows dialog interruptions
- **Dynamic Content** — Expanded celestial visuals including planetary rings and space backgrounds

---

## ➕ Added

### GameBoy-Style Main Menu
A retro-inspired menu system controlled with **W / S arrow navigation**, featuring responsive **tick sound feedback** and clear category separation.

Available modes:

- **STORY MODE**  
  Follow the narrative progression through chapters  
  *(Starting with Chapter 1: The 7 Sins)*

- **BATTLE MODE**  
  Engage in **1v1 duels** against selected bosses for practice and experimentation.

- **ENDLESS MODE**  
  A survival challenge where combat loops indefinitely without a final stage.

---

### Custom Pause Menu (`Esc`)
A fully integrated pause system that overlays the screen with a **semi-transparent dark filter**, presenting:

- **RESUME**
- **EXIT TO MENU**

The system operates smoothly without freezing the game or triggering Windows pop-up dialogs.

---

### Advanced Celestial Assets
Expanded background visuals featuring procedurally varied planets:

- **Single-ring planets** *(Saturn-style)*
- **Cross-ring planets** *(X-Ring formations)*

Each planet is generated with **randomized color palettes and size variations**.

---

## 🔄 Changed

### Director & Factory Refactor
Boss spawning logic has been fully separated into the **Sin Factory** system.

Bosses can now be spawned simply by referencing their name, reducing code complexity by approximately **50%** and improving scalability for future content.

---

### Arena Integrity Rules
Score recording rules have been refined:

- In **Story Mode**, exiting through the Pause Menu will **not record a score**, preventing leaderboard exploitation.
- In **Battle Mode**, exiting will immediately redirect players to the **Hall of Fame screen**.

---

### HUD Mode Display
The right-side **Sidebar HUD** now displays the current **Game Mode** being played.

Examples:
- `STORY: CH 1`
- `BOSS RUSH`

---

## 🐞 Fixed

### Infinite Spawning Glitch
Fixed an issue where bosses could repeatedly spawn in **1v1 Battle Mode**, resulting in the infamous **"Army of Pride" bug**.

### Divide by Zero (HUD)
Resolved an error caused by dividing score values by a **zero target value** during the initialization phase of Battle Mode.

### Input Overlap
Fixed an issue where **Enter/Return inputs** could trigger multiple actions between the main menu and the game start screen.

### Immortal Ghosting
Fixed a bug where the **Immortal status** allowed players to pass through the **Cataclysm Wave**.

`Cataclysm` now acts as a **true catastrophic event**, bypassing all defensive states.

---

## 📊 Updated Elite Class Table (v4.3.0)

| Sin Class | Technical Mechanic | Play Mode Availability |
|-----------|--------------------|------------------------|
| Lucifer | Sovereign Domination | Story / Battle / Endless |
| RealPride | Absolute Annihilation | Story / Battle / Endless |
| Gluttony | Shield Devour | Story / Battle / Endless |
| Greed | Inventory Erasure | Story / Battle / Endless |
| Lust / Sloth | Movement / Input Lockdown | Story / Endless |

---

> **"The stage is set, the modes are ready.  
> Choose your sin, and let the duel begin."**



## [4.2.0] - 2026-03-14
### "The Architect & Impact Update"

Version 4.2.0 focuses on a major internal **refactoring effort** to prepare the engine for future expansion, while also introducing stronger **visual feedback systems** to make combat feel more impactful and satisfying.

### Version 4.2 Focus
- **Factory & Director Pattern** — A modular system for spawning bosses and controlling narrative flow
- **Hit Feedback System** — White flash visual impact when enemies take damage
- **Advanced Collision Layering** — Reorganized collision handling and rendering order
- **Robust Memory Management** — Reduced redundant object creation for improved stability

---

## ➕ Added

### The Sin Factory (`New-Sin`)
A **modular boss creation system** that allows any boss to be spawned directly by name.

Example:
```
New-Sin "Lucifer"
```

This enables instant **1v1 boss testing** and custom encounter setups.

### Chapter Director System
Boss spawn logic for **Chapter 1** has been separated from the main game loop.

This prepares the engine for future content such as:
- **Chapter 2**
- **Endless Mode**

### Hit Flash Effect (`FlashTimer`)
All enemies and bosses now **flash white when taking damage**, improving hit confirmation and combat feedback.

### Emergency Support Drop
An automatic support item drop system that spawns a `[D] (Defense)` item every **15 seconds** when **Lucifer enters his critical phase** `(HP < 9,000)`.

---

## 🔄 Changed

### Collision Logic Segmentation
`CollisionManager.ps1` has been reorganized into dedicated processing groups:

- **Unstoppable Threats**
- **Global Nuke**
- **Item Pickups**
- **Weapon Damage**

This improves both **performance clarity and maintainability**.

### Z-Index Overhaul
Rendering order has been adjusted so that **explosion effects (Missile / Nuke)** always render **above bosses**, ensuring clearer damage feedback.

### Weapon Balancing (Phase 2)
Heavy weapon damage has been rebalanced when **Lucifer enters his Fragile Phase (armor broken)**.

| Weapon | Damage |
|------|------|
| Holy Bomb | 800 |
| Nuke | 400 |
| Missile | 50 |

---

## 🐞 Fixed

### Immortal Exploit
Fixed a bug where the **Immortal status** allowed players to pass through the `Cataclysm Wave`.

`Cataclysm` now **always bypasses immortality mechanics**.

### Indexing Error (ArrayList)
Prevented crashes caused by  
`Index was out of range`

when large numbers of enemies were removed simultaneously by **Nuke effects**.

### PointF & `op_Subtraction`
Permanently fixed rendering errors caused by **floating-point coordinate calculations in PowerShell**.

---

> **"The foundation is laid. The sins are coded.  
> The King has fallen, but the engine is just waking up."**



## [4.1.2] - 2026-03-12
### "The Smart Kernel Update"

This update introduces a **major improvement to the engine's dependency management system**, preparing the architecture for future expansion.  
The manual file-loading approach has been replaced with a **Smart Auto-Loader kernel** capable of dynamically discovering and loading game modules.

---

## 🔄 Changed

### Kernel Architecture Overhaul

Replaced the traditional **manual Dot-Sourcing file loading** with a **Smart Auto-Loader system**.

The new kernel automatically scans the **`src` directory** and loads all required game modules, including:

- Enemy classes
- Boss entities
- Weapon systems
- Supporting engine components

This significantly simplifies development and allows **new content to be added without modifying the core loader**.

---

### Inheritance Priority System

Implemented a **class loading priority structure** to ensure stable PowerShell class resolution.

| Load Priority | Description |
|---|---|
| Base Classes | Core engine and parent classes |
| Entity Classes | Enemies, bosses, and gameplay objects |
| Derived Classes | Specialized or inherited implementations |

This prevents **TypeNotFound errors** caused by child classes loading before their parent definitions.

---

## 🐞 Fixed

### Type Resolution Errors

Resolved multiple **PowerShell 5.1 parser errors** where class types were not recognized during the loading stage.

A **multi-pass loading strategy** is now used to guarantee that dependencies are resolved before execution.

---

### Circular Reference Protection

Added **HashSet-based dependency tracking** to prevent duplicate loading when files are referenced through both:

- Explicit file paths
- Wildcard imports

This ensures the loader avoids **circular references and redundant class initialization**.

---

> **"The core is now autonomous. Add a Sin, add a weapon—the engine will find them."**



## [4.1.1] - 2026-03-12
### "The Celestial Rings Update"

A small visual update that enhances the **cosmic atmosphere** of the battlefield by introducing more diverse planetary objects in the background.

---

## ➕ Added

### Ringed Planet Variations

New planetary visuals now appear within the **dynamic background system**.

| Planet Type | Description |
|---|---|
| **Saturn Type** | A planet with a **single horizontal ring**. Uses **depth rendering** so the ring visually wraps around the planet. |
| **X-Rings Type** | A rare planet featuring **two intersecting rings forming an X shape**, adding unique visual depth to the starfield. |

---

### Randomized Planet Types

The background generation system now **randomizes planet styles** every **10 levels**, ensuring the cosmic scenery remains varied and visually engaging throughout gameplay.

---

> **"Even in the depths of space, beauty remains. Watch the rings drift by as you prepare for the next Sin."**



## [4.1.0] - 2026-03-12
### "The Restoration of Peace"

Version 4.1.0 focuses on **gameplay polish, visual atmosphere, and a memorable ending sequence**, marking the conclusion of the epic battle against the **Seven Sins**.

---

## Version 4.1 Focus

- **Dynamic Backgrounds** — Parallax starfield with randomized planetary visuals  
- **Tactical Support** — Emergency defense item drops during critical boss phases  
- **Visual Feedback** — Critical warning banners and victory screen system  
- **Boss Balancing** — Improved armor mechanics and target-specific damage scaling  

---

## ➕ Added

### Cosmic Starfield & Planets
Introduced a **dynamic space background system** featuring:

- Twinkling stars moving at **different parallax speeds**
- **Randomized planets** with varying sizes and colors
- Planets drift across the battlefield **every 10 levels**

---

### Emergency Defense Drop — *Item [D]*

A tactical support system during the **Lucifer encounter**.

When Lucifer’s HP falls below **9000**, an **Emergency Defense Supply** will drop every **15 seconds**, granting:

- **+5 Defense Shield**

---

### Holy Bomb — *Item [H]*

A legendary weapon dropped by **Wrath enemies during the final boss battle**.

| Property | Value |
|---|---|
| Damage | 800 |
| Target | Lucifer Core / Armor |
| Type | High-impact boss weapon |

---

### Victory Banner & Credits

A full **endgame sequence** has been added.

After defeating Lucifer:

- A banner appears:
```
LUCIFER DESTROYED
```

- **Scrolling credits** play on screen
- The game transitions to the **Hall of Fame leaderboard**

---

## 🔄 Changed

### Lucifer Armor Logic

Lucifer's **blue armor shield** now behaves as a **one-time trigger**:

| Condition | Effect |
|---|---|
| HP < 1000 | Armor activates once |
| Damage Taken | HP bar visually reflects the real value |

---

### Target-Specific Damage Scaling

Heavy weapons now deal **enhanced damage against boss entities** during vulnerable phases.

| Weapon | Behavior |
|---|---|
| Nuke | Increased boss damage |
| Missile | Enhanced damage vs boss parts |
| Holy Bomb | Extremely effective vs Lucifer |

Damage against **standard enemies remains unchanged**.

---

### Cataclysm Proximity Warning

When **RealPride** has **3 laser cycles remaining**, the battlefield will trigger a warning system:

- Arena border flashes
- Warning banner appears:
```
!!! CATACLYSM INCOMING !!!
```

This signals that **the final attack is imminent**.

---

## 🐞 Fixed

### Negative HP Glitch
Resolved an issue where Lucifer's HP could drop below zero when hit by heavy weapons.  
A **minimum HP clamp (0)** has been implemented.

---

### Missile Phase Ghosting
Missiles now **detonate immediately upon hitting boss components**, even if those components are temporarily protected by phase shields.

---

### Z-Index Rendering
Adjusted rendering order so that **Missile and Nuke explosion effects appear above boss entities**, improving damage visibility.

---

> **"The stars are silent again. The sins have been purged. Mission: Accomplished."**



## [4.0.0] - 2026-03-11
### "The Fall of Lucifer"

Version 4.0.0 marks a **major milestone**, introducing the game's **Final Encounter**.  
Players now face **Lucifer**, the most complex boss ever created in AlienStrike, featuring **destructible parts, phase-based combat, and large-scale battlefield mechanics**.

---

## Version 4.0 Focus

- **Multi-Part Boss Architecture** — Destructible boss components
- **Phase Transition System** — Combat behavior evolves as damage is dealt
- **Cinematic Visual Feedback** — Smooth HP bars and dimensional portal effects
- **Strategic Combat Design** — Destroying boss parts directly damages the core

---

## ➕ Added

### Final Boss: Lucifer (`Lucifer.ps1`)  
**HP: 20,000**

The largest and most complex enemy in the game. Lucifer is composed of **four destructible combat modules**:

**Side Cannons (2x)**  
- Fires **Fatal Beams**  
- HP: 2000 each

**Top Turrets (2x)**  
- Fires **Armor-Piercing Projectiles (Speed 15)**  
- HP: 400 each

---

### Destruction Feedback System

Destroying Lucifer’s components immediately reduces the **main boss HP**:

| Destroyed Part | Boss HP Reduction |
|---|---|
| Cannon | -4000 |
| Turret | -1000 |

---

### Summoning Portal

When Lucifer's HP drops below **7000**, a **Magenta Portal** opens, continuously summoning **Wrath-class enemies** to reinforce the battlefield.

---

### Approaching Warning System

After defeating **RealPride**, the screen will flash red and display:



## [3.4.1] - 2026-03-11
### "The Arena Integrity Update"

A minor update focused on **closing a loophole in the resurrection system**, ensuring that **Gatekeeper-class encounters remain uninterrupted and intense** throughout the fight.

---

## 🔄 Changed

### Arena Integrity Logic
Improved the **player death handling system**.

If the player dies while **RealPride is still present on the battlefield**, the system will now **cancel any board-clearing routines** under all circumstances.  
This prevents the boss from disappearing before the duel is properly concluded.

### Persistent Encounter
When the player dies within **RealPride's domain**, they will now **immediately respawn** with:

- **50 Defense Shield**
- **3 seconds of Immortal Status**

This ensures the fight **continues seamlessly without breaking the encounter flow**.

---

## 🐞 Fixed

### Accidental De-spawning
Fixed a bug where **RealPride could be removed from the game** if the player died from other causes  
*(such as collisions or standard projectiles)* rather than the **Fatal Laser attack**.

---

> **"The Gatekeeper doesn't leave until you're dead — or he's dust."**
```
!!! LUCIFER APPROACHING !!!
```

for **3 seconds**, signaling the arrival of the final boss.

---

## 🔄 Changed

### Smooth HP Bar Overhaul
The boss health bar now uses a **dual-layer display**:

- **Red Bar** → Immediate damage
- **White Bar** → Smooth delayed follow effect

This creates a **cinematic damage visualization**.

---

### Shield Dynamics (Phase Lock)

Lucifer's **Core remains shielded** until key components are destroyed:

| Phase | Condition |
|---|---|
| Phase 0 | Core fully protected |
| Phase 1 | Cannons destroyed |
| Phase 2 | Turrets destroyed → Core vulnerable |

---

### Nuke Tactical Buff

The **Nuke** now:

- **Bypasses phase armor**
- Deals **direct damage to Lucifer's Core**
- Causes **massive AOE damage to surrounding parts**

---

### Arena Continuity

Respawn rules during the **Final Boss Encounter**:

- Player respawns instantly after death
- Gains **3 seconds of Immortal status**
- **Battlefield is not cleared**, ensuring uninterrupted combat.

---

## 🐞 Fixed

### PointF Construction Error
Resolved drawing coordinate issues in PowerShell by separating coordinate calculations from render calls.

### Missile Phase Clipping
Missiles now **explode on contact with boss components**, even if the component is currently in an invulnerable state.

### Index Out of Range
Prevented crashes caused by large simultaneous entity removal during **Nuke activations**.

---

> **"Heaven sent you. Hell built this. Only one survives the Final Sin."**



## [3.4.0] - 2026-03-11
### "The Gatekeeper's Judgment"

Version 3.4.0 introduces the first **Gatekeeper-tier boss**, **RealPride**, who stands as the final barrier before entering **Lucifer's domain**.  
This update focuses on **High-Stakes Combat**, where every decision and every second determines victory or defeat.

**Version 3.4 Focus:**
- **Gatekeeper Mechanics:** Boss encounter with an **Enrage Countdown Timer**
- **Hard Game Over:** A fatal attack that bypasses all revival systems
- **Fatal UI:** Critical-level warning system for catastrophic events
- **Immortal Status:** Temporary invulnerability to prevent spawn-kill scenarios

---

## ➕ Added

### True Boss: RealPride (`RealPride.ps1`) [HP: 2000]

A **Gatekeeper-class boss** that appears after defeating **Gluttony three times**.

RealPride features **smooth player-tracking AI** and a **phased attack sequence**, escalating the pressure as the fight progresses.

---

### Ultimate Skill: Cataclysm Wave

If RealPride is **not defeated within 15 laser cycles**, the boss will unleash a **massive pink energy curtain** that wipes across the screen *(Opacity-based wipe effect)*.

This attack causes an **instant Game Over**, bypassing:
- Immortal status
- Remaining player lives
- Shield protection

---

### Victory Skill: Sovereign Grace (Blue Laser)

Upon defeat, RealPride releases a **blue sweeping energy wave** across the battlefield.

If the player is struck, their **Defense Shield is recalibrated to 50 units**, ensuring balance before entering the next boss encounter.

---

### New Status: Immortal [I]

A **temporary 3-second invulnerability state** granted after reviving from a Fatal Laser hit.

The player ship will **blink visually**, providing a brief recovery window to reposition and avoid immediate destruction.

---

## 🔄 Changed

### Fatal UI Sidebar

Added a critical warning indicator:
```
>> FATAL ENTITY <<
CATACLYSM IN: X
```
Displayed in the **Sidebar**, updating in real-time to create intense pressure during the Gatekeeper encounter.

---

### Nuke Re-balancing

Adjusted **Nuke damage against RealPride to 200**.

This makes the **Nuke a key strategic weapon** during the boss fight, dealing **20× more effective damage compared to standard enemies**.

---

### Refactored Arena Logic

When RealPride appears:

- **Standard enemies (Minions) are cleared**
- **Other Sin-class bosses remain active**

This creates the **most challenging combat scenario**, forcing players to handle multiple high-level threats simultaneously.

---

## 🐞 Fixed

### Smooth Interpolation
Improved boss movement using **Lerp-like interpolation**, reducing jitter during high-speed tracking.

### Console Color Compatibility
Resolved a **Runtime Error** caused by unsupported **Gold console color**.  
Replaced with compatible **Yellow / Cyan color values**.

### PointF Construction Fix
Fixed an exception when rendering **triangle-based geometry** by enforcing explicit **`[float]` casting** for all coordinates.

---

> **"The countdown to Cataclysm has begun.  
> You aren't just fighting a Sin anymore — you're fighting time itself."**



## [3.3.0] - 2026-03-10
### "The Gluttony & Tactical Nuke Update"

Version 3.3.0 introduces a major update centered around **high-endurance miniboss combat** and **strategic shield resource management**, alongside the debut of a **battlefield-clearing super weapon**.

---

## ➕ Added

### Boss: Gluttony (`Gluttony.ps1`) [HP: 200]
A **devouring miniboss** that appears based on the player's **Defense Shield level**.

Spawn conditions:
- **Stage 1:** 100 Shield points  
- **Stage 2:** 200 Shield points  

Gluttony can **heal itself by stealing the player's shield energy**, turning defensive resources into a tactical risk.

### Super Weapon: Nuke (Item `N`)
The **highest-tier weapon** obtainable by defeating Gluttony.

When detonated at **Y = 300**, the Nuke will:
- **Clear all standard enemies from the screen**
- Deal **massive damage to Sin-class bosses**

### New Projectile: Purple Blast
A **giant purple projectile** that follows a **curved trajectory toward the player**.

On impact, it **steals 50% of the player's shield** and transfers the energy back to Gluttony.

---

## 🔄 Changed

### Defense Shield Overhaul
The **maximum shield capacity** has been increased to **400 points**.

A new **Shield-Based Spawn Threshold system** has been implemented, using shield accumulation as the trigger for spawning the **Gluttony boss encounter**.

### Engine Organization
Refactored the `Handle-PostCollision` function into a more **modular structure**, allowing the engine to support **more complex Buff/Debuff calculations** without impacting performance.

### Entity Interaction
Improved **Greed's screen-clearing logic** so it will **no longer remove Gluttony from the battlefield** if the miniboss fight is still active.

---

## 🐞 Fixed

### Nuke Collision Runtime Error
Fixed an error occurring when the **Nuke explosion hit standard enemies lacking a `TakeDamage` function**.

A **Class Type validation check** has been added to prevent the runtime exception.

### Gluttony Blast Visibility
Adjusted the **spawn point and speed** of the Purple Blast projectile so players can **visually detect and react in time**.

### Shield Block Priority
Updated the **collision priority order** in `CollisionManager`.

Shield-stealing projectiles now **resolve before normal defensive blocking**, ensuring Gluttony's mechanics function as intended.

---

> **"Your shield is no longer just protection; it's a dinner bell for the hungry."**



## [3.2.0] - 2026-03-09
### "The Tactical Arsenal Update"

Version 3.2.0 focuses on expanding the **player arsenal** and improving the **precision of heavy weapon control**.  
This update introduces a **Weapon Swap system**, a new **continuous Hitscan Laser weapon**, and a **smart inventory grouping system** to maintain stable weapon ordering.

**Version 3.2 Focus:**
- **Weapon Rotation (Q-Switch):** Batch-based weapon type rotation
- **High-Power Weaponry:** Introduction of the Player Laser sweeping weapon
- **Input Precision:** Item controls (Q/E) migrated to `KeyDown` events for 100% accurate input handling
- **Smart Inventory:** Item grouping logic to prevent unintended weapon switching

---

## ➕ Added

### New Player Weapon: Laser (`PlayerLaser.ps1`)
A **bright lime-colored Hitscan weapon** that remains attached to the player ship for **1 second**.

The laser can be **swept across the battlefield**, dealing **piercing damage** to all enemies in its path.

### Weapon Swap System (Key: `Q`)
Players can press **Q** to **rotate weapon types** in their inventory (e.g., switching between **Missile** and **Laser**).

The system automatically **skips duplicate weapon types**, ensuring efficient rotation.

### Smart Grouping Logic
When collecting new items (such as **Missiles dropped by Lust**), the system will **insert them into the correct weapon group** within the inventory.

This prevents the **current weapon order from shifting unexpectedly**.

---

## 🔄 Changed

### Refactored Input Handling
The logic for **Q and E inputs** has been moved from the **Game Loop** to the **`KeyDown` event** in the main file.

This resolves **input overlap issues** caused by repeated frame polling and improves performance efficiency.

### Laser Collision Handling
Updated `CollisionManager.ps1` to properly support **continuous laser damage** without destroying the projectile object upon collision.

### UI Enhancement (Inventory xCount)
The HUD now:

- Displays **item counts per weapon type**
- Shows **`NEXT: [Type]`** to indicate the upcoming weapon in the rotation queue

---

## 🐞 Fixed

### Auto-Switching Bug
Fixed an issue where the **arsenal could automatically switch weapon types** after receiving new items from Lust.

### Laser Visual Desync
Corrected the **laser rendering position** so it remains perfectly aligned with the **player ship's weapon muzzle** on every frame.

### Out-of-Bounds Culling
Adjusted the **projectile cleanup condition** in the Game Loop to properly support **long-range projectiles** with extended length.

---

> **"Swap, Aim, and Obliterate. The inventory is now under your total control."**



## [3.1.0] - 2026-03-09
### "The Greed Duel & Shield Reinforcement"

Version 3.1.0 introduces a **high-risk, high-reward gameplay mechanic** with the arrival of the Sin of **Greed**, alongside player size adjustments for more precise movement and evasive control.

---

## ➕ Added

### New Elite Enemy: Greed (`Greed.ps1`)
A **golden star-shaped boss** featuring **Circular Orbit AI**.  
Greed moves in rapid orbital patterns and has a **2-second lifespan** before triggering **self-destruction**.

### New Projectile: Greed Arrow
A **golden arrow projectile** with an initial **homing vector**, traveling at **speed 16**.  
If the player is hit, the **entire Inventory is instantly wiped**.

### New Buff: Defense Shield (Stackable)
A special reward obtained by defeating Greed.

Grants a **protective shield** that can **automatically block any incoming damage or debuff**.  
The shield is **stackable**, granting **10 charges per Greed defeated**.

---

## 🔄 Changed

### Player Miniaturization
The player ship size has been **reduced by 30%** *(now 21×21 px)* to improve maneuverability in tight combat spaces.

The **weapon hitbox remains unchanged**, preserving shooting accuracy.

### The Greed Duel Arena
When Greed appears, the system will:

- **Clear all standard enemies from the screen**
- **Temporarily halt enemy spawning**

This creates a **1-on-1 duel scenario** between the player and Greed.

### Visual Shield Aura
Added a **Cyan circular aura effect** around the player ship while **Defense Shield** is active.

A **remaining shield counter (D icon)** is now displayed on the Sidebar.

---

## 🐞 Fixed

### Polygon Casting Fix
Fixed an `op_Addition` error when rendering **polygonal shapes** (Lust / Greed).

The system now strictly enforces **`[PointF[]]` and `[float]` type casting** for stable geometry rendering.

### Spawn Logic Correction
Resolved an issue where **Greed could appear immediately at game start**.

Adjusted the **Score Threshold validation** to ensure correct spawn timing.

---

> **"Greed will take everything you have, or give you the power to keep it all."**



## [3.0.0] - 2026-03-08
### "The Arcade Evolution & Sloth's Domain"

Version 3.0.0 represents the **largest system overhaul in the project so far**.  
This update focuses on the full implementation of **HUD 2.0** and a deep **architecture refactor**, preparing the engine to support more complex **item and status systems** moving forward.

**Version 3.0 Focus:**
- **Engine Purity:** Cleaned the core file by migrating nearly all gameplay logic into specialized Managers
- **HUD 2.0 (Arcade Style):** The Sidebar interface returns with modernized visual feedback
- **Advanced Status System:** Introduces **Jammer**, **Speed Buff**, and a refined **Wrath stacking system**

---

## ➕ Added

### New Elite Enemy: Sloth (`Sloth.ps1`)
The **fourth Sin-class boss**, featuring **Sequence-based AI** behavior.

Attack sequence:
- Slowly approaches the target  
- Stops mid-air  
- Deploys bombs  
- Fires counter shots  
- Retreats from the battlefield  

Sloth has **6 HP**.

### New Projectile: SlothBomb & Shockwave
A **three-stage explosive orb** *(Green → Yellow → Red)* that detonates into a massive **semi-circular Shockwave**, sweeping the lower combat area.

### New Status: Jammer (Debuff)
A disruptive signal effect *(J icon)* that prevents the player from **using items (Key: E)** for **5 seconds**.

### New Status: Speed Boost (Buff)
Reward for defeating Sloth.  
The player receives **2× movement speed** *(S icon)* for **7 seconds**.

### Inventory Stack System
A redesigned **HUD inventory system** capable of displaying **large item counts (x100+)**.

Includes a **Next-Item Preview** indicator to help players plan their combat strategy.

---

## 🔄 Changed

### God-Object Erasure (Final Phase)
`AlienStrike.ps1` has been completely stripped of gameplay calculations.

All logic has been migrated to:
- `Handle-PostCollision`
- `Update-PlayerStatus`

inside `GameLogic.ps1`.

The main file now acts purely as a **controller layer**.

### Wrath Buff Refactor (The 3-Stack Rule)
Rebalanced the **Wrath system**:

- Collect **3 stacks** to unlock **Red Mode**
- Red Mode lasts **14 seconds**
- Stack timers **no longer reset** until the buff expires, improving gameplay balance.

### Visual Health Icons
Player lives are now displayed as **red heart icons** instead of numeric values, reinforcing the **classic arcade aesthetic**.

### New HUD Layout
The HUD has been reorganized for clarity:

- **Sidebar (Right):** General information and active Buffs  
- **Play Area (Top-Left):** Critical Debuffs that require immediate player attention

---

## 🐞 Fixed

### Missile Drift Fix
Improved the **explosion position calculation** for missiles, making the detonation both **more accurate and twice as wide**.

### Movement Double-Step Bug
Fixed a velocity stacking issue that caused the player ship to **move faster than intended** when the **Speed Buff** was active.

### Post-Collision Loop Integrity
Corrected the **post-collision status evaluation order**, preventing rare cases of **status effects becoming stuck**.

---

> **"The sidebar is back. The math is moved. The sins are stronger.  
> Welcome to the final evolution of PowerShell combat."**


## [2.4.1] - 2026-03-08
### "The Ordnance Calibration"

A small but important update focused on refining the **heavy weapon system (Missiles)** and rebalancing the **Debuff mechanics** to give players more tactical options when fighting back.

---

## ➕ Added

### Lust Loot Table
Implemented a **drop system for Lust-class enemies**.  
Destroying a Lust ship now immediately grants **5 Missiles** to the player's Inventory per ship.

---

## 🔄 Changed

### Missile Overhaul
- Increased **AOE explosion radius** to **300px (approximately 2× larger)**.
- Missile explosions now **remain stationary at the detonation point**.
- Added **Piercing capability**: explosions now deal damage to **all enemies within the radius** instead of disappearing after the first hit.

### Debuff Balancing
- The **Silence status effect** now affects **Primary Fire only**.
- Players can still **deploy Missiles (Items)** even while silenced, allowing them to use emergency counterattacks.

### Lust Buff
- Increased **Lust HP to 3**.
- Added a **visible Health Bar** for clearer damage feedback during combat.

---

## 🐞 Fixed

### Score Calculation Bug
Fixed a **Runtime Error in `CollisionManager.ps1`** caused by an `if` statement nested inside the score addition parentheses.

### Missile Drifting
Fixed a bug where **missile explosions drifted off-screen**.  
The system now **locks the X-Y position immediately when the state changes to `IsExploding`**.

---

> **"Silence their guns, but you can't silence their vengeance."**



## [2.4.0] - 2026-03-08
### "The Pride & Vanity Update"

Version 2.4.0 introduces the most significant architectural shift since the project's inception. By implementing a **Decoupled Engine Logic**, the core game loop has been streamlined for future scalability. This update also completes the **"Sins of Disruption" trilogy** with the arrival of **Pride** and **Lust**, alongside the first iteration of the **Active Inventory System**.

**Version 2.4 Focus:**
- Architectural Refactoring (Logic Decoupling)
- Active Item Economy (Missile Systems)
- Complex Sin-Class AI (State-driven & Traversal AI)
- Movement-altering Status Effects (Siren Debuff)

---

## ➕ Added

### New Elite Enemy: Pride (`Pride.ps1`)
A high-durability Sin entity (**4 HP**) featuring a **State-Driven AI**. Pride uses a predictive **Lock-on Laser (Hitscan)** that targets the player's X-axis and fires after a **1-second charging phase**, followed by a **high-speed descent**.

### New Elite Enemy: Lust (`Lust.ps1`)
A tactical **triangle-class interceptor**. Lust utilizes **Sine-wave traversal** to swoop across the screen while firing **Siren projectiles**. Spawns in **coordinated 5-ship swarms** upon Level Up milestones.

### Active Inventory System (**MISSILE**)
Introduces the first **usable item type**. Players can now **store and deploy Long-range Missiles** *(Key: `E`)*. Features an **Area-of-Effect (AOE) Explosion** mechanic that deals damage within a localized radius *(Orange burst effect)*.

### New Status Effect: Siren (**Confusion**)
A high-tier debuff that triggers **Directional Inversion**. While active, **player horizontal controls are flipped** *(Left becomes Right, Right becomes Left)* for **3 seconds**, testing mental adaptability.

---

## 🔄 Changed

### Engine Refactoring (God-Object Mitigation)
Migrated massive logic blocks from `AlienStrike.ps1` into specialized functions within `GameLogic.ps1`.  
This includes the decoupling of:
- Input Handling
- Boss Spawn Logic
- Post-Collision Status Processing

### Dynamic Spawn Calibration
Recalibrated the **SpawnRate algorithm** to prevent entity overcrowding. Difficulty now scales more gracefully, focusing on **enemy quality over quantity** while capping maximum spawn frequency for improved performance.

### Enhanced Sin-Class Visuals
Implemented unique **geometry rendering** for Lust *(polygonal triangles)* and added **persistent HUD health bars** for all Sin-class entities to improve combat feedback.

### Advanced HUD Integration
The status renderer now supports:
- **Inventory Tracking (Missile counts)**
- **Siren Status Indicator (S-Icon)**

The Siren status is color-coded in **Deep Pink** for immediate player recognition.

---

## 🧹 Refactoring Notes

- **Main Loop Cleanup:** `AlienStrike.ps1` reduced by ~60% in line count  
- **State Management:** Delegated status timer management to specialized manager functions  
- **Input Abstraction:** Standardized control handling to support future status effect modifiers

---

> **"Pride locks your movement; Lust twists your direction. Survival is no longer just about aiming."**



## [2.3.0] - 2026-03-08
### "The Green-Eyed Curse Update"

Building upon the aggressive framework of version **2.2.0**, this update introduces **Envy**, the second elite sin, shifting the challenge from pure speed to **tactical survival**.

Version **2.3.0** marks the debut of the **Status Effect System**, introducing gameplay-altering debuffs that force players to adapt their strategies mid-combat. The HUD has also been overhauled with a **dynamic rendering engine** to track active buffs and debuffs in real-time.

**Version 2.3 Focus:**
- Status Effect Architecture  
- Dynamic UI/HUD Rendering  
- Tactical Combat Disruption  

---

### ➕ Added

- **New Elite Enemy: Envy (`Envy.ps1`)**  
  The second Sin-class entity. Envy features elusive, erratic movement patterns and focuses on tactical disruption rather than brute force.

- **Status Effect Framework (Debuffs)**  
  Implemented the foundational system for temporary player modifications.  
  Introduces the **Silence** status effect, which temporarily disables player weaponry.

- **Dynamic Status HUD**  
  Integrated a real-time status tracker into the sidebar.  
  The system dynamically renders active icons and countdown timers only when effects are active, keeping the interface clean and uncluttered.

- **New Projectile: Silence Bullet (`SilenceBullet.ps1`)**  
  A specialized **Magenta-colored projectile** fired by Envy that triggers the **Silence** status effect upon collision.

---

### 🔄 Changed

- **Optimized Rendering Engine**  
  Overhauled `RenderManager.ps1` to use dynamic `foreach` iteration for HUD elements.  
  This removes fixed-array constraints and allows flexible UI scaling with more reliable object rendering across different PowerShell environments.

- **Player Combat Logic**  
  Updated `Player.ps1` to include state-checking for status effects, enabling the **Silence mechanic** to override the player's primary fire capability.

- **Advanced Collision Handling**  
  Enhanced `CollisionManager.ps1` to support **Effect Payloads** on projectiles, allowing bullets to pass complex status data to the player upon impact.

- **Visual UI Feedback**  
  Added specialized **color-coded icons** (e.g., the **"Z" icon** for Silence) and **high-precision timers** to improve player awareness of active debuffs.

---

> *"Wrath tests your reflexes; Envy tests your restraint."*



## [2.2.0] - 2026-03-07
"The Wrath Unleashed Update"
Building upon the infinite arcade loop introduced in 2.1.0, this update brings a massive spike in challenge with the introduction of our first major elite enemy from the "Seven Deadly Sins" roster. 
We have successfully completed and integrated **Wrath**, establishing a new framework for advanced enemy behaviors, unique attack patterns, and boss-level encounters.
Version 2.2 Focus: 
Advanced enemy AI, new boss mechanics, and the expansion of the entity framework.

### Added
- **New Elite Enemy: Wrath** (`Wrath.ps1`): The first completed Sin. Wrath features highly aggressive movement, tracking capabilities, and high-speed projectile attacks to test player reflexes.
- **Seven Deadly Sins Framework**: Implemented the directory and foundational files for the remaining sins (`Lust`, `Gluttony`, `Greed`, `Sloth`, `Envy`, `Pride`) in preparation for future updates.
- **Advanced Enemy Architecture**: Added `BaseEnemy.ps1` to standardize complex logic, health scaling, and behaviors for elite enemies and bosses.

### Changed
- **Game Logic Update**: Updated `GameLogic.ps1` to handle elite wave spawning, ensuring Wrath appears seamlessly within the dynamic math-based scaling system.
- **Combat Adjustments**: Enhanced `EnemyBullet.ps1` to support Wrath's specialized multi-shot and burst fire patterns.
- **Collision Enhancements**: Tweaked `CollisionManager.ps1` to support the larger hitboxes and unique interactions required for Sin-class enemies.
- **Rendering**: Updated `RenderManager.ps1` to handle special visual cues and UI elements when Wrath is spawned on the screen.



## [2.1.0] - 2026-03-07
### "The Infinite Arcade Update"

This update transforms the game into a true classic arcade experience.  
We replaced hardcoded limits with dynamic math-based scaling, introduced a player lives system, and overhauled the user interface with a dedicated sidebar.

**Version 2.1 Focus:**  
Infinite gameplay loop, better player feedback via HUD, and fairer collision mechanics.

---

### ✨ Added

**Arcade Lives System**  
Players now start with **3 lives (A)**. Taking damage subtracts a life and resets the board instead of causing an instant Game Over.

**Dedicated UI Sidebar**  
Expanded the window width from **500px to 700px** to accommodate a clean, right-aligned HUD panel displaying:
- Level
- Score
- Next Level Target
- Lives

**Next Level Target**  
Added a dynamic calculation to show players exactly how many points are needed to reach the next level.

---

### 🔄 Changed & Improved

**Infinite Math-Based Scaling**  
Completely rewrote `GameLogic.ps1`.  
Replaced static `if/else` conditions with mathematical formulas (`[math]::Sqrt` and Modulo), allowing the game to smoothly scale up to **Level 999** with dynamically looping enemy colors and capped speed limits.

**Fairer Dodging**  
Reduced the hitbox size of enemy bullets (`Inflate(-5, -5)`) in `CollisionManager.ps1` to prevent frustrating **"cheap deaths"** and make dodging feel more accurate.

**Collision Handling Refactor**  
Modified collision logic to return an `IsPlayerHit` state instead of an immediate `IsGameOver` to support the new lives system.

---

### 🐛 Fixed

**Entity Boundary Limits**  
Fixed an issue where the expanded window size allowed the Player ship and Enemy spawn points to overlap into the new UI Sidebar.  
Gameplay area is now strictly restricted to **0–500px**.



## [2.0.0] - 2026-03-07
A classic vertical space shooter game refactored into a modular **Object-Oriented Game Engine** using PowerShell and System.Windows.Forms.

**Version 2.0 Focus:**
This update moves away from a monolithic script to a clean, maintainable architecture. The game logic, rendering, collision, and score systems are now separated into dedicated managers.

## 🛠️ v2.0 Refactor Highlights
*   **Modular Design:** Code split into `Entities` (Player, Enemy, Bullet) and `Managers` (Render, Collision, GameLogic).
*   **Robust Save System:** Fixed JSON serialization issues for local high scores.
*   **Optimized Loop:** Improved game loop performance with cleaner state management.

## 📂 Project Structure
```text
AlienStrike/
├── src/
│   ├── Entities/       # Game Objects
│   ├── Managers/       # Logic, Render, Collision, Score
├── AlienStrike.ps1     # Main Controller
└── scores.json         # High Scores Data
```



## [1.0.0] - 2026-03-07

### Added
- **Core Engine:** Implemented the main game loop using `System.Windows.Forms.Timer` (~60 FPS).
- **OOP Structure:** Created base `GameObject` class and derived entities (`Player`, `Enemy`, `Bullet`).
- **Rendering:** Implemented double-buffered GDI+ rendering for flicker-free graphics.
- **Player Mechanics:** Movement logic (Left/Right) and cooldown-based shooting system.
- **Level System:**
    - Added progressive difficulty scaling based on score.
    - Level 1: Basic Red enemies.
    - Level 2: Faster Orange enemies (Score > 1000).
    - Level 3: Fast Purple enemies with high spawn rate (Score > 3000).
    - Level 4: Silver enemies with **Enemy AI** (Shoot back logic) (Score > 5000).
- **Enemy AI:** Added `EnemyBullet` class and logic for enemies to fire projectiles at the player.
- **Leaderboard:**
    - Added JSON-based save system (`scores.json`).
    - Added "Hall of Fame" screen displaying Rank, Name, Level, and Score.
    - Added Name Input dialog upon Game Over.
- **UI:**
    - Start Screen with instructions.
    - HUD showing current Score and Level.
    - "Game Over" flow with seamless restart capability.

### Notes
- Initial release uses placeholder geometric shapes for all assets.