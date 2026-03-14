#AlienStrike.ps1
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- 1. Smart Auto-Loader (v4.1.2: Strict Dependency Loading) ---

# กำหนดลำดับการโหลดตาม "ความต้องการ" ของแต่ละ Class
$LoadOrder = @(
    "src\Entities\GameObject.ps1",           # 1. รากฐานสูงสุด
    "src\Entities\Projectiles\Bullet.ps1",   # 2. กระสุนแม่
    "src\Entities\Projectiles\EnemyBullet.ps1",
    "src\Entities\Projectiles\*.ps1",       # 3. กระสุนลูกทุกชนิด (ต้องโหลดก่อนบอสที่ยิงมัน)
    "src\Entities\Enemies\BaseEnemy.ps1",    # 4. ศัตรูแม่
    "src\Entities\Player.ps1",               # 5. ผู้เล่น
    "src\Entities\*.ps1",                    # 6. คลาสเสริม (DefenseDrop)
    "src\Entities\Enemies\Sins\LuciferPart.ps1", # 7. ชิ้นส่วนบอส (ต้องโหลดก่อนตัวบอสใหญ่)
    "src\Entities\Enemies\Sins\Wrath.ps1",       # 8. บอสที่ถูกบอสอื่นเรียกใช้
    "src\Entities\Enemies\Sins\*.ps1",           # 9. บอสที่เหลือทั้งหมด
    "src\Managers\*.ps1"                         # 10. ตัวจัดการ (โหลดหลังสุด)
)

$LoadedFiles = New-Object System.Collections.Generic.HashSet[string]

foreach ($pattern in $LoadOrder) {
    $targetPath = Join-Path $PSScriptRoot $pattern
    
    # ดึงไฟล์ตาม Pattern และเรียงลำดับให้แน่นอน
    Get-ChildItem -Path $targetPath -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
        if (-not $LoadedFiles.Contains($_.FullName)) {
            try {
                . $_.FullName
                [void]$LoadedFiles.Add($_.FullName)
            } catch {
                Write-Warning "Failed to load: $($_.Name). Dependency might be missing."
            }
        }
    }
}

# ตรวจสอบความพร้อม (Critical Check)
if (!(Get-Command "Get-GameDifficulty" -ErrorAction SilentlyContinue)) {
    Write-Error "Critical Managers failed to load. Check folder structure!"
    exit
}

# --- Helper Functions: Score System ---
$scoreFile = "$PSScriptRoot\scores.json"

function Do-GameOver {
    $timer.Stop() # หยุดเกม
    
    # เซฟคะแนน
    $name = Show-NameInputBox $Script:score
    Save-Score $name $Script:score $Script:level

    # รีเซ็ตสถานะเพื่อไปหน้า Leaderboard
    $Script:gameOver = $false
    $Script:gameStarted = $false
    $Script:showLeaderboard = $true
    $Script:lives = 3
    $Script:wrathKills = 0     # สำหรับนับจำนวนโกรธ
    $Script:silenceTimer = 0   # ตัวนับเวลาติดใบ้
    $Script:wrathBuffTimer = 0  # ตัวจับเวลา Buff 7 วินาที (420 เฟรม)
    $Script:wrathBuffLevel = 0  # 0=ปกติ, 1=ยิง 2 นัด(Blue), 2=ยิง 4 นัด(Red)
    $Script:sirenTimer = 0   # ตัวนับเวลาติดสถานะ Siren (เดินสลับทิศ)
    $Script:wrathStackCount = 0  # ตัวนับ Stack (0-5)
    $Script:currentTrackedLevel = 1 # ใส่ไว้ตอนเริ่มเกม / ในฟังก์ชัน Do-GameOver
    $Script:jammerTimer = 0    # ตัวนับเวลาติดสถานะ Jammer (ห้ามใช้ Item)
    $Script:prideKills = 0     # ตัวนับจำนวนการฆ่า Pride (สะสมเพื่อเรียก Sloth)
    $Script:defenseHits = 0
    $Script:totalGluttonyKills = 0  # นับสะสมเพื่อเรียก RealPride
    $Script:immortalTimer = 0  # ตัวนับเวลาสถานะอมตะ (I)
    $Script:nextGreedTarget = 20000

    $Script:speedTimer = 0  # ตัวนับเวลา Buff Speed
    $Script:realPrideDefeatedTotal = 0 # นับยอดคิลสะสมเพื่อจบเกม
    $Script:luciferWarningTimer = 0  # เพิ่มบรรทัดนี้ใน Do-GameOver

    $Script:items.Clear()
    $Script:itemDropTimer = 0
    $Script:isCataclysmIncoming = $false

    $Script:isLuciferDead = $false
    $Script:victoryTimer = 0
    $Script:showCredits = $false
    $Script:creditY = 600.0


    # --- RESET GAME OBJECTS ---
    # สร้าง Player ใหม่ที่จุดเริ่มต้น
    $Script:player = [Player]::new(225, 500)
    
    # ล้างศัตรูและกระสุนให้เกลี้ยง
    if ($null -ne $Script:bullets) { $Script:bullets.Clear() }
    if ($null -ne $Script:enemies) { $Script:enemies.Clear() }
    
    # ล้างกระสุนศัตรู (สร้างใหม่เลยกันเหนียว)
    $Script:enemyBullets = [System.Collections.ArrayList]::new()

    $Script:inventory = [System.Collections.ArrayList]::new()
   
    # ทดสอบ: แจกมิสไซล์ 5 อัน และ เลเซอร์ 1 อัน
    Add-To-Inventory "Missile" 5
    Add-To-Inventory "Laser" 1
    
    # รีเซ็ตค่าคะแนนและเลเวล
    $Script:score = 0
    $Script:nextPrideScoreTarget = 5000 # เป้าหมายคะแนนแรกที่ Pride จะเกิด
    $Script:level = 1

    # สั่งวาดหน้าจอใหม่ (จะไปโผล่ที่หน้า Leaderboard)
    $form.Invalidate()
}


# --- 2. Setup Window ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Alien Strike: OOP Engine"
$form.ClientSize = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = "Black"
$form.MaximizeBox = $false
$form.FormBorderStyle = "Fixed3D"

# Enable DoubleBuffered to prevent flickering
$prop = [System.Windows.Forms.Form].GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"NonPublic,Instance")
$prop.SetValue($form, $true, $null)

# --- 3. Game Variables ---
Write-Host "Loading Game Objects..."
$Script:gameMode = "Chapter1" # หรือเปลี่ยนเป็น "1v1_Lucifer" เพื่อเทสบอสใหญ่ทันที
$Script:player = [Player]::new(225, 500)

if ($null -eq $Script:player) {
    [System.Windows.Forms.MessageBox]::Show("Failed to load player! Check Player.ps1", "Error")
    exit
}

$Script:bullets = [System.Collections.ArrayList]::new()
$Script:enemies = [System.Collections.ArrayList]::new()

$Script:rnd = New-Object System.Random
$Script:enemyBullets = [System.Collections.ArrayList]::new()

$Script:inventory = [System.Collections.ArrayList]::new()
# ตอนเริ่มเกม แจกให้ก่อนเลย 5 อัน
Add-To-Inventory "Missile" 5
Add-To-Inventory "Laser" 1

$Script:score = 0
$Script:nextPrideScoreTarget = 5000 # เป้าหมายคะแนนแรกที่ Pride จะเกิด
$Script:nextGreedTarget = 20000
$Script:level = 1
$Script:lives = 3   
$Script:wrathKills = 0     # สำหรับนับจำนวนโกรธ
$Script:silenceTimer = 0   # ตัวนับเวลาติดใบ้
$Script:wrathBuffTimer = 0  # ตัวจับเวลา Buff 7 วินาที (420 เฟรม)
$Script:wrathBuffLevel = 0  # 0=ปกติ, 1=ยิง 2 นัด(Blue), 2=ยิง 4 นัด(Red)
$Script:sirenTimer = 0   # ตัวนับเวลาติดสถานะ Siren (เดินสลับทิศ)
$Script:wrathStackCount = 0  # ตัวนับ Stack (0-5)
$Script:currentTrackedLevel = 1 # ใส่ไว้ตอนเริ่มเกม / ในฟังก์ชัน Do-GameOver
$Script:jammerTimer = 0    # ตัวนับเวลาติดสถานะ Jammer (ห้ามใช้ Item)
$Script:prideKills = 0     # ตัวนับจำนวนการฆ่า Pride (สะสมเพื่อเรียก Sloth)
$Script:totalGluttonyKills = 0  # นับสะสมเพื่อเรียก RealPride
$Script:spawnRate = 3  
$Script:gameStarted = $false
$Script:gameOver = $false
$Script:showLeaderboard = $false
$Script:speedTimer = 0  # ตัวนับเวลา Buff Speed
$Script:defenseHits = 0
$Script:immortalTimer = 0  # ตัวนับเวลาสถานะอมตะ (I)
$Script:realPrideDefeatedTotal = 0 # นับยอดคิลสะสมเพื่อจบเกม
$Script:keysPressed = @{}

$Script:items = [System.Collections.ArrayList]::new()
$Script:itemDropTimer = 0
$Script:isCataclysmIncoming = $false # สำหรับป้ายเตือน Cataclysm
$Script:planets = [System.Collections.ArrayList]::new() # สำหรับพื้นหลังอวกาศ
$Script:isLuciferDead = $false
$Script:victoryTimer = 0
$Script:showCredits = $false # สำหรับ End Credit
$Script:creditY = 600.0

# --- 4. Input Handling ---
$form.KeyPreview = $true 
$form.Add_KeyDown({
    $Script:keysPressed[$_.KeyCode.ToString()] = $true
    
     # --- [เพิ่มตรงนี้] ระบบสลับอาวุธแบบ Instant ---
    if ($_.KeyCode.ToString() -eq "Q" -and $Script:gameStarted) {
        if ($Script:inventory.Count -gt 1) {
            $firstType = $Script:inventory[0]
            
            # หาว่าไอเทมประเภทอื่นตัวแรกอยู่ที่ไหน
            $nextTypeIdx = -1
            for ($i = 0; $i -lt $Script:inventory.Count; $i++) {
                if ($Script:inventory[$i] -ne $firstType) {
                    $nextTypeIdx = $i
                    break
                }
            }

            # ถ้ามีอาวุธประเภทอื่น ให้ย้าย "ทั้งก้อน" ของอาวุธปัจจุบันไปไว้ข้างหลัง
            if ($nextTypeIdx -ne -1) {
                for ($j = 0; $j -lt $nextTypeIdx; $j++) {
                    $item = $Script:inventory[0]
                    $Script:inventory.RemoveAt(0)
                    [void]$Script:inventory.Add($item)
                }
                # เสียง Beep สั้นๆ ให้รู้ว่าสลับอาวุธแล้ว
                [System.Media.SystemSounds]::Asterisk.Play()
            }
        }
    }
     # --- [NEW] ระบบใช้ไอเทม E (ย้ายมานี่เพื่อกันบั๊กรัว) ---
    if ($_.KeyCode.ToString() -eq "E" -and $Script:jammerTimer -le 0) {
        if ($Script:inventory.Count -gt 0) {
            $activeItem = $Script:inventory[0]
            
            if ($activeItem -eq "Missile") {
                [void]$Script:bullets.Add([Missile]::new($Script:player.X + 5, $Script:player.Y))
                $Script:inventory.RemoveAt(0)
            }
            elseif ($activeItem -eq "Laser") {
                # เช็คไม่ให้ยิงเลเซอร์ซ้อน
                $hasActiveLaser = ($Script:bullets | Where-Object { $_.GetType().Name -eq "PlayerLaser" }).Count -gt 0
                if (-not $hasActiveLaser) {
                    [void]$Script:bullets.Add([PlayerLaser]::new($Script:player))
                    $Script:inventory.RemoveAt(0)
                }
            }
            # [เพิ่มตรงนี้] ถ้าไอเทมที่ถือคือ Nuke
            elseif ($activeItem -eq "Nuke") {
                [void]$Script:bullets.Add([Nuke]::new($Script:player.X, $Script:player.Y))
                $Script:inventory.RemoveAt(0)
                # เสียงระเบิดเตือน
                [System.Media.SystemSounds]::Hand.Play()
            }
            elseif ($activeItem -eq "HolyBomb") {
                [void]$Script:bullets.Add([HolyBomb]::new($Script:player.X + 5, $Script:player.Y))
                $Script:inventory.RemoveAt(0)
            }
        }
    }

    # Press Esc to pause/exit
    if ($_.KeyCode -eq "Escape") { 
        $timer.Stop()
        $ans = [System.Windows.Forms.MessageBox]::Show("Do you want to exit?", "Quit Game", 4, 32)
        if ($ans -eq "Yes") { $form.Close() }
        else { $timer.Start() }
    }

    if ($_.KeyCode -eq "F1") {
        $Script:gameMode = "1v1_Lucifer"
        $Script:enemies.Clear()
        Write-Host ">>> MODE CHANGED: 1v1 LUCIFER <<<" -ForegroundColor Red
    }

     # กด Enter
    if ($_.KeyCode -eq "Enter") {
        if ($Script:showCredits) {
            $Script:showCredits = $false
            # ล้างสนามรบทั้งหมดก่อนไปหน้ากรอกชื่อ (เพื่อให้เริ่มลูปใหม่ได้สะอาด)
            $Script:enemies.Clear()
            $Script:enemyBullets.Clear()
            $Script:bullets.Clear()
            $Script:realPrideDefeatedTotal = 0
            $Script:totalGluttonyKills = 0
            
            Do-GameOver # ไปหน้ากรอกชื่อและ Leaderboard
            return
        }
        # กรณี 1: ถ้าดู Leaderboard อยู่ -> ให้กลับไปหน้า Start Screen
        elseif ($Script:showLeaderboard) {
            $Script:showLeaderboard = $false
            $Script:gameStarted = $false
            $Script:gameOver = $false
            $form.Invalidate() # บังคับวาดหน้าจอใหม่ทันที
        } 
        # กรณี 2: ถ้าอยู่ที่หน้า Start Screen -> ให้เริ่มเกม
        elseif (-not $Script:gameStarted) { 
            $Script:gameStarted = $true 
            $timer.Start()  # <--- [สำคัญมาก] ต้องสั่ง Start ไม่งั้นเกมไม่เดิน!
        }
    }


    # กด L ที่หน้า Start Screen เพื่อดู Leaderboard
    if ($_.KeyCode -eq "L" -and -not $Script:gameStarted -and -not $Script:showLeaderboard) {
        $Script:showLeaderboard = $true
        $form.Invalidate()
    }



})
$form.Add_KeyUp({
    $Script:keysPressed[$_.KeyCode.ToString()] = $false
})

# --- 5. Game Loop ---
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 16 # ~60 FPS

$timer.Add_Tick({
    # ถ้าปราบ Lucifer ได้แล้ว
    if ($Script:isLuciferDead) {
        if ($Script:victoryTimer -gt 0) {
            $Script:victoryTimer--
            if ($Script:victoryTimer -le 0) { 
                $Script:showCredits = $true # จบ 3 วิแล้วค่อยเปิดเครดิต
            }
        }
        $form.Invalidate() # สั่งวาดหน้าจอต่อไปเรื่อยๆ เพื่อให้เครดิตเลื่อน
        return # ออกจาก Loop ตรงนี้เลย (ศัตรูและกระสุนจะหยุดนิ่งค้างสนาม)
    }

    if (-not $Script:gameStarted -or $Script:gameOver) { return }

    # --- A. Update Difficulty ---
    $diff = Get-GameDifficulty $Script:score
    $Script:level = $diff.Level
    $Script:spawnRate = $diff.SpawnRate
    $Script:targetScore = $diff.NextLevelScore

    # --- เช็คการเกิดของบอสพิเศษ (Lust / Pride) ---
    Check-BossSpawns

    Check-ItemDrops

    # --- ควบคุมผู้เล่น ---
    Handle-PlayerInput

    # --- B. Spawn Enemies (ศัตรูธรรมดา) ---
    $isGluttonyOut = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Gluttony" }).Count -gt 0
    $hasGreed = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Greed" }).Count -gt 0

    $isLuciferActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" }).Count -gt 0
    # เพิ่ม -and -not $isLuciferActive
    if (-not $isGluttonyOut -and -not $hasGreed -and -not $isLuciferActive -and $Script:enemies.Count -lt 20) {
        if ($Script:rnd.Next(0, 100) -lt $Script:spawnRate) {
            [void]$Script:enemies.Add((New-EnemySpawn 500 $Script:level $Script:rnd))
        }
    }

    # ถ้ามี Gluttony หรือ Greed อยู่ในสนาม ลูกกระจ๊อกจะไม่เกิด
    if (-not $isGluttonyOut -and -not $hasGreed -and $Script:enemies.Count -lt 20) {
        if ($Script:rnd.Next(0, 100) -lt $Script:spawnRate) {
            [void]$Script:enemies.Add((New-EnemySpawn 500 $Script:level $Script:rnd))
        }
    }

     # --- [เพิ่ม] อัปเดตตำแหน่งไอเทมที่ดรอป ---
    for ($i = $Script:items.Count - 1; $i -ge 0; $i--) {
        $it = $Script:items[$i]
        $it.Update()
        if ($it.Y -gt 650) { $Script:items.RemoveAt($i) }
    }


    # --- C. Update Bullets ---
    for ($i = $Script:bullets.Count - 1; $i -ge 0; $i--) {
        $b = $Script:bullets[$i]
        $b.Update()
        
        # แก้ตรงนี้: ถ้าเป็นเลเซอร์ ห้ามลบด้วยเงื่อนไขขอบบน (-20)
        # หรือปรับตัวเลขให้ลึกขึ้นเป็น -700 เพื่อรองรับความยาวเลเซอร์
        if ($b.Y -lt -700 -or $b.Y -gt 1000) { 
            $Script:bullets.RemoveAt($i) 
        }
    }

    # --- D. Update Entities Movement (เคลื่อนที่ศัตรู & กระสุนศัตรู) ---
    foreach ($e in $Script:enemies) { 
        
        # [แก้ไขตรงนี้] แยกประเภทศัตรูก่อนอัปเดตการเดิน
        if ($e -is [BaseEnemy]) {
            # ถ้าเป็นกลุ่ม 7 บาป (มีระบบมองเห็น Player)
            $e.UpdateWithPlayer($Script:player) 
        } else {
            # ถ้าเป็นศัตรูธรรมดา [Enemy]
            $e.Update() 
        }
        
        # ส่วนการยิงเหมือนเดิม
        $shotResult = $e.TryShoot($Script:level)
        
        if ($null -ne $shotResult) { 
            if ($shotResult -is [System.Collections.IEnumerable]) {
                foreach ($b in $shotResult) {[void]$Script:enemyBullets.Add($b)}
            } else {
                [void]$Script:enemyBullets.Add($shotResult)
            }
        }
    }

    foreach ($eb in $Script:enemyBullets) { $eb.Update() }

    # --- E. Handle Collisions ---
    $collisionResult = Invoke-GameCollisions $Script:player $Script:bullets $Script:enemies $Script:enemyBullets $form.ClientSize.Height $Script:items

    # --- [NEW] ระบบสั่นจอ (Screen Shake) ---
    if ($collisionResult.ShakeIntensity -gt 0) {
        $intensity = $collisionResult.ShakeIntensity
        # ดีดตำแหน่งหน้าต่างสุ่มตามความแรง
        $form.Left += $Script:rnd.Next(-$intensity, $intensity)
        $form.Top += $Script:rnd.Next(-$intensity, $intensity)
    } else {
        # ถ้าไม่มีการสั่น ให้พยายามจัดหน้าต่างกลับเข้าที่กึ่งกลาง (ถ้าต้องการ)
        # หรือปล่อยไว้อย่างนั้นก็ได้ครับ
    }
    # --- F. จัดการสถานะหลังการชน ---
    # ถ้าฟังก์ชันคืนค่า $true แปลว่าเลือดหมด ให้หยุดทำ Loop นี้ทันที (เหมือนคำสั่ง return เดิมของคุณ)
    $isDead = Handle-PostCollision $collisionResult
    if ($isDead) { return }

    $form.Invalidate()
})

# --- 6. Render/Paint ---
$form.Add_Paint({
    try {
        $g = $_.Graphics
        $g.SmoothingMode = "AntiAlias"
        $g.TextRenderingHint = "AntiAlias"
        $g.Clear([System.Drawing.Color]::Black)

        # --- [เพิ่ม] วาดพื้นหลังอวกาศ (Layer ล่างสุด) ---
        Draw-Background $g $form.Width $form.Height $Script:level

        if ($Script:showCredits) {
            Draw-Credits $g $form.Width $form.Height
            $form.Invalidate() # บังคับให้วาดซ้ำเรื่อยๆ เพื่อให้ตัวหนังสือเลื่อน (Scrolling)
            return
        }

        if ($Script:showLeaderboard) {
            Draw-Leaderboard $g $form.Width $form.Height
            return
        }

        if (-not $Script:gameStarted) {
            Draw-StartScreen $g $form.Width $form.Height
            return
        }

        # --- [เพิ่ม] วาดไอเทม D ที่กำลังร่วงลงมา ---
        foreach ($it in $Script:items) { $it.Draw($g) }

        # --- [เพิ่ม] ป้ายเตือน Cataclysm Incoming (RealPride) ---
        if ($Script:isCataclysmIncoming) {
            $warnFont = New-Object System.Drawing.Font("Impact", 20)
            if (([DateTime]::Now.Millisecond % 500) -lt 250) { # กะพริบ
                $g.DrawString("!!! CATACLYSM INCOMING !!!", $warnFont, [System.Drawing.Brushes]::OrangeRed, 130, 150)
                # วาดกรอบสีแดงกะพริบรอบสนามรบ
                $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Red, 5), 5, 5, 490, 590)
            }
        }

    

        # --- เรียกใช้ฟังก์ชันดึงค่า UI แทนโค้ดยาวๆ ---
        $uiStatus = Get-UIStatus

        # --- CASE 4: GAMEPLAY ---
        # เพิ่ม $Script:inventory ต่อท้ายเข้าไป
        Draw-Gameplay $g $Script:player $Script:bullets $Script:enemies $Script:enemyBullets $Script:score $Script:level $Script:lives $Script:targetScore $uiStatus.Buffs $uiStatus.Debuffs $Script:inventory
    } catch {
        Write-Host "Paint Error: $_"
    }
})

$form.Add_Shown({ $form.Activate(); $form.Focus() })

# --- 7. Start Game ---
$timer.Start()
Write-Host "Starting Game Loop..."
[void]$form.ShowDialog()