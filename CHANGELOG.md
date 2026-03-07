## [2.1.0] - 2025-01-29
### "The Infinite Arcade Update"

This update transforms the game into a true classic arcade experience.  
We replaced hardcoded limits with dynamic math-based scaling, introduced a player lives system, and overhauled the user interface with a dedicated sidebar.

**Version 2.1 Focus:**  
Infinite gameplay loop, better player feedback via HUD, and fairer collision mechanics.

---

### ✨ Added

**Arcade Lives System**  
Players now start with **3 lives (❤)**. Taking damage subtracts a life and resets the board instead of causing an instant Game Over.

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



## [2.0.0] - 2025-01-29
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



## [1.0.0] - 2025-01-29

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