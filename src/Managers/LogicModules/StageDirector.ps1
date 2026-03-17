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

        "Chapter2" { Update-ChapterTwoProgression }

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
    if ($Script:gameMode -notin @("Chapter1", "Endless")) { 
        return 
    }

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

    # 1. เช็ค Level Up (Lust Swarm)
    if ($Script:level -gt $Script:currentTrackedLevel) {
        $Script:currentTrackedLevel = $Script:level
        # ปล่อย Lust เฉพาะตอนที่ไม่มีบอสใหญ่
        if (-not $isLuciferActive -and -not $isRealPrideActive) {
            Write-Host ">>> CHAPTER 1: LUST SWARM INBOUND <<<" -ForegroundColor Green
            for ($i = 0; $i -lt 5; $i++) {
                $dir = if ($i % 2 -eq 0) { 1 } else { -1 }
                $sx = if ($dir -eq 1) { -50 - ($i*40) } else { 550 + ($i*40) }
                [void]$Script:enemies.Add([Lust]::new($sx, 50 + ($i*20), $dir))
            }
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

# --- ฟังก์ชันสร้างฝูงบิน Delta (ลำดับ Layer: น้ำเงินหลัง แดงหน้า) ---
function Spawn-DeltaFormation ([float]$centerX, [float]$targetY) {
    # 1. ลูกน้องแถวหลังสุด (น้ำเงิน 2 ลำบน)
    [void]$Script:enemies.Add([Watcher]::new($centerX, -100, $centerX - 45, $targetY - 45, "Minion"))
    [void]$Script:enemies.Add([Watcher]::new($centerX, -100, $centerX + 45, $targetY - 45, "Minion"))

    # 2. ลูกน้องแถวกลาง (น้ำเงิน 2 ลำกลาง)
    [void]$Script:enemies.Add([Watcher]::new($centerX, -100, $centerX - 25, $targetY + 5, "Minion"))
    [void]$Script:enemies.Add([Watcher]::new($centerX, -100, $centerX + 25, $targetY + 5, "Minion"))

    # 3. หัวหน้า (แดง - แอดหน้าสุด)
    [void]$Script:enemies.Add([Watcher]::new($centerX, -100, $centerX, $targetY, "Leader"))
}

$Script:chapterTwoWave = 0
$Script:waveDelayTimer = 0 # ตัวนับเวลาถอยหลังก่อนปล่อยชุดใหม่
$Script:subWaveTriggered = $false

function Update-ChapterTwoProgression {
    $activeEnemies = $Script:enemies | Where-Object { $_.Y -lt 1000 }
    
    if ($activeEnemies.Count -gt 0) { 
        # ลอจิก Sub-Wave ของ Wave 3 (เหมือนเดิม)
        if ($Script:chapterTwoWave -eq 3 -and -not $Script:subWaveTriggered) {
            $orbits = $activeEnemies | Where-Object { $_.Type -eq "Orbit" }
            if ($orbits.Count -le 2) { # ปรับให้เหลือ 2 ลำค่อยเรียกวงใหม่
                $Script:subWaveTriggered = $true
                $cx = 230; $cy = 150
                for ($i = 0; $i -lt 4; $i++) { # ลดเหลือ 4 ลำ
                    $w = [Watcher]::new($cx, $cy, $cx, $cy, "Orbit")
                    $w.Angle = (($i * 90) + 45) * ([math]::PI / 180)
                    $w.OrbitCX = $cx; $w.OrbitCY = $cy
                    [void]$Script:enemies.Add($w)
                }
                [void]$Script:enemies.Add([Watcher]::new(550, 180, 0, 0, "Ace"))
            }
        }
        $Script:waveDelayTimer = 30; return 
    }
    
    if ($Script:waveDelayTimer -gt 0) { $Script:waveDelayTimer--; return }

    $Script:chapterTwoWave++
    $Script:subWaveTriggered = $false
    Write-Host ">>> CHAPTER 2: STARTING WAVE $Script:chapterTwoWave <<<" -ForegroundColor Cyan
    
    switch ($Script:chapterTwoWave) {
        1 { Spawn-DeltaFormation 230 150 }
        2 { 
            for($i=0;$i-lt 4;$i++) {
                [void]$Script:enemies.Add([Watcher]::new(-50, 100, (40 + $i*35), (80 + $i*20), "Minion"))
                [void]$Script:enemies.Add([Watcher]::new(460, 100, (420 - $i*35), (80 + $i*20), "Minion"))
            }
        }
        3 { 
            $cx = 250; $cy = 150
            for ($i = 0; $i -lt 5; $i++) {
                $w = [Watcher]::new($cx, $cy, $cx, $cy, "Orbit")
                $w.Angle = ($i * 72) * ([math]::PI / 180); $w.OrbitCX = $cx; $w.OrbitCY = $cy
                [void]$Script:enemies.Add($w)
            }
            [void]$Script:enemies.Add([Watcher]::new(-100, 120, 0, 0, "Ace"))
        }
        4 { 
            # [เนิฟ Wave 4] ส่งค่า "Passive" ไปให้ลูกน้อง
            Spawn-Pyramid 80 100 0   "Passive"
            Spawn-Pyramid 230 100 30  "Passive" # เพิ่มดีเลย์การยิงให้ห่างกันมากขึ้น
            Spawn-Pyramid 380 100 60  "Passive"
        }
        5 {
            # [NEW] Wave 5: Twin Columns (กำแพงคู่)
            for($i=0;$i-lt 5;$i++) {
                [void]$Script:enemies.Add([Watcher]::new(100, -50, 100, (50 + $i*60), "Minion"))
                [void]$Script:enemies.Add([Watcher]::new(350, -50, 350, (50 + $i*60), "Minion"))
            }
            Write-Host ">>> WAVE 5: THE TWIN COLUMNS <<<" -ForegroundColor Yellow
        }
        6 {
            # [NEW] Wave 6: Ace Squadron (ฝูงบินรบพิเศษ)
            [void]$Script:enemies.Add([Watcher]::new(-100, 100, 0, 0, "Ace"))
            [void]$Script:enemies.Add([Watcher]::new(600, 150, 0, 0, "Ace"))
            [void]$Script:enemies.Add([Watcher]::new(-100, 200, 0, 0, "Ace"))
            Write-Host ">>> WAVE 6: ACE INTERCEPTORS <<<" -ForegroundColor Red
        }
        7 { 
            Write-Host ">>> WAVE 7: LEFT GRID ASSAULT <<<" -ForegroundColor Cyan
            Spawn-GridFormation 50 100 
        }
        8 { 
            Write-Host ">>> WAVE 8: RIGHT GRID ASSAULT <<<" -ForegroundColor Cyan
            Spawn-GridFormation 300 100 
        }
        9 {
            Write-Host ">>> WAVE 9: TWIN GRID REINFORCED <<<" -ForegroundColor Yellow
            Spawn-GridFormation 50 80
            Spawn-GridFormation 300 80
        }
        10 {
            Write-Host ">>> WAVE 10: THE GRAND A-FORMATION (NO ESCAPE) <<<" -ForegroundColor Red
            Spawn-AFormation
        }
        
        default {
            Write-Host ">>> CHAPTER 2 RESTARTING... <<<" -ForegroundColor Yellow
            $Script:chapterTwoWave = 0 
        }
    }
}

# --- ปรับปรุงฟังก์ชัน Spawn-Pyramid ให้รองรับโหมด Passive ---
function Spawn-Pyramid ([float]$centerX, [float]$targetY, [int]$shootOffset = 0, [string]$minionBehavior = "Minion") {
    $leader = [Watcher]::new($centerX, -150, $centerX, $targetY, "Leader")
    $leader.ActionTimer = $shootOffset 
    [void]$Script:enemies.Add($leader)

    # ลูกน้องจะได้รับพฤติกรรมตามที่สั่ง (เช่น Passive คือบินอย่างเดียวไม่ยิง)
    [void]$Script:enemies.Add([Watcher]::new($centerX - 35, -150, $centerX - 40, $targetY + 45, $minionBehavior))
    [void]$Script:enemies.Add([Watcher]::new($centerX, -150, $centerX, $targetY + 45, $minionBehavior))
    [void]$Script:enemies.Add([Watcher]::new($centerX + 35, -150, $centerX + 40, $targetY + 45, $minionBehavior))
}

# --- ฟังก์ชันสร้าง Grid 9 ลำ (สี่เหลี่ยม 3x3) ---
function Spawn-GridFormation ([float]$startX, [float]$targetY) {
    for ($row = 0; $row -lt 3; $row++) {
        for ($col = 0; $col -lt 3; $col++) {
            $tx = $startX + ($col * 50)
            $ty = $targetY + ($row * 50)
            [void]$Script:enemies.Add([Watcher]::new($tx, -100, $tx, $ty, "Minion"))
        }
    }
}

# --- ฟังก์ชันสร้างมหาขบวนบิน A-Star (Wave 10) ---
function Spawn-AFormation {
    $cx = 230.0; $cy = 80.0
    # 1. ยอดพีระมิด (แดง - หัวหน้า)
    [void]$Script:enemies.Add([Watcher]::new($cx, -100, $cx, $cy, "Leader", $true))

    # 2. ขาซ้ายและขวา (น้ำเงิน 8 ลำ)
    for ($i = 1; $i -le 4; $i++) {
        $offX = $i * 40; $offY = $i * 50
        [void]$Script:enemies.Add([Watcher]::new($cx, -100, ($cx - $offX), ($cy + $offY), "Minion", $true))
        [void]$Script:enemies.Add([Watcher]::new($cx, -100, ($cx + $offX), ($cy + $offY), "Minion", $true))
    }

    # 3. คานกลาง (น้ำเงิน 3 ลำ)
    [void]$Script:enemies.Add([Watcher]::new($cx, -100, $cx - 40, $cy + 100, "Minion", $true))
    [void]$Script:enemies.Add([Watcher]::new($cx, -100, $cx, $cy + 100, "Minion", $true))
    [void]$Script:enemies.Add([Watcher]::new($cx, -100, $cx + 40, $cy + 100, "Minion", $true))
}