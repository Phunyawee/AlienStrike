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