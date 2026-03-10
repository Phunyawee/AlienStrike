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



# --- [Optimised] คำนวณความยาก: ลดเพดานเพื่อกันแลค ---
function Get-GameDifficulty ($currentScore) {
    $calculatedLevel = [math]::Floor([math]::Sqrt($currentScore / 750)) + 1
    $lvl = [math]::Min($calculatedLevel, 999)
    
    # ปรับลด SpawnRate: เริ่ม 2 เลเวลละ 0.5 ตันที่ 15 (แค่นี้ก็เต็มจอแล้วครับสำหรับ 60FPS)
    $rate = [math]::Min((2 + ($lvl * 0.5)), 15)
    
    $nextLevelScore = [math]::Pow($lvl, 2) * 750
    return @{ Level = $lvl; SpawnRate = $rate; NextLevelScore = $nextLevelScore }
}

# --- สร้างศัตรูธรรมดา ---
function New-EnemySpawn ($width, $level, $rnd) {
    $ex = $rnd.Next(0, ($width - 40))
    $ey = -40
    
    # โอกาสเกิด Wrath 8%
    if ($rnd.Next(1, 101) -le 8) {
        $sinLevel = [math]::Min(([math]::Floor($level / 200) + 1), 5)
        return [Wrath]::new($ex, $ey, $sinLevel)
    }

    $minSpeed = [math]::Min((2 + [math]::Floor($level / 2)), 15)
    $maxSpeed = [math]::Min(($minSpeed + 5), 20)
    $speed = $rnd.Next($minSpeed, $maxSpeed)
    
    $colorList = @([System.Drawing.Color]::Red, [System.Drawing.Color]::Orange, [System.Drawing.Color]::Purple, [System.Drawing.Color]::Cyan, [System.Drawing.Color]::Lime, [System.Drawing.Color]::Gold)
    $enemyColor = if ($level -ge 999) { [System.Drawing.Color]::DarkRed } else { $colorList[($level - 1) % $colorList.Count] }
    
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

# ==========================================
# --- [Optimised] ฟังก์ชันเช็คการเกิดบอส ---
# ==========================================
function Check-BossSpawns {
    # 1. เช็คสถานะสนามรบ
    $isRealPrideOut = ($Script:enemies | Where-Object { $_.GetType().Name -eq "RealPride" }).Count -gt 0
    $isGluttonyOut = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Gluttony" }).Count -gt 0

    # ถ้าบอสใหญ่อยู่ ห้ามสปอนตัวอื่นเพิ่ม (ยกเว้น RealPride เอง)
    if ($isRealPrideOut) { return }

    # --- 2. [NEW] เงื่อนไข RealPride (Final Boss) ---
    if ($Script:totalGluttonyKills -ge 3) {
        $Script:totalGluttonyKills = 0 
        # Clear เฉพาะลูกกระจ๊อก
        for ($i = $Script:enemies.Count - 1; $i -ge 0; $i--) {
            if ($Script:enemies[$i] -isnot [BaseEnemy]) { $Script:enemies.RemoveAt($i) }
        }
        [void]$Script:enemies.Add([RealPride]::new(210, -150, $Script:player))
        return # เมื่อ RealPride มา ให้หยุดเช็คตัวอื่นในเฟรมนี้
    }

    # --- 3. ระบบ Pride ปกติ (ทุก 100,000 คะแนน) ---
    if ($Script:score -ge $Script:nextPrideScoreTarget) {
        [void]$Script:enemies.Add([Pride]::new(230, -50))
        $Script:nextPrideScoreTarget += 100000 
    }

    # --- 4. ระบบ Greed (ล้างสนามลูกกระจ๊อก) ---
    if ($Script:score -gt 0 -and $Script:score -ge $Script:nextGreedTarget) {
        for ($i = $Script:enemies.Count - 1; $i -ge 0; $i--) {
            if ($Script:enemies[$i] -isnot [BaseEnemy]) { $Script:enemies.RemoveAt($i) }
        }
        [void]$Script:enemies.Add([Greed]::new($Script:rnd.Next(100, 400), $Script:rnd.Next(100, 200), $Script:player))
        $Script:nextGreedTarget += 20000 
    }

    # --- 5. ระบบ Lust (Level Up) ---
    if ($Script:level -gt $Script:currentTrackedLevel) {
        $Script:currentTrackedLevel = $Script:level
        for ($i = 0; $i -lt 5; $i++) {
            $dir = if ($i % 2 -eq 0) { 1 } else { -1 }
            $sx = if ($dir -eq 1) { -50 - ($i*40) } else { 550 + ($i*40) }
            [void]$Script:enemies.Add([Lust]::new($sx, 50 + ($i*20), $dir))
        }
    }

    # --- 6. ระบบ Gluttony Stage ---
    if (-not $isGluttonyOut) {
        $spawnGluttony = $false
        if ($Script:defenseHits -ge 300 -and $Script:gluttonyStage -eq 2) { $Script:gluttonyStage = 3; $spawnGluttony = $true }
        elseif ($Script:defenseHits -ge 200 -and $Script:gluttonyStage -eq 1) { $Script:gluttonyStage = 2; $spawnGluttony = $true }
        elseif ($Script:defenseHits -ge 100 -and $Script:gluttonyStage -eq 0) { $Script:gluttonyStage = 1; $spawnGluttony = $true }
        if ($spawnGluttony) { [void]$Script:enemies.Add([Gluttony]::new(210, -100, $Script:player)) }
    }

    # --- 7. ระบบ Sloth (เมื่อ Pride ตาย) ---
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

    # --- บอสตัวสำคัญ ---
    if ($collisionResult.GluttonyKills -gt 0) {
        Add-To-Inventory "Nuke"
        $Script:totalGluttonyKills += $collisionResult.GluttonyKills # [FIX] บวกค่าเพื่อให้ RealPride เกิด!
        Write-Host "Gluttony Kills: $Script:totalGluttonyKills / 3" -ForegroundColor Magenta
    }

    # --- [NEW] ฆ่า RealPride (รีเซ็ตลูป) ---
    if ($collisionResult.RealPrideKilled) {
        $Script:realPrideDefeatedTotal++
        $Script:totalGluttonyKills = 0
        [void]$Script:enemyBullets.Add([SovereignPulse]::new($Script:player.Y + 5))
        Write-Host ">>> GATEKEEPER DEFEATED ($Script:realPrideDefeatedTotal / 2) <<<" -ForegroundColor Yellow # แก้ตรงนี้!
    }

    # --- เช็คเรียก Lucifer (บอสตัวสุดท้าย) ---
    if ($Script:realPrideDefeatedTotal -ge 2) {
        # Lucifer Spawning Logic (เร็วๆ นี้)
        Write-Host "THE KING OF HELL IS COMING..." -ForegroundColor Red
    }

    
    if ($collisionResult.LustKills -gt 0) {
        for ($i = 0; $i -lt $collisionResult.LustKills; $i++) { 1..5 | ForEach-Object { Add-To-Inventory "Missile" } }
    }

    if ($collisionResult.SlothKills -gt 0) { $Script:speedTimer = 420 }

    if ($collisionResult.GreedKills -gt 0) {
        $Script:defenseHits += (10 * $collisionResult.GreedKills)
    }

    if ($collisionResult.PrideKilled) { $Script:prideKills++ }

    if ($collisionResult.WrathKills -gt 0 -and $Script:wrathBuffLevel -lt 2) {
        for ($k = 0; $k -lt $collisionResult.WrathKills; $k++) {
            $Script:wrathStackCount++
            if ($Script:wrathStackCount -ge 3) {
                $Script:wrathBuffLevel = 2
                $Script:wrathBuffTimer = 840 # 14 วินาที
                $Script:wrathStackCount = 0
            } else {
                $Script:wrathBuffLevel = 1
                $Script:wrathBuffTimer = 420 # 7 วินาที
            }
        }
    }
 # --- [NEW] จัดการเวลา Immortal ---
    if ($Script:immortalTimer -gt 0) { $Script:immortalTimer-- }

    # --- สถานะผิดปกติ ---
    if ($Script:silenceTimer -gt 0) { $Script:silenceTimer-- }
    if ($collisionResult.ApplySilence) { $Script:silenceTimer = 180 }
    if ($collisionResult.ApplySiren) { $Script:sirenTimer = 180 }
    if ($Script:jammerTimer -gt 0) { $Script:jammerTimer-- }
    if ($collisionResult.ApplyJammer) { $Script:jammerTimer = 300 }
    if ($collisionResult.ApplyGreed) { $Script:inventory.Clear() }

    # --- จัดการโล่และบอสเขมือบ ---
    if ($Script:defenseHits -gt 400) { $Script:defenseHits = 400 }
    if ($Script:defenseHits -lt 100) { $Script:gluttonyStage = 0 }

    # --- Timers ---
    if ($Script:wrathBuffTimer -gt 0) { 
        $Script:wrathBuffTimer--
        if ($Script:wrathBuffTimer -le 0) { 
            $Script:wrathBuffLevel = 0
            # ลบการรีเซ็ต Stack ออก เพื่อให้เก็บสะสมข้ามเวลาได้
            # $Script:wrathStackCount = 0 
        }
    }
    if ($Script:speedTimer -gt 0) { $Script:speedTimer-- }

    # ==========================================
    # 6. ตรวจสอบสถานะการตาย (GameOver & Fatal Check)
    # ==========================================
    if ($collisionResult.IsPlayerHit) {
        $Script:lives--
        if ($Script:lives -le 0) { Do-GameOver; return $true }
        else {
            $Script:player.X = 225; $Script:player.Y = 500
            
            if ($collisionResult.IsFatalHit) {
                $Script:defenseHits = 50 
                # --- สั่งให้เป็นอมตะ 3 วินาที (180 เฟรม) ---
                $Script:immortalTimer = 180 
                Write-Host "FATAL RESURRECTION: IMMORTAL FOR 3 SECS!" -ForegroundColor White
            } else {
                $Script:enemies.Clear(); $Script:enemyBullets.Clear(); $Script:bullets.Clear()
            }
        }
    }
    return $false 
}