# src/Managers/LogicModules/StageDirector.ps1
# ==========================================
# 2. PROGRESSION: ผู้กำกับการแสดง (Director)
# ==========================================
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

