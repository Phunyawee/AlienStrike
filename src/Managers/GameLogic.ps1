# AlienStrike\src\GameLogic.ps1
# --- ฟังก์ชันเพิ่มไอเทมเข้ากระเป๋าแบบจัดกลุ่ม ---
function Add-To-Inventory ($itemType) {
    # 1. หาตำแหน่งสุดท้ายของไอเทมประเภทเดียวกัน
    $lastIdx = -1
    for ($i = 0; $i -lt $Script:inventory.Count; $i++) {
        if ($Script:inventory[$i] -eq $itemType) { $lastIdx = $i }
    }

    # 2. ถ้าเจอ ให้แทรกต่อท้ายกลุ่มเดิมทันที
    if ($lastIdx -ne -1) {
        $Script:inventory.Insert($lastIdx + 1, $itemType)
    } else {
        # 3. ถ้าไม่มีประเภทนี้เลย ให้ต่อท้ายแถวตามปกติ
        [void]$Script:inventory.Add($itemType)
    }
}



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
    if ($Script:speedTimer -gt 0) { $Script:speedTimer-- } # ลดเวลาบัฟ Speed ตรงนี้ด้วย

    $moveLeft = ($Script:keysPressed["A"] -or $Script:keysPressed["Left"])
    $moveRight = ($Script:keysPressed["D"] -or $Script:keysPressed["Right"])

    # 1. คำนวณความเร็ว (ปกติ 8, บัฟ 16)
    $currentSpeed = 8
    if ($Script:speedTimer -gt 0) { $currentSpeed = 16 }

    # 2. คำนวณทิศทาง (ปกติ หรือ Siren)
    $direction = 0
    if ($moveLeft) { $direction = -1 }
    if ($moveRight) { $direction = 1 }

    if ($Script:sirenTimer -gt 0) { $direction *= -1 } # สลับทิศถ้าติด Siren

    # 3. สั่งเคลื่อนที่ครั้งเดียวจบ!
    if ($direction -ne 0) {
        $Script:player.Move($direction * $currentSpeed)
    }

    # --- ส่วนยิงปืนและไอเทมเหมือนเดิม ---
    if ($Script:keysPressed["W"] -or $Script:keysPressed["Space"] -or $Script:keysPressed["Up"]) {
        if ($Script:silenceTimer -le 0 -and $Script:player.CanShoot()) {
            $px = $Script:player.X; $py = $Script:player.Y
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
        
        # ถ้าเป็นขั้น 2 โชว์เวลาถอยหลัง (สีแดง)
        if ($Script:wrathBuffLevel -eq 2) {
            $activeBuffs += [PSCustomObject]@{ 
                Icon = "W"; 
                Value = "{0:N1}s" -f $bSecondsLeft; 
                Color = [System.Drawing.Brushes]::Red 
            }
        } 
        # ถ้าเป็นขั้น 1 โชว์จำนวน Stack (สีฟ้า) เช่น W 3/5
        else {
            $activeBuffs += [PSCustomObject]@{ 
                Icon = "W"; 
                Value = "$($Script:wrathStackCount)/3"; 
                Color = [System.Drawing.Brushes]::DeepSkyBlue 
            }
        }
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

    if ($Script:jammerTimer -gt 0) {
        $activeDebuffs += [PSCustomObject]@{ Icon = "J"; Value = "{0:N1}s" -f ($Script:jammerTimer/60.0); Color = [System.Drawing.Brushes]::Yellow }
    }

    if ($Script:speedTimer -gt 0) {
        $sSecondsLeft = [math]::Round(($Script:speedTimer / 60.0), 1)
        $activeBuffs += [PSCustomObject]@{ 
            Icon = "S"; 
            Value = "{0:N1}s" -f $sSecondsLeft; 
            Color = [System.Drawing.Brushes]::SkyBlue 
        }
    }
    
    # Buff: Defense Shield (ไอคอน D สีเหลืองทอง)
    if ($Script:defenseHits -gt 0) {
        $activeBuffs += [PSCustomObject]@{ 
            Icon = "D"; 
            Value = "x$Script:defenseHits"; 
            Color = [System.Drawing.Brushes]::Gold 
        }
    }

    return @{ Buffs = $activeBuffs; Debuffs = $activeDebuffs }
}

# ==========================================
# --- ฟังก์ชันเช็คการเกิดของบอสพิเศษ (แยกออกมาเพื่อความคลีน) ---
# ==========================================
function Check-BossSpawns {
     # เช็คว่ามี Gluttony อยู่ในสนามไหม
    $isGluttonyOut = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Gluttony" }).Count -gt 0

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
        $Script:nextPrideScoreTarget += 10000 
    }

     # --- 1. ระบบ Greed (ตัวล้างสนาม) ---
    if ($Script:score -gt 0 -and $Script:score -ge $Script:nextGreedTarget) {
        # ลบศัตรูตัวอื่นทิ้งทั้งหมด "ยกเว้น Gluttony"
        for ($i = $Script:enemies.Count - 1; $i -ge 0; $i--) {
            if ($Script:enemies[$i].GetType().Name -ne "Gluttony") {
                $Script:enemies.RemoveAt($i)
            }
        }

        # เสก Greed
        $gx = $Script:rnd.Next(100, 400); $gy = $Script:rnd.Next(100, 200)
        [void]$Script:enemies.Add([Greed]::new($gx, $gy, $Script:player))
        $Script:nextGreedTarget += 20000 
    }

    # # เช็คปล่อย Sloth
    # if ($Script:prideKills -ge 5 -and $Script:rnd.Next(0, 100) -lt 50) {
    #     $Script:prideKills = 0 # รีเซ็ต
    #     # ปล่อย 2 ลำ ซ้ายและขวา
    #     [void]$Script:enemies.Add([Sloth]::new(-100, 150, 100, 150, 0))   # ลำซ้าย ทิ้งทันที
    #     [void]$Script:enemies.Add([Sloth]::new(700, 150, 450, 150, 90))  # ลำขวา ทิ้งหลังผ่านไป 1.5 วิ
    # }

    if ($true) { 
    # หมายเหตุ: ถ้าใส่ $true เฉยๆ มันจะปล่อย Sloth ออกมาทุก Frame จนเครื่องค้างได้
    # แนะนำให้เช็คจาก $Script:prideKills -ge 1 แทน เพื่อให้ปล่อยเป็นรอบๆ
    if ($Script:prideKills -ge 1) {
        $Script:prideKills = 0 # รีเซ็ตทันที

        # ปล่อย 2 ลำ ซ้ายและขวา
        [void]$Script:enemies.Add([Sloth]::new(-100, 150, 100, 150, 0))   # ลำซ้าย: ออกทันที
        [void]$Script:enemies.Add([Sloth]::new(700, 150, 450, 150, 300)) # ลำขวา: ออกหลังผ่านไป 5 วิ (300 เฟรม)
    }
}
}



# ==========================================
# --- ฟังก์ชันจัดการผลลัพธ์หลังการชน (ย้ายมาจาก Main) ---
# ==========================================
function Handle-PostCollision ($collisionResult) {
    # ==========================================
    # 1. ระบบคะแนน (Scoring)
    # ==========================================
    if ($collisionResult.ScoreAdded -gt 0) {
        $Script:score += $collisionResult.ScoreAdded
    }

    # ==========================================
    # 2. ระบบจัดการหลังศัตรูตาย (Loot & Buffs)
    # ==========================================
    
    # --- ฆ่า Gluttony (ได้ Nuke) ---
    if ($collisionResult.GluttonyKills -gt 0) {
        Add-To-Inventory "Nuke"
        Write-Host ">>> NUKE ACQUIRED! <<<" -ForegroundColor Red
    }

    # --- ฆ่า Lust (ได้ Missile 5 อัน) ---
    if ($collisionResult.LustKills -gt 0) {
        for ($i = 0; $i -lt $collisionResult.LustKills; $i++) {
            1..5 | ForEach-Object { Add-To-Inventory "Missile" }
        }
    }

    # --- ฆ่า Sloth (ได้ Speed Buff 7 วิ) ---
    if ($collisionResult.SlothKills -gt 0) {
        $Script:speedTimer = 420 
    }

    # --- ฆ่า Greed (ได้โล่ 10 อัน) ---
    if ($collisionResult.GreedKills -gt 0) {
        $Script:defenseHits += (10 * $collisionResult.GreedKills)
        Write-Host ">>> DEFENSE SHIELD REINFORCED! <<<" -ForegroundColor Cyan
    }

    # --- ฆ่า Pride (สะสมยอดเพื่อเรียก Sloth) ---
    if ($collisionResult.PrideKilled) { 
        $Script:prideKills++ 
    }

    # --- ฆ่า Wrath (สะสม Stack ร่างแดง) ---
    if ($collisionResult.WrathKills -gt 0 -and $Script:wrathBuffLevel -lt 2) {
        for ($k = 0; $k -lt $collisionResult.WrathKills; $k++) {
            $Script:wrathStackCount++
            if ($Script:wrathStackCount -ge 3) {
                $Script:wrathBuffLevel = 2; $Script:wrathBuffTimer = 840; $Script:wrathStackCount = 0
            } else {
                $Script:wrathBuffLevel = 1; $Script:wrathBuffTimer = 420
            }
        }
    }

    # ==========================================
    # 3. ระบบสถานะผิดปกติ (Debuffs)
    # ==========================================
    
    # Silence (ใบ้ปืนหลัก)
    if ($Script:silenceTimer -gt 0) { $Script:silenceTimer-- }
    if ($collisionResult.ApplySilence) { $Script:silenceTimer = 180 }

    # Siren (เดินสลับทิศ - ลดเวลาใน Handle-PlayerInput แล้ว)
    if ($collisionResult.ApplySiren) { $Script:sirenTimer = 180 }

    # Jammer (ใบ้ปุ่ม E)
    if ($Script:jammerTimer -gt 0) { $Script:jammerTimer-- }
    if ($collisionResult.ApplyJammer) { $Script:jammerTimer = 300 }

    # Greed (ล้างคลัง)
    if ($collisionResult.ApplyGreed) {
        $Script:inventory.Clear()
        Write-Host ">>> INVENTORY WIPED! <<<" -ForegroundColor Yellow
    }

    # ==========================================
    # 4. ระบบการเกิดของ Gluttony (Stage System)
    # ==========================================
    
    # จำกัดโล่สูงสุด 400
    if ($Script:defenseHits -gt 400) { $Script:defenseHits = 400 }

    # เช็คว่าบอสจอมตะกละอยู่ในสนามไหม
    $isGluttonyOut = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Gluttony" }).Count -gt 0

    if (-not $isGluttonyOut) {
        # Stage 0 -> 1 (ที่โล่ 100)
        if ($Script:defenseHits -ge 100 -and $Script:gluttonyStage -eq 0) {
            [void]$Script:enemies.Add([Gluttony]::new(210, -100, $Script:player))
            $Script:gluttonyStage = 1
        }
        # Stage 1 -> 2 (ที่โล่ 200)
        elseif ($Script:defenseHits -ge 200 -and $Script:gluttonyStage -eq 1) {
            [void]$Script:enemies.Add([Gluttony]::new(210, -100, $Script:player))
            $Script:gluttonyStage = 2
        }
    }

    # ระบบ Reset Stage: ถ้าโล่ลดต่ำกว่า 100 ให้เริ่มนับหนึ่งใหม่ได้
    if ($Script:defenseHits -lt 100) { $Script:gluttonyStage = 0 }

    # ==========================================
    # 5. การจัดการเวลา Buff (Timers)
    # ==========================================
    if ($Script:wrathBuffTimer -gt 0) { 
        $Script:wrathBuffTimer--
        if ($Script:wrathBuffTimer -le 0) { $Script:wrathBuffLevel = 0; $Script:wrathStackCount = 0 }
    }
    if ($Script:speedTimer -gt 0) { $Script:speedTimer-- }

    # ==========================================
    # 6. ตรวจสอบสถานะการตาย (GameOver Check)
    # ==========================================
    if ($collisionResult.IsPlayerHit) {
        $Script:lives--
        if ($Script:lives -le 0) { Do-GameOver; return $true }
        else {
            $Script:player.X = 225; $Script:player.Y = 500
            $Script:enemies.Clear(); $Script:enemyBullets.Clear(); $Script:bullets.Clear()
        }
    }

    return $false 
}