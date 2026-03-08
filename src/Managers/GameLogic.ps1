# AlienStrike\src\GameLogic.ps1

# --- Function 1: คำนวณ Level และ SpawnRate จาก Score แบบสมการ ---
function Get-GameDifficulty ($currentScore) {
    # 1. คำนวณ Level ปัจจุบัน
    $calculatedLevel = [math]::Floor([math]::Sqrt($currentScore / 750)) + 1
    $lvl = [math]::Min($calculatedLevel, 999)
    $rate = [math]::Min((3 + [math]::Floor($lvl * 1.5)), 100)
    
    # 2. คำนวณคะแนนที่ต้องการสำหรับ "เลเวลถัดไป" (Target Score)
    # สมการย้อนกลับ: (Level)^2 * 750
    $nextLevelScore = [math]::Pow($lvl, 2) * 750

    # ส่งค่าเป้าหมายคะแนนกลับไปด้วย!
    return @{ 
        Level = $lvl; 
        SpawnRate = $rate; 
        NextLevelScore = $nextLevelScore 
    }
}

# --- Function 2: สร้างศัตรู (รวมระบบ Mini-Boss: Wrath) ---
function New-EnemySpawn ($width, $level, $rnd) {
    # เผื่อความกว้างไว้ 40 เพราะ Wrath ตัวกว้าง 40 (กันเกิดแล้วทะลุขอบจอ)
    $ex = $rnd.Next(0, ($width - 40))
    $ey = -40
    
    # ==========================================
    # 1. ระบบสุ่มเกิด Mini-Boss (บาป Wrath)
    # ==========================================
    # ให้มีโอกาส 8% ที่ศัตรูตัวนี้จะกลายเป็น Wrath (ปรับเลข 8 ได้ตามความโหดที่ต้องการ)
    $spawnChance = $rnd.Next(1, 101) 
    
    if ($spawnChance -le 8) {
        
        # คำนวณความโกรธ (Sin Level) เก่งขึ้นทุกๆ 200 เลเวล
        # เลเวล 1-199 จะได้ 0+1 = 1 | เลเวล 200-399 จะได้ 1+1 = 2
        $sinLevel =[math]::Floor($level / 200) + 1
        
        # บังคับไม่ให้ความโกรธเกินระดับ 5
        $sinLevel = [math]::Min($sinLevel, 5)
        
        # ส่ง Wrath ออกไปเกิดแทนศัตรูธรรมดา!
        return [Wrath]::new($ex, $ey, $sinLevel)
    }

    # if ($spawnChance -le 100) { 
        
    #     # ล็อกให้เป็นเลเวล 5 (โหดสุด) ไปเลย
    #     $sinLevel = 5
        
    #     return [Wrath]::new($ex, $ey, $sinLevel)
    # }

    # ==========================================
    # 2. ถ้ายกเว้นด้านบน (92%) ให้เกิดศัตรูธรรมดา
    # ==========================================
    $minSpeed = 2 + [math]::Floor($level / 2)
    $maxSpeed = $minSpeed + 3 + [math]::Floor($level / 10)
    
    # บังคับความเร็วสูงสุด ป้องกันบั๊ก
    $minSpeed = [math]::Min($minSpeed, 20)
    $maxSpeed = [math]::Min($maxSpeed, 25)
    
    $speed = $rnd.Next($minSpeed, $maxSpeed)
    
    # ระบบสีวนลูป
    $colorList = @(
        [System.Drawing.Color]::Red,     
        [System.Drawing.Color]::Orange,
        [System.Drawing.Color]::Purple,
        [System.Drawing.Color]::Cyan,
        [System.Drawing.Color]::Lime,[System.Drawing.Color]::Gold,
        [System.Drawing.Color]::Silver   
    )
    
    $colorIndex = ($level - 1) % $colorList.Count
    $enemyColor = $colorList[$colorIndex]
    
    if ($level -ge 999) {
        $enemyColor = [System.Drawing.Color]::DarkRed 
    }
    
    return [Enemy]::new($ex, $ey, $speed, $enemyColor)
}


# ==========================================
# --- ฟังก์ชันจัดการควบคุมผู้เล่น (ย้ายมาจากหน้าหลัก) ---
# ==========================================
function Handle-PlayerInput {
    if ($Script:sirenTimer -gt 0) { $Script:sirenTimer-- }

    $moveLeft = ($Script:keysPressed["A"] -or $Script:keysPressed["Left"])
    $moveRight = ($Script:keysPressed["D"] -or $Script:keysPressed["Right"])

    if ($Script:sirenTimer -gt 0) {
        if ($moveLeft) { $Script:player.MoveRight(500) }
        if ($moveRight) { $Script:player.MoveLeft() }
    } else {
        if ($moveLeft) { $Script:player.MoveLeft() }
        if ($moveRight) { $Script:player.MoveRight(500) }
    }
    
    if ($Script:keysPressed["W"] -or $Script:keysPressed["Space"] -or $Script:keysPressed["Up"]) {
        if ($Script:silenceTimer -le 0 -and $Script:player.CanShoot()) {
            $px = $Script:player.X
            $py = $Script:player.Y

            if ($Script:wrathBuffLevel -eq 2) {
                [void]$Script:bullets.Add([Bullet]::new($px + 4, $py, 0))    
                [void]$Script:bullets.Add([Bullet]::new($px + 20, $py, 0))   
                [void]$Script:bullets.Add([Bullet]::new($px - 4, $py, -4))   
                [void]$Script:bullets.Add([Bullet]::new($px + 28, $py, 4))   
            } elseif ($Script:wrathBuffLevel -eq 1) {
                [void]$Script:bullets.Add([Bullet]::new($px + 4, $py, 0))
                [void]$Script:bullets.Add([Bullet]::new($px + 20, $py, 0))
            } else {
                [void]$Script:bullets.Add([Bullet]::new($px + 12, $py))
            }
            $Script:player.ResetCooldown()
        }
    }

    if ($Script:keysPressed["E"] -and $Script:inventory.Count -gt 0) {
        $Script:keysPressed["E"] = $false 
        $activeItem = $Script:inventory[0]
        $Script:inventory.RemoveAt(0)
        
        if ($activeItem -eq "Missile") {
            [void]$Script:bullets.Add([Missile]::new($Script:player.X + 15, $Script:player.Y))
        }
    }
    
    $Script:player.Update()
}

# ==========================================
# --- ฟังก์ชันจัดการ UI (ย้ายมาจากหน้าหลัก) ---
# ==========================================
function Get-UIStatus {
    $activeBuffs = @()
    $activeDebuffs = @()

    if ($Script:wrathBuffTimer -gt 0) {
        $bSecondsLeft = [math]::Round(($Script:wrathBuffTimer / 60.0), 1)
        $bColor = if ($Script:wrathBuffLevel -eq 2) { [System.Drawing.Brushes]::Red } else { [System.Drawing.Brushes]::DeepSkyBlue }
        $activeBuffs += [PSCustomObject]@{ Icon = "W"; Value = "{0:N1}" -f $bSecondsLeft; Color = $bColor }
    }

    if ($Script:inventory.Count -gt 0) {
        if ($Script:inventory[0] -eq "Missile") {
            $activeBuffs += [PSCustomObject]@{ Icon = "M"; Value = "x$($Script:inventory.Count)"; Color = [System.Drawing.Brushes]::Cyan }
        }
    }

    if ($Script:silenceTimer -gt 0) {
        $dSecondsLeft = [math]::Round(($Script:silenceTimer / 60.0), 1)
        $activeDebuffs += [PSCustomObject]@{ Icon = "Z"; Value = "{0:N1}" -f $dSecondsLeft; Color = [System.Drawing.Brushes]::Magenta }
    }

    if ($Script:sirenTimer -gt 0) {
        $sSecondsLeft = [math]::Round(($Script:sirenTimer / 60.0), 1)
        $activeDebuffs += [PSCustomObject]@{ Icon = "S"; Value = "{0:N1}" -f $sSecondsLeft; Color = [System.Drawing.Brushes]::DeepPink }
    }

    return @{ Buffs = $activeBuffs; Debuffs = $activeDebuffs }
}

# ==========================================
# --- ฟังก์ชันเช็คการเกิดของบอสพิเศษ (แยกออกมาเพื่อความคลีน) ---
# ==========================================
function Check-BossSpawns {
    # 1. เช็คปล่อยฝูง Lust ตอน Level Up
    if ($Script:level -gt $Script:currentTrackedLevel) {
        $Script:currentTrackedLevel = $Script:level
        
        for ($i = 0; $i -lt 5; $i++) {
            if ($i % 2 -eq 0) {
                $l = [Lust]::new(-50 - ($i * 40), 50 + ($i * 20), 1) 
            } else {
                $l = [Lust]::new(550 + ($i * 40), 50 + ($i * 20), -1) 
            }
            [void]$Script:enemies.Add($l)
        }
    }

    # 2. เช็คปล่อย Pride ทุกๆ 5000 คะแนน
    if ($Script:score -ge $Script:nextPrideScoreTarget) {
        $pride = [Pride]::new(230, -50)
        [void]$Script:enemies.Add($pride)
        $Script:nextPrideScoreTarget += 5000 
    }
}



# ==========================================
# --- ฟังก์ชันจัดการผลลัพธ์หลังการชน (ย้ายมาจาก Main) ---
# ==========================================
function Handle-PostCollision ($collisionResult) {
    
    # -----------------------------------
    # 1. ระบบสุ่ม Buff จากการฆ่า Wrath
    # -----------------------------------
    if ($collisionResult.WrathKills -gt 0) {
        for ($k = 0; $k -lt $collisionResult.WrathKills; $k++) {
            $roll = $Script:rnd.Next(1, 101) # สุ่ม 1-100
            
            if ($roll -le 5) {
                $Script:wrathBuffLevel = 2
                $Script:wrathBuffTimer = 420 
            } else {
                if ($Script:wrathBuffLevel -lt 2) {
                    $Script:wrathBuffLevel = 1
                }
                $Script:wrathBuffTimer = 420 
            }
        }
    }

    # ระบบแจกไอเทมจาก Lust
    if ($collisionResult.LustKills -gt 0) {
        for ($i = 0; $i -lt $collisionResult.LustKills; $i++) {
            # ฆ่า Lust 1 ตัว ได้มิสไซล์ 5 อัน
            1..5 | ForEach-Object { [void]$Script:inventory.Add("Missile") }
        }
    }

    # 2. ลดเวลา Buff 
    if ($Script:wrathBuffTimer -gt 0) { 
        $Script:wrathBuffTimer -= 1 
        if ($Script:wrathBuffTimer -le 0) {
            $Script:wrathBuffLevel = 0 
        }
    }

    # 3. ลดเวลาสถานะใบ้ และ เช็คการติดสถานะใบ้
    if ($Script:silenceTimer -gt 0) { 
        $Script:silenceTimer -= 1 
    }
    if ($collisionResult.ApplySilence) {
        $Script:silenceTimer = 180 
    }

    # 4. เช็คติดสถานะเดินหลอน (Siren)
    # (เราไม่ใส่ลดเวลาตรงนี้ เพราะมันไปลดอยู่ใน Handle-PlayerInput แล้วครับ)
    if ($collisionResult.ApplySiren) {
        $Script:sirenTimer = 180 
    }

    # 5. อัปเดตคะแนน
    if ($collisionResult.ScoreAdded -gt 0) {
        $Script:score += $collisionResult.ScoreAdded
    }

    # 6. เช็คว่าผู้เล่นโดนดาเมจไหม
    if ($collisionResult.IsPlayerHit) {
        $Script:lives -= 1   # ลดชีวิต 1 ดวง
        
        if ($Script:lives -le 0) {
            Do-GameOver
            return $true # <--- รีเทิร์น True เพื่อบอก Game Loop ว่าให้หยุดทำงาน (ตายแล้ว)
        } else {
            $Script:player.X = 225
            $Script:player.Y = 500
            
            $Script:enemies.Clear()
            $Script:enemyBullets.Clear()
            $Script:bullets.Clear()
        }
    }

    return $false # <--- รีเทิร์น False แปลว่ายังมีชีวิตอยู่ เล่นเฟรมต่อไปได้
}