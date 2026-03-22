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

    if ($Script:gameMode -eq "Simulation") {
        $activeEnemies = $Script:enemies | Where-Object { $_.Y -lt 1000 }
        if ($activeEnemies.Count -eq 0) {
            # เสกใหม่กลางจอ
            [void]$Script:enemies.Add((New-Sin $Script:selectedSimTarget 230 100))
        }
        return # จบการทำงานของ Director ทันที ห้ามไปเช็ค Chapter อื่น!
    }

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
        "Simulation" {
            if ($Script:enemies.Count -eq 0) {
                Write-Host ">>> RE-SPAWNING SIM TARGET: $Script:selectedSimTarget <<<" -ForegroundColor Gray
                [void]$Script:enemies.Add((New-Sin $Script:selectedSimTarget 210 100))
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

$Script:chapterTwoWave = 0
$Script:waveDelayTimer = 0 # ตัวนับเวลาถอยหลังก่อนปล่อยชุดใหม่
$Script:subWaveTriggered = $false

function Update-ChapterTwoProgression {
    $activeEnemies = $Script:enemies | Where-Object { 
        $_.Y -lt 1000 -and 
        $_.X -gt -500 -and $_.X -lt 1200 -and 
        ($null -eq $_.HP -or $_.HP -gt 0) -and
        $_.GetType().Name -ne "Explode" # (เผื่อคุณมีคลาส Effect ระเบิดค้างอยู่)
    }
    
    # 1. เช็คว่าศัตรูยังอยู่ หรือติดช่วงหน่วงเวลาไหม
    if ($activeEnemies.Count -gt 0) { $Script:waveDelayTimer = 30; return }
    if ($Script:waveDelayTimer -gt 0) { $Script:waveDelayTimer--; return }

    $Script:chapterTwoWave++
    $Script:subWaveTriggered = $false 

    # ==========================================
    # ลอจิกการเลือก Wave (1-11 คือคงที่, 12-17 คือสุ่ม)
    # ==========================================
    $currentAction = $Script:chapterTwoWave

    # ถ้าอยู่ในช่วงสุ่ม (Wave 12 ถึง 17)
    if ($Script:chapterTwoWave -ge 12 -and $Script:chapterTwoWave -le 17) {
        # ถ้ายังไม่ได้สุ่ม ให้สุ่มเก็บไว้ 6 อันจาก 10 แบบแรก
        if ($Script:chapterTwoRandomPool.Count -eq 0) {
            for ($i=0; $i -lt 6; $i++) { $Script:chapterTwoRandomPool += $Script:rnd.Next(1, 11) }
            Write-Host ">>> CHAPTER 2: RANDOM ASSAULT PREPARED <<<" -ForegroundColor Gray
        }
        # ดึงเลข Wave จาก Pool มาใช้ (เช่น รอบที่ 12 ดึง index 0)
        $currentAction = $Script:chapterTwoRandomPool[$Script:chapterTwoWave - 12]
        Write-Host ">>> CHAPTER 2: RANDOM WAVE ($($Script:chapterTwoWave - 11)/6) - TYPE $currentAction <<<" -ForegroundColor Magenta
    }

    # --- เริ่มปล่อยตัวละครตามลำดับ $currentAction ---
    switch ($currentAction) {
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
                $w = [Watcher]::new($cx, $cy, $cx, $cy, "Orbit"); $w.Angle = ($i * 72) * ([math]::PI / 180); $w.OrbitCX = $cx; $w.OrbitCY = $centerY
                [void]$Script:enemies.Add($w)
            }
            [void]$Script:enemies.Add([Watcher]::new(-100, 120, 0, 0, "Ace"))
        }
        4 { Spawn-Pyramid 80 100 0 "Passive"; Spawn-Pyramid 230 100 30 "Passive"; Spawn-Pyramid 380 100 60 "Passive" }
        5 {
            for($i=0;$i-lt 5;$i++) {
                [void]$Script:enemies.Add([Watcher]::new(100, -50, 100, (50 + $i*60), "Minion"))
                [void]$Script:enemies.Add([Watcher]::new(350, -50, 350, (50 + $i*60), "Minion"))
            }
        }
        6 { 
            [void]$Script:enemies.Add([Watcher]::new(-100, 100, 0, 0, "Ace"))
            [void]$Script:enemies.Add([Watcher]::new(600, 150, 0, 0, "Ace"))
            [void]$Script:enemies.Add([Watcher]::new(-100, 200, 0, 0, "Ace"))
        }
        7 { Spawn-GridFormation 50 100 }
        8 { Spawn-GridFormation 300 100 }
        9 { Spawn-GridFormation 50 80; Spawn-GridFormation 300 80 }
        10 { Spawn-AFormation }
        
        # --- บอสตามพล็อตเรื่อง ---
        11 { 
            # Nephilim (ฟิกซ์ตำแหน่งที่ 11 เสมอ)
            Write-Host ">>> WARNING: NEPHILIM CLASS DETECTED <<<" -ForegroundColor Red
            [void]$Script:enemies.Add((New-Sin "Nephilim" 170 -100))
        }

         # --- [เพิ่ม] ระลอกที่ 18: เปิดตัวบอสใหญ่ Azazel ---
        18 {
            Write-Host "!!! WARNING: AZAZEL - THE WAR BRINGER HAS ARRIVED !!!" -ForegroundColor Red
            # ล้างลูกกระจ๊อกออกให้หมดก่อนบอสมา
            $minions = $Script:enemies | Where-Object { $_ -isnot [BaseEnemy] }
            foreach ($m in $minions) { [void]$Script:enemies.Remove($m) }
            
            # เสก Azazel (พิกัด X=150 เพื่อให้ฐานกว้าง 200 อยู่กลางจอ 500 พอดี)
            [void]$Script:enemies.Add((New-Sin "Azazel" 150 -150))
        }

        default {
            # ถ้าเล่นจนจบ Azazel (Wave 19+) ให้รีเซ็ตหรือขึ้น Chapter 3
            if ($Script:chapterTwoWave -gt 18) {
                Write-Host ">>> CHAPTER 2 SCRIPT COMPLETED! <<<" -ForegroundColor Gold
                $Script:chapterTwoWave = 0
                $Script:chapterTwoRandomPool = @()
            }
        }
    }
}
