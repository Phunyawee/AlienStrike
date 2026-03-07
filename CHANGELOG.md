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