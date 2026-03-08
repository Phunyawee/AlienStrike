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