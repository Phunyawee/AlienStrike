# AlienStrike - Technical Wiki (v4.0.0)

## 😈 Elite Enemy Encyclopedia (The 7 Sins)

Each **Sin-class enemy** introduces a unique disruption mechanic that forces players to adapt their combat style.

---

### 1. Lust — *Directional Inversion*

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/lust.gif" width="200"> | **Ability:** Fires **Siren Bullets (Pink)**. Upon impact, the player's horizontal controls are inverted **(Left ↔ Right)** for **3 seconds**. |

---

### 2. Gluttony — *Shield Devour*

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/gluttony.gif" width="200"> | **Ability:** Fires a massive **Purple Blast**. If hit, it **consumes 50% of the player's Defense Shield** and converts the energy into **HP for the boss**. |

---

### 3. Greed — *Inventory Erasure*

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/greed.gif" width="200"> | **Ability:** A fast-moving **gold star entity** that fires a **Gold Arrow**. Impact results in an **instant wipe of the player's entire inventory** *(Missiles, Lasers, Nukes)*. |

---

### 4. Sloth — *Disruption Pulse*

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/sloth.gif" width="200"> | **Ability:** Drops a **multi-stage bomb** that detonates into a **Shockwave**. Being caught in the pulse triggers the **Jammer effect**, disabling the **[E] item key**. |

---

### 5. Wrath — *Scatter Shot*

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/wrath.gif" width="200"> | **Ability:** Aggressive **erratic movement** combined with a **5-way shotgun spread**, designed to overwhelm player positioning. |

---

### 6. Envy — *Weapon Jam*

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/envy.gif" width="200"> | **Ability:** Fires **Silence Bullets (Magenta)**. Triggers the **Silence status**, temporarily disabling the player's **primary fire**. |

---

### 7. Pride — *Hitscan Beam*

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/pride.gif" width="200"> | **Ability:** Charges a powerful **Vertical Laser**. Telegraphed by a **red dotted line**, followed by an **instant-hit beam** and a **high-speed charge attack**. |

---

## 👑 Gatekeeper-Class Entity
### RealPride — *Absolute Annihilation*

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/realpride.gif" width="200"> | **Ability:** A Gatekeeper-class entity that appears after defeating **Gluttony three times**. RealPride tracks the player using **smooth pursuit AI** and enforces a **Cataclysm countdown**. If not defeated within **15 laser cycles**, it unleashes **Cataclysm Wave**, a screen-wide fatal attack that results in **instant Game Over**, bypassing shields, lives, and Immortal status. |

---

## 🔥 Final Sin Entity
### Lucifer — *The King of Hell*

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/lucifer.gif" width="200"> | **Ability:** The ultimate enemy of AlienStrike. Lucifer is a **multi-part boss entity** composed of destructible weapon systems. The battle revolves around **strategically dismantling its combat modules** to expose the Core. Destroying components directly reduces Lucifer's main HP. When its health drops below **7000**, Lucifer opens a **Magenta Summoning Portal**, continuously spawning **Wrath-class enemies** to overwhelm the battlefield. |

---

### 🧩 Boss Architecture

| Component | HP | Function |
|---|---|---|
| Side Cannon (Left) | 2000 | Fires **Fatal Beam** attacks |
| Side Cannon (Right) | 2000 | Fires **Fatal Beam** attacks |
| Top Turret (Left) | 400 | Fires **Armor-Piercing Projectiles** |
| Top Turret (Right) | 400 | Fires **Armor-Piercing Projectiles** |

---

### ⚙ Destruction Feedback System

| Destroyed Part | Core HP Damage |
|---|---|
| Cannon | -4000 |
| Turret | -1000 |

Destroying Lucifer’s weapon systems weakens the boss **both tactically and structurally**, forcing a transition toward **Core exposure**.

---

### 🔄 Combat Phases

| Phase | Condition | Effect |
|---|---|---|
| Phase 0 | Boss Appears | Core protected by armor |
| Phase 1 | Cannons Destroyed | Core shield weakened |
| Phase 2 | Turrets Destroyed | Core becomes fully vulnerable |
| Phase 3 | HP < 7000 | **Wrath Portal** begins summoning enemies |

---

> **"Heaven sent you. Hell built this. Only one survives the Final Sin."**

---

# 🚀 Player Arsenal & Tactical Systems

## Defensive Layer: **Defense Shield [D]**

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/shield.gif" width="200"> | **System:** A stackable **energy shield** represented by a **Cyan Aura** around the ship. Automatically blocks **damage and debuffs**. **Maximum capacity: 400 hits.** |

---

## Heavy Weaponry: **Missile [M]**

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/missile.gif" width="200"> | **Tactical:** A high-damage **AOE projectile**. Upon impact or range expiration, it triggers a **massive explosion** that **pierces multiple enemies**. |

---

## Precision Weaponry: **Laser [L]**

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/laser.gif" width="200"> | **Tactical:** A **Lime Hitscan Beam** that tracks the ship's horizontal position. Ideal for **lane clearing** and **high-HP targets** in a **1-second burst**. |

---

## Ultimate Weaponry: **Nuke [N]**

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/nuke.gif" width="200"> | **Ultimate:** Obtained from **Gluttony**. Clears **all common enemies on screen** and deals **heavy damage to Sin-class bosses**, triggering a **screen-wide wipe effect**. |

---

## Combat Buffs: **Wrath [W] & Speed [S]**

| Image | Description |
|---|---|
| <img src="./Images/wiki_v1/buffs.gif" width="200"> | **Wrath [W]:** Stack **3 kills** to unlock **4-way fire mode**.<br><br>**Speed [S]:** Reward from defeating **Sloth**. Grants **200% movement speed for 7 seconds**. |

---

> **"Strategy is the only weapon that can't be jammed."**