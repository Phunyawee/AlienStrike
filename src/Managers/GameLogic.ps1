# ==========================================
# 1. FACTORY & INVENTORY: โรงงานผลิตและระบบคลังแสง
# ==========================================

function New-Sin ([string]$name, [float]$x = 210, [float]$y = -150) {
    switch ($name) {
        "Wrath"    { return [Wrath]::new($x, $y, 5) }
        "Envy"     { return [Envy]::new($x, $y, $Script:player) }
        "Pride"    { return [Pride]::new($x, $y) }
        "Lust"     { return [Lust]::new($x, $y, 1) }
        "Sloth"    { return [Sloth]::new($x, $y, $x, 150, 0) }
        "Greed"    { return [Greed]::new($x, $y, $Script:player) }
        "Gluttony" { return [Gluttony]::new($x, $y, $Script:player) }
        "RealPride"{ return [RealPride]::new($x, $y, $Script:player) }
        "Lucifer"  { return [Lucifer]::new($x, $y, $Script:player) }
        default    { return $null }
    }
}

function Add-To-Inventory ($itemType, [int]$amount = 1) {
    for ($k = 0; $k -lt $amount; $k++) {
        $lastIdx = -1
        for ($i = 0; $i -lt $Script:inventory.Count; $i++) {
            if ($Script:inventory[$i] -eq $itemType) { $lastIdx = $i }
        }
        if ($lastIdx -ne -1) { $Script:inventory.Insert($lastIdx + 1, $itemType) }
        else { [void]$Script:inventory.Add($itemType) }
    }
}

# [NEW] ระบบดรอปไอเทม D (Defense) ทุกๆ 15 วินาที เมื่อสู้กับ Lucifer
function Check-ItemDrops {
    $lucifer = $Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" } | Select-Object -First 1
    
    # เงื่อนไข: ต้องมี Lucifer และเลือดต้องต่ำกว่า 9000
    if ($lucifer -and $lucifer.HP -lt 9000) {
        $Script:itemDropTimer++
        if ($Script:itemDropTimer -ge 900) {
            $Script:itemDropTimer = 0
            $rx = $Script:rnd.Next(50, 450)
            if ($null -ne $Script:items) {
                [void]$Script:items.Add([DefenseDrop]::new($rx, -50))
                Write-Host ">>> EMERGENCY DEFENSE DROPPED! <<<" -ForegroundColor Cyan
            }
        }
    } else { $Script:itemDropTimer = 0 }
}

# ==========================================
# 2. PROGRESSION: ผู้กำกับการแสดง (Director)
# ==========================================

function Update-ChapterOneProgression {
    $isLuciferActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" }).Count -gt 0
    $isRealPrideActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "RealPride" }).Count -gt 0
    $isGluttonyActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Gluttony" }).Count -gt 0

    # --- 1. ตรรกะเรียก LUCIFER (เช็คก่อนเสมอ) ---
    if ($Script:realPrideDefeatedTotal -ge 2 -and -not $isLuciferActive) {
        if ($Script:luciferWarningTimer -le 0) {
            Write-Host "!!! WARNING: UNKNOWN ENERGY SIGNATURE DETECTED !!!" -ForegroundColor Red
            $Script:enemies.Clear(); $Script:enemyBullets.Clear(); $Script:bullets.Clear()
            $Script:luciferWarningTimer = 180 
        }
        if ($Script:luciferWarningTimer -gt 0) {
            $Script:luciferWarningTimer--
            if ($Script:luciferWarningTimer -eq 1) {
                [void]$Script:enemies.Add((New-Sin "Lucifer"))
                $Script:realPrideDefeatedTotal = 0 
                Write-Host ">>> LUCIFER HAS ARRIVED <<<" -ForegroundColor Magenta
            }
            return 
        }
    }
    if ($isLuciferActive) { return }

    # --- 2. ตรรกะ RealPride (Gatekeeper) ---
    if ($isRealPrideActive) { 
        $rp = $Script:enemies | Where-Object { $_.GetType().Name -eq "RealPride" } | Select-Object -First 1
        if ($rp) { 
            $rem = 15 - $rp.LaserCount
            $Script:isCataclysmIncoming = ($rem -le 3) # เตือน Cataclysm เมื่อเหลือเลเซอร์ <= 3
        }
        return 
    }

    if ($Script:totalGluttonyKills -ge 3) {
        Write-Host ">>> GATEKEEPER IS SUMMONED! <<<" -ForegroundColor Yellow
        $Script:totalGluttonyKills = 0; $Script:gluttonyStage = 0
        $minions = $Script:enemies | Where-Object { $_ -isnot [BaseEnemy] }
        foreach ($m in $minions) { [void]$Script:enemies.Remove($m) }
        [void]$Script:enemies.Add((New-Sin "RealPride" 210 -150))
        return
    }

    # --- 3. บอสทั่วไปตามคะแนน/เลเวล ---
    if ($Script:score -gt 0 -and $Script:score -ge $Script:nextGreedTarget) {
        $minions = $Script:enemies | Where-Object { $_ -isnot [BaseEnemy] }
        foreach ($m in $minions) { [void]$Script:enemies.Remove($m) }
        [void]$Script:enemies.Add((New-Sin "Greed" ($Script:rnd.Next(100, 400)) ($Script:rnd.Next(100, 200))))
        $Script:nextGreedTarget += 20000 
        Write-Host ">>> GREED DETECTED! <<<" -ForegroundColor Yellow
    }

    if ($Script:score -ge $Script:nextPrideScoreTarget) {
        [void]$Script:enemies.Add((New-Sin "Pride" 230 -50))
        $Script:nextPrideScoreTarget += 100000 
    }

    if ($Script:level -gt $Script:currentTrackedLevel) {
        $Script:currentTrackedLevel = $Script:level
        Write-Host ">>> LEVEL UP: LUST SWARM INCOMING! <<<" -ForegroundColor Green
        for ($i = 0; $i -lt 5; $i++) {
            $dir = if ($i % 2 -eq 0) { 1 } else { -1 }
            $sx = if ($dir -eq 1) { -50 - ($i*40) } else { 550 + ($i*40) }
            [void]$Script:enemies.Add([Lust]::new($sx, 50 + ($i*20), $dir))
        }
    }

    if (-not $isGluttonyActive) {
        $shouldSpawnG = $false
        if ($Script:defenseHits -ge 300 -and $Script:gluttonyStage -eq 2) { $Script:gluttonyStage = 3; $shouldSpawnG = $true }
        elseif ($Script:defenseHits -ge 200 -and $Script:gluttonyStage -eq 1) { $Script:gluttonyStage = 2; $shouldSpawnG = $true }
        elseif ($Script:defenseHits -ge 100 -and $Script:gluttonyStage -eq 0) { $Script:gluttonyStage = 1; $shouldSpawnG = $true }
        if ($shouldSpawnG) { 
            [void]$Script:enemies.Add((New-Sin "Gluttony")) 
            Write-Host ">>> GLUTTONY STAGE $($Script:gluttonyStage) ACTIVE <<<" -ForegroundColor Magenta
        }
    }

    if ($Script:prideKills -ge 1) {
        $Script:prideKills = 0
        [void]$Script:enemies.Add([Sloth]::new(-100, 150, 100, 150, 0))
        [void]$Script:enemies.Add([Sloth]::new(700, 150, 450, 150, 180))
    }
}

function Check-BossSpawns {
    # 1. ตรวจสอบสถานะบอสปัจจุบัน
    $isGluttonyActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Gluttony" }).Count -gt 0
    $isGreedActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Greed" }).Count -gt 0
    $isLuciferActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" }).Count -gt 0
    $isRealPrideActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "RealPride" }).Count -gt 0

    # 2. เลือกโหมดการเล่น
    switch ($Script:gameMode) {
        
        # --- โหมดเนื้อเรื่องปกติ ---
        "Chapter1" { 
            Update-ChapterOneProgression 
        }

        # --- [เพิ่มส่วนนี้!] โหมด Endless: วนลูปนรก ---
        "Endless" {
            # ถ้าปราบ Lucifer ได้แล้ว ให้รีเซ็ตลำดับบอสเพื่อเริ่มรอบใหม่ (แต่ไม่รีเซ็ตคะแนน/เวล)
            if ($Script:isLuciferDead) {
                Write-Host ">>> ENDLESS REBIRTH: RESETTING SIN CYCLE <<<" -ForegroundColor Green
                $Script:isLuciferDead = $false
                $Script:realPrideDefeatedTotal = 0
                $Script:totalGluttonyKills = 0
                $Script:gluttonyStage = 0
                $Script:enemyBullets.Clear() # เคลียร์กระสุนค้างจอ
            }
            # เรียกใช้ Progression เดียวกับ Chapter 1 (ซึ่งตอนนี้ Lust อยู่บนสุดแล้ว)
            Update-ChapterOneProgression 
        }

        # --- กลุ่มโหมดดวล 1v1 BATTLE ---
        "1v1_LUCIFER" {
            if (-not $isLuciferActive) { 
                [void]$Script:enemies.Add((New-Sin "Lucifer" 210 80)) 
                Write-Host ">>> DUEL START: LUCIFER <<<" -ForegroundColor Magenta
            }
        }

        "1v1_REALPRIDE" {
            if (-not $isRealPrideActive) { 
                [void]$Script:enemies.Add((New-Sin "RealPride" 210 80)) 
                Write-Host ">>> DUEL START: REAL PRIDE <<<" -ForegroundColor Yellow
            }
        }

        "1v1_GLUTTONY" {
            if (-not $isGluttonyActive) { 
                [void]$Script:enemies.Add((New-Sin "Gluttony" 210 80)) 
                Write-Host ">>> DUEL START: GLUTTONY <<<" -ForegroundColor Magenta
            }
        }

        "1v1_GREED" {
            if (-not $isGreedActive) { 
                [void]$Script:enemies.Add((New-Sin "Greed" 210 150)) 
                Write-Host ">>> DUEL START: GREED <<<" -ForegroundColor Yellow
            }
        }
    }
}
# ==========================================
# 3. CORE LOGIC: ระบบการชนและประมวลผล
# ==========================================

function Handle-PostCollision ($collisionResult) {
    if ($collisionResult.ScoreAdded -gt 0) { $Script:score += $collisionResult.ScoreAdded }
    $isLuciferActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" }).Count -gt 0

    if ($collisionResult.GluttonyKills -gt 0) { 
        Add-To-Inventory "Nuke" 5
        $Script:totalGluttonyKills += $collisionResult.GluttonyKills
        Write-Host ">>> GLUTTONY DEFEATED ($Script:totalGluttonyKills / 3) <<<" -ForegroundColor Magenta
    }

    if ($collisionResult.RealPrideKilled) { 
        $Script:realPrideDefeatedTotal++; $Script:totalGluttonyKills = 0
        [void]$Script:enemyBullets.Add([SovereignPulse]::new($Script:player.Y + 5))
        Write-Host ">>> GATEKEEPER DEFEATED ($Script:realPrideDefeatedTotal / 2) <<<" -ForegroundColor Yellow
    }

    if ($collisionResult.LuciferKilled) {
        $Script:victoryTimer = 180; $Script:isLuciferDead = $true
        Write-Host ">>> LUCIFER HAS BEEN BANISHED <<<" -ForegroundColor Green
        return $true 
    }

    # บัฟ/ไอเทม
    if ($collisionResult.LustKills -gt 0) { Add-To-Inventory "Missile" (5 * $collisionResult.LustKills) }
    if ($collisionResult.SlothKills -gt 0) { $Script:speedTimer = 420; Write-Host ">>> SPEED BOOST ACTIVATED <<<" -ForegroundColor Cyan }
    if ($collisionResult.GreedKills -gt 0) { $Script:defenseHits += (10 * $collisionResult.GreedKills); Write-Host ">>> SHIELD REINFORCED <<<" -ForegroundColor Cyan }
    if ($collisionResult.PrideKilled) { $Script:prideKills++ }

    # [NEW] รางวัลจาก Wrath ในด่าน Lucifer
    if ($collisionResult.WrathKills -gt 0 -and $isLuciferActive) {
        Add-To-Inventory "Laser" 5; Add-To-Inventory "Missile" 5
        Write-Host ">>> ARSENAL REPLENISHED! <<<" -ForegroundColor Green
    }

    if ($collisionResult.WrathKills -gt 0 -and $Script:wrathBuffLevel -lt 2) {
        for ($k = 0; $k -lt $collisionResult.WrathKills; $k++) {
            $Script:wrathStackCount++; if ($Script:wrathStackCount -ge 3) { $Script:wrathBuffLevel = 2; $Script:wrathBuffTimer = 840; $Script:wrathStackCount = 0 }
            else { $Script:wrathBuffLevel = 1; $Script:wrathBuffTimer = 420 }
        }
    }

    # Timers
    if ($Script:immortalTimer -gt 0) { $Script:immortalTimer-- }
    if ($Script:silenceTimer -gt 0) { $Script:silenceTimer-- }
    if ($collisionResult.ApplySilence) { $Script:silenceTimer = 180 }
    if ($collisionResult.ApplySiren) { $Script:sirenTimer = 180 }
    if ($Script:jammerTimer -gt 0) { $Script:jammerTimer-- }
    if ($collisionResult.ApplyJammer) { $Script:jammerTimer = 300 }
    if ($collisionResult.ApplyGreed) { $Script:inventory.Clear(); Write-Host ">>> INVENTORY WIPED! <<<" -ForegroundColor Red }
    
    if ($Script:defenseHits -gt 400) { $Script:defenseHits = 400 }
    if ($Script:defenseHits -lt 100) { $Script:gluttonyStage = 0 }
    if ($Script:wrathBuffTimer -gt 0) { $Script:wrathBuffTimer--; if($Script:wrathBuffTimer -le 0){ $Script:wrathBuffLevel = 0 } }
    if ($Script:speedTimer -gt 0) { $Script:speedTimer-- }

    # Resurrection Logic
    if ($collisionResult.IsPlayerHit) {
        $Script:lives--; if ($Script:lives -le 0) { Do-GameOver; return $true }
        $Script:player.X = 225; $Script:player.Y = 500
        $isRP = ($Script:enemies | Where-Object { $_.GetType().Name -eq "RealPride" }).Count -gt 0
        if ($isRP -or $isLuciferActive -or $collisionResult.IsFatalHit) {
            $Script:defenseHits = 50; $Script:immortalTimer = 180
            Write-Host ">>> ARENA RESURRECTION <<<" -ForegroundColor Yellow
        } else {
            $Script:enemies.Clear(); $Script:enemyBullets.Clear(); $Script:bullets.Clear(); $Script:items.Clear()
        }
    }
    return $false 
}


function Get-GameDifficulty ($currentScore) {
    $calculatedLevel = [math]::Floor([math]::Sqrt($currentScore / 750)) + 1
    $lvl = [math]::Min($calculatedLevel, 999)
    $rate = [math]::Min((2 + ($lvl * 0.5)), 15) 
    return @{ Level = $lvl; SpawnRate = $rate; NextLevelScore = ([math]::Pow($lvl, 2) * 750) }
}

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

function Handle-PostCollision ($collisionResult) {
    if ($collisionResult.ScoreAdded -gt 0) { $Script:score += $collisionResult.ScoreAdded }
    $isLuciferActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" }).Count -gt 0

    if ($collisionResult.GluttonyKills -gt 0) { Add-To-Inventory "Nuke" 5; $Script:totalGluttonyKills += $collisionResult.GluttonyKills }
    if ($collisionResult.RealPrideKilled) { 
        $Script:realPrideDefeatedTotal++; $Script:totalGluttonyKills = 0
        [void]$Script:enemyBullets.Add([SovereignPulse]::new($Script:player.Y + 5))
    }
    if ($collisionResult.LuciferKilled) {
        $Script:victoryTimer = 180; $Script:isLuciferDead = $true
        return $true 
    }

    if ($collisionResult.LustKills -gt 0) { for($i=0;$i-lt $collisionResult.LustKills;$i++){ Add-To-Inventory "Missile" 5} }
    if ($collisionResult.SlothKills -gt 0) { $Script:speedTimer = 420 }
    if ($collisionResult.GreedKills -gt 0) { $Script:defenseHits += (10 * $collisionResult.GreedKills) }
    if ($collisionResult.PrideKilled) { $Script:prideKills++ }
    if ($collisionResult.WrathKills -gt 0 -and $isLuciferActive) { 
        for($i=0;$i-lt $collisionResult.WrathKills;$i++){ 
            Add-To-Inventory "Laser" 5; Add-To-Inventory "Missile" 5 
        } 
    }

    if ($collisionResult.WrathKills -gt 0 -and $Script:wrathBuffLevel -lt 2) {
        for ($k = 0; $k -lt $collisionResult.WrathKills; $k++) {
            $Script:wrathStackCount++; if ($Script:wrathStackCount -ge 3) { $Script:wrathBuffLevel = 2; $Script:wrathBuffTimer = 840; $Script:wrathStackCount = 0 }
            else { $Script:wrathBuffLevel = 1; $Script:wrathBuffTimer = 420 }
        }
    }

    if ($Script:immortalTimer -gt 0) { $Script:immortalTimer-- }
    if ($Script:silenceTimer -gt 0) { $Script:silenceTimer-- }
    if ($collisionResult.ApplySilence) { $Script:silenceTimer = 180 }
    if ($collisionResult.ApplySiren) { $Script:sirenTimer = 180 }
    if ($Script:jammerTimer -gt 0) { $Script:jammerTimer-- }
    if ($collisionResult.ApplyJammer) { $Script:jammerTimer = 300 }
    if ($collisionResult.ApplyGreed) { $Script:inventory.Clear() }
    
    if ($Script:defenseHits -gt 400) { $Script:defenseHits = 400 }
    if ($Script:defenseHits -lt 100) { $Script:gluttonyStage = 0 }
    if ($Script:wrathBuffTimer -gt 0) { $Script:wrathBuffTimer--; if($Script:wrathBuffTimer -le 0){ $Script:wrathBuffLevel = 0 } }
    if ($Script:speedTimer -gt 0) { $Script:speedTimer-- }

    if ($collisionResult.IsPlayerHit) {
        $Script:lives--; if ($Script:lives -le 0) { Do-GameOver; return $true }
        $Script:player.X = 225; $Script:player.Y = 500
        $isRP = ($Script:enemies | Where-Object { $_.GetType().Name -eq "RealPride" }).Count -gt 0
        if ($isRP -or $isLuciferActive -or $collisionResult.IsFatalHit) {
            $Script:defenseHits = 50; $Script:immortalTimer = 180
        } else {
            $Script:enemies.Clear(); $Script:enemyBullets.Clear(); $Script:bullets.Clear(); $Script:items.Clear()
        }
    }
    return $false 
}

# ==========================================
# 4. UTILS: เครื่องมือเสริม
# ==========================================

function Check-ItemDrops {
    $lucifer = $Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" } | Select-Object -First 1
    if ($lucifer -and $lucifer.HP -lt 9000) {
        $Script:itemDropTimer++
        if ($Script:itemDropTimer -ge 900) {
            $Script:itemDropTimer = 0
            if ($null -ne $Script:items) { [void]$Script:items.Add([DefenseDrop]::new($Script:rnd.Next(50, 450), -50)) }
        }
    } else { $Script:itemDropTimer = 0 }
}

function Handle-PlayerInput {
    if ($Script:sirenTimer -gt 0) { $Script:sirenTimer-- }
    if ($Script:speedTimer -gt 0) { $Script:speedTimer-- }
    $moveL = ($Script:keysPressed["A"] -or $Script:keysPressed["Left"])
    $moveR = ($Script:keysPressed["D"] -or $Script:keysPressed["Right"])
    $speed = if ($Script:speedTimer -gt 0) { 16 } else { 8 }
    $dir = 0
    if ($moveL) { $dir = -1 } elseif ($moveR) { $dir = 1 }
    if ($Script:sirenTimer -gt 0) { $dir *= -1 }
    if ($dir -ne 0) { $Script:player.Move($dir * $speed) }
    if ($Script:keysPressed["W"] -or $Script:keysPressed["Space"] -or $Script:keysPressed["Up"]) {
        if ($Script:silenceTimer -le 0 -and $Script:player.CanShoot()) {
            $px = $Script:player.X; $py = $Script:player.Y
            if ($Script:wrathBuffLevel -eq 2) {
                [void]$Script:bullets.Add([Bullet]::new($px+4,$py,0)); [void]$Script:bullets.Add([Bullet]::new($px+20,$py,0))   
                [void]$Script:bullets.Add([Bullet]::new($px-4,$py,-4)); [void]$Script:bullets.Add([Bullet]::new($px+28,$py,4))   
            } elseif ($Script:wrathBuffLevel -eq 1) {
                [void]$Script:bullets.Add([Bullet]::new($px+4,$py,0)); [void]$Script:bullets.Add([Bullet]::new($px+20,$py,0))
            } else { [void]$Script:bullets.Add([Bullet]::new($px+7,$py)) }
            $Script:player.ResetCooldown()
        }
    }
    $Script:player.Update()
}

function Get-UIStatus {
    $buffs = @(); $debuffs = @()
    
    # 1. Wrath Buff (W)
    if ($Script:wrathBuffLevel -eq 2) { 
        $buffs += [PSCustomObject]@{ Icon="W"; Value="{0:N1}s" -f ($Script:wrathBuffTimer/60.0); Color=[System.Drawing.Brushes]::Red } 
    } elseif ($Script:wrathStackCount -gt 0) { 
        $buffs += [PSCustomObject]@{ Icon="W"; Value="$($Script:wrathStackCount)/3"; Color=[System.Drawing.Brushes]::DeepSkyBlue } 
    }
    
    # --- [ลบก้อนที่เช็ค $Script:inventory[0] ตรงนี้ออกให้หมด] ---

    # 2. Debuffs (Z, S, J, I)
    if ($Script:silenceTimer -gt 0) { $debuffs += [PSCustomObject]@{ Icon="Z"; Value="{0:N1}s" -f ($Script:silenceTimer/60.0); Color=[System.Drawing.Brushes]::Magenta } }
    if ($Script:sirenTimer -gt 0) { $debuffs += [PSCustomObject]@{ Icon="S"; Value="{0:N1}s" -f ($Script:sirenTimer/60.0); Color=[System.Drawing.Brushes]::DeepPink } }
    if ($Script:jammerTimer -gt 0) { $debuffs += [PSCustomObject]@{ Icon="J"; Value="{0:N1}s" -f ($Script:jammerTimer/60.0); Color=[System.Drawing.Brushes]::Yellow } }
    if ($Script:speedTimer -gt 0) { $buffs += [PSCustomObject]@{ Icon="S"; Value="{0:N1}s" -f ($Script:speedTimer/60.0); Color=[System.Drawing.Brushes]::SkyBlue } }
    if ($Script:defenseHits -gt 0) { $buffs += [PSCustomObject]@{ Icon="D"; Value="x$Script:defenseHits"; Color=[System.Drawing.Brushes]::Gold } }
    if ($Script:immortalTimer -gt 0) { $debuffs += [PSCustomObject]@{ Icon="I"; Value="{0:N1}s" -f ($Script:immortalTimer/60.0); Color=[System.Drawing.Brushes]::White } }

    return @{ Buffs = $buffs; Debuffs = $debuffs }
}