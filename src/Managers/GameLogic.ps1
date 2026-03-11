# AlienStrike\src\GameLogic.ps1
# --- ฟังก์ชันเพิ่มไอเทมเข้ากระเป๋าแบบจัดกลุ่ม ---
# --- ฟังก์ชันเพิ่มไอเทมเข้ากระเป๋าแบบจัดกลุ่ม ---
function Add-To-Inventory ($itemType) {
    $lastIdx = -1
    for ($i = 0; $i -lt $Script:inventory.Count; $i++) {
        if ($Script:inventory[$i] -eq $itemType) { $lastIdx = $i }
    }
    if ($lastIdx -ne -1) { $Script:inventory.Insert($lastIdx + 1, $itemType) }
    else { [void]$Script:inventory.Add($itemType) }
}

# --- คำนวณความยาก (Optimised) ---
function Get-GameDifficulty ($currentScore) {
    $calculatedLevel = [math]::Floor([math]::Sqrt($currentScore / 750)) + 1
    $lvl = [math]::Min($calculatedLevel, 999)
    $rate = [math]::Min((2 + ($lvl * 0.5)), 15) # สูงสุด 15% กันแลค
    return @{ Level = $lvl; SpawnRate = $rate; NextLevelScore = ([math]::Pow($lvl, 2) * 750) }
}

# --- สร้างศัตรูธรรมดา ---
function New-EnemySpawn ($width, $level, $rnd) {
    $ex = $rnd.Next(0, ($width - 40))
    if ($rnd.Next(1, 101) -le 8) {
        return [Wrath]::new($ex, -40, [math]::Min(([math]::Floor($level / 200) + 1), 5))
    }
    $minS = [math]::Min((2 + [math]::Floor($level / 2)), 15)
    $speed = $rnd.Next($minS, ($minS + 5))
    $colors = @([System.Drawing.Color]::Red, [System.Drawing.Color]::Orange, [System.Drawing.Color]::Purple, [System.Drawing.Color]::Cyan, [System.Drawing.Color]::Lime, [System.Drawing.Color]::Gold)
    return [Enemy]::new($ex, -40, $speed, $colors[($level - 1) % $colors.Count])
}

# ==========================================
# --- [ตรวจสอบบอส] ฟังก์ชันเช็คการเกิดบอส ---
# ==========================================
function Check-BossSpawns {
    # เช็คสถานะปัจจุบันของบอสในสนาม
    $isLuciferActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" }).Count -gt 0
    $isRealPrideActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "RealPride" }).Count -gt 0
    $isGluttonyActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Gluttony" }).Count -gt 0

    # 1. ถ้า Lucifer อยู่ ห้ามทุกอย่าง (Final Arena)
    if ($isLuciferActive) { return }

    # 2. เงื่อนไขเรียก Lucifer (เมื่อฆ่า RealPride ครบ 2 ตัว)
    if ($Script:realPrideDefeatedTotal -ge 2 -and -not $isLuciferActive) {
        if ($Script:luciferWarningTimer -le 0) {
            # ล้างกระดานและเริ่มนับ 3 วิ
            $Script:enemies.Clear(); $Script:enemyBullets.Clear(); $Script:bullets.Clear()
            $Script:luciferWarningTimer = 180 
        }
        
        if ($Script:luciferWarningTimer -gt 0) {
            $Script:luciferWarningTimer--
            if ($Script:luciferWarningTimer -eq 1) {
                # เสก Lucifer
                [void]$Script:enemies.Add([Lucifer]::new(200, -150, $Script:player))
                # [สำคัญ] รีเซ็ตยอดคิลเพื่อไม่ให้มันรัน Clear() ซ้ำซ้อนในเฟรมถัดไป
                $Script:realPrideDefeatedTotal = 0 
            }
            return 
        }
    }

    # 3. ถ้า RealPride อยู่ ห้ามสปอนตัวอื่น (Gatekeeper Arena)
    if ($isRealPrideActive) { return }

    # 4. เงื่อนไขเกิด RealPride (ฆ่า Gluttony ครบ 3)
    if ($Script:totalGluttonyKills -ge 3) {
        $Script:totalGluttonyKills = 0
        $Script:gluttonyStage = 0
        # Clear ลูกกระจ๊อก
        $minions = $Script:enemies | Where-Object { $_ -isnot [BaseEnemy] }
        foreach ($m in $minions) { [void]$Script:enemies.Remove($m) }
        [void]$Script:enemies.Add([RealPride]::new(210, -150, $Script:player))
        return
    }

    # --- บอสตัวอื่นๆ (Lust, Greed, Gluttony, Sloth) ---
    
    # Greed (ทุก 20,000 แต้ม)
    if ($Script:score -gt 0 -and $Script:score -ge $Script:nextGreedTarget) {
        $minions = $Script:enemies | Where-Object { $_ -isnot [BaseEnemy] }
        foreach ($m in $minions) { [void]$Script:enemies.Remove($m) }
        [void]$Script:enemies.Add([Greed]::new($Script:rnd.Next(100, 400), $Script:rnd.Next(100, 200), $Script:player))
        $Script:nextGreedTarget += 20000 
    }

    # Pride ปกติ (ทุก 100,000 แต้ม)
    if ($Script:score -ge $Script:nextPrideScoreTarget) {
        [void]$Script:enemies.Add([Pride]::new(230, -50))
        $Script:nextPrideScoreTarget += 100000 
    }

    # Lust (Level Up)
    if ($Script:level -gt $Script:currentTrackedLevel) {
        $Script:currentTrackedLevel = $Script:level
        for ($i = 0; $i -lt 5; $i++) {
            $dir = if ($i % 2 -eq 0) { 1 } else { -1 }
            $sx = if ($dir -eq 1) { -50 - ($i*40) } else { 550 + ($i*40) }
            [void]$Script:enemies.Add([Lust]::new($sx, 50 + ($i*20), $dir))
        }
    }

    # Gluttony (Stage based on Shield)
    if (-not $isGluttonyActive) {
        $shouldSpawnG = $false
        if ($Script:defenseHits -ge 300 -and $Script:gluttonyStage -eq 2) { $Script:gluttonyStage = 3; $shouldSpawnG = $true }
        elseif ($Script:defenseHits -ge 200 -and $Script:gluttonyStage -eq 1) { $Script:gluttonyStage = 2; $shouldSpawnG = $true }
        elseif ($Script:defenseHits -ge 100 -and $Script:gluttonyStage -eq 0) { $Script:gluttonyStage = 1; $shouldSpawnG = $true }
        if ($shouldSpawnG) { [void]$Script:enemies.Add([Gluttony]::new(210, -100, $Script:player)) }
    }

    # Sloth (เมื่อ Pride ตาย)
    if ($Script:prideKills -ge 1) {
        $Script:prideKills = 0
        [void]$Script:enemies.Add([Sloth]::new(-100, 150, 100, 150, 0))
        [void]$Script:enemies.Add([Sloth]::new(700, 150, 450, 150, 180))
    }
}

# ==========================================
# --- [Optimised] จัดการหลังการชน ---
# ==========================================
function Handle-PostCollision ($collisionResult) {
    if ($collisionResult.ScoreAdded -gt 0) { $Script:score += $collisionResult.ScoreAdded }

    $isLuciferActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" }).Count -gt 0

    # รางวัลพิเศษในสนาม Lucifer
    if ($collisionResult.WrathKills -gt 0 -and $isLuciferActive) {
        for ($i=0;$i-lt $collisionResult.WrathKills;$i++) {
            1..5 | ForEach-Object { Add-To-Inventory "Laser"; Add-To-Inventory "Missile" }
        }
    }

    if ($collisionResult.GluttonyKills -gt 0) {
        Add-To-Inventory "Nuke"
        $Script:totalGluttonyKills += $collisionResult.GluttonyKills
        Write-Host "Gluttony Defeated. RealPride Progress: $Script:totalGluttonyKills / 3" -ForegroundColor Magenta
    }

    if ($collisionResult.RealPrideKilled) {
        $Script:realPrideDefeatedTotal++
        $Script:totalGluttonyKills = 0
        [void]$Script:enemyBullets.Add([SovereignPulse]::new($Script:player.Y + 5))
        Write-Host ">>> GATEKEEPER DEFEATED ($Script:realPrideDefeatedTotal / 2) <<<" -ForegroundColor Yellow
    }

    # บัฟ/ไอเทมอื่นๆ
    if ($collisionResult.LustKills -gt 0) { for($i=0;$i-lt $collisionResult.LustKills;$i++){ 1..5 | ForEach-Object { Add-To-Inventory "Missile" } } }
    if ($collisionResult.SlothKills -gt 0) { $Script:speedTimer = 420 }
    if ($collisionResult.GreedKills -gt 0) { $Script:defenseHits += (10 * $collisionResult.GreedKills) }
    if ($collisionResult.PrideKilled) { $Script:prideKills++ }

    # Wrath Stack System
    if ($collisionResult.WrathKills -gt 0 -and $Script:wrathBuffLevel -lt 2) {
        for ($k = 0; $k -lt $collisionResult.WrathKills; $k++) {
            $Script:wrathStackCount++
            if ($Script:wrathStackCount -ge 3) { $Script:wrathBuffLevel = 2; $Script:wrathBuffTimer = 840; $Script:wrathStackCount = 0 }
            else { $Script:wrathBuffLevel = 1; $Script:wrathBuffTimer = 420 }
        }
    }

    # จัดการ Timers
    if ($Script:immortalTimer -gt 0) { $Script:immortalTimer-- }
    if ($Script:silenceTimer -gt 0) { $Script:silenceTimer-- }
    if ($collisionResult.ApplySilence) { $Script:silenceTimer = 180 }
    if ($collisionResult.ApplySiren) { $Script:sirenTimer = 180 }
    if ($Script:jammerTimer -gt 0) { $Script:jammerTimer-- }
    if ($collisionResult.ApplyJammer) { $Script:jammerTimer = 300 }
    if ($collisionResult.ApplyGreed) { $Script:inventory.Clear() }

    # โล่และสถานะบอส
    if ($Script:defenseHits -gt 400) { $Script:defenseHits = 400 }
    if ($Script:defenseHits -lt 100) { $Script:gluttonyStage = 0 }
    if ($Script:wrathBuffTimer -gt 0) { $Script:wrathBuffTimer--; if($Script:wrathBuffTimer -le 0){ $Script:wrathBuffLevel = 0 } }
    if ($Script:speedTimer -gt 0) { $Script:speedTimer-- }

    # เช็คการตาย (Arena Integrity)
    if ($collisionResult.IsPlayerHit) {
        $Script:lives--
        if ($Script:lives -le 0) { Do-GameOver; return $true }
        
        $Script:player.X = 225; $Script:player.Y = 500
        $isRealPrideActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "RealPride" }).Count -gt 0
        
        if ($isRealPrideActive -or $isLuciferActive -or $collisionResult.IsFatalHit) {
            $Script:defenseHits = 50; $Script:immortalTimer = 180
            Write-Host "ARENA RESURRECTION: KEEP FIGHTING!" -ForegroundColor Yellow
        } else {
            $Script:enemies.Clear(); $Script:enemyBullets.Clear(); $Script:bullets.Clear()
        }
    }
    return $false 
}

# (Handle-PlayerInput และ Get-UIStatus เหมือนเดิม)

# ==========================================
# --- ฟังก์ชันจัดการควบคุมผู้เล่น (ย้ายมาจากหน้าหลัก) ---
# ==========================================
function Handle-PlayerInput {
    # 1. ลดเวลาสถานะ (Timer)
    if ($Script:sirenTimer -gt 0) { $Script:sirenTimer-- }
    if ($Script:speedTimer -gt 0) { $Script:speedTimer-- }

    $moveLeft = ($Script:keysPressed["A"] -or $Script:keysPressed["Left"])
    $moveRight = ($Script:keysPressed["D"] -or $Script:keysPressed["Right"])

    # 2. คำนวณความเร็ว (ปกติ 8, บัฟ 16)
    $currentSpeed = 8
    if ($Script:speedTimer -gt 0) { $currentSpeed = 16 }

    # 3. คำนวณทิศทาง (ปกติ หรือ Siren)
    $direction = 0
    if ($moveLeft) { $direction = -1 }
    if ($moveRight) { $direction = 1 }

    if ($Script:sirenTimer -gt 0) { $direction *= -1 } # สลับทิศถ้าติด Siren

    # 4. สั่งเคลื่อนที่ด้วย Move($step) อย่างเดียว (ห้ามเรียก MoveLeft/Right!)
    if ($direction -ne 0) {
        $Script:player.Move($direction * $currentSpeed)
    }

    # 5. การยิงปืนหลัก (W / Space)
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
                [void]$Script:bullets.Add([Bullet]::new($px + 7, $py))
            }
            $Script:player.ResetCooldown()
        }
    }
    
    # 6. อัปเดต Cooldown (สำคัญมาก! ถ้าบรรทัดนี้ไม่ทำงาน จะยิงไม่ออก)
    $Script:player.Update()
}

# ==========================================
# --- ฟังก์ชันจัดการ UI (ย้ายมาจากหน้าหลัก) ---
# ==========================================
function Get-UIStatus {
    $activeBuffs = @()
    $activeDebuffs = @()

     # --- แก้ไขส่วนของ Wrath UI ---
    if ($Script:wrathBuffLevel -eq 2) {
        # ถ้าเป็นขั้น 2 (เก็บครบ 3) โชว์เวลาถอยหลังสีแดง
        $bSecondsLeft = [math]::Round(($Script:wrathBuffTimer / 60.0), 1)
        $activeBuffs += [PSCustomObject]@{ 
            Icon = "W"; 
            Value = "{0:N1}s" -f $bSecondsLeft; 
            Color = [System.Drawing.Brushes]::Red 
        }
    } else {
        # ถ้ายังไม่ถึงขั้น 2 แต่มี Stack สะสมไว้ ให้โชว์จำนวน Stack สีฟ้าเสมอ
        if ($Script:wrathStackCount -gt 0) {
            $activeBuffs += [PSCustomObject]@{ 
                Icon = "W"; 
                Value = "$($Script:wrathStackCount)/3"; 
                Color =[System.Drawing.Brushes]::DeepSkyBlue 
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

    # Debuff/Buff พิเศษ: Immortal (สีขาว I)
    if ($Script:immortalTimer -gt 0) {
        $iSeconds = [math]::Round(($Script:immortalTimer / 60.0), 1)
        $activeDebuffs += [PSCustomObject]@{ 
            Icon = "I"; 
            Value = "{0:N1}s" -f $iSeconds; 
            Color = [System.Drawing.Brushes]::White 
        }
    }

    return @{ Buffs = $activeBuffs; Debuffs = $activeDebuffs }
}

