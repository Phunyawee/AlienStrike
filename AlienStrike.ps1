#AlienStrike.ps1
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- 1. Smart Auto-Loader (v5.0.2: Nephilim Dependency Fix) ---

$LoadOrder = @(
    "src\Entities\GameObject.ps1",
    "src\Entities\Projectiles\Bullet.ps1",
    "src\Entities\Projectiles\EnemyBullet.ps1",
    "src\Entities\Projectiles\EnemyMissile.ps1", # โหลดมิสไซล์ก่อน
    "src\Entities\Projectiles\*.ps1",            # โหลดกระสุนลูกทุกชนิด (รวม NephilimBlade)
    "src\Entities\Enemies\BaseEnemy.ps1",
    "src\Entities\Player.ps1",
    "src\Entities\*.ps1",
    "src\Entities\Enemies\Sins\LuciferPart.ps1",
    "src\Entities\Enemies\Sins\Watcher.ps1",     # [จุดสำคัญ] ต้องโหลด Watcher ก่อนบอสตัวอื่น!
    "src\Entities\Enemies\Sins\Wrath.ps1",
    "src\Entities\Enemies\Sins\*.ps1",           # ค่อยโหลดบอสที่เหลือ (เช่น Nephilim)
    "src\Managers\*.ps1",
    "src\Managers\LogicModules\*.ps1",
    "src\Managers\CollisionModules\*.ps1",
    "src\Managers\RenderModules\*.ps1"
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

function Reset-Session {
    # 1. ล้างสถานะ Pause และหน้าจอ (แก้ปัญหา Exit แล้วยัง Pause)
    $Script:isPaused = $false
    $Script:gameStarted = $false
    $Script:showCredits = $false
    $Script:isLuciferDead = $false
    $Script:victoryTimer = 0
    $Script:chapterTwoWave = 0
    $Script:waveDelayTimer = 0

    # 2. ล้างลิสต์วัตถุทั้งหมด
    $Script:enemies.Clear()
    $Script:enemyBullets.Clear()
    $Script:bullets.Clear()
    $Script:items.Clear()

    # 3. รีเซ็ตอาวุธเริ่มต้น (แก้ปัญหาอาวุธไม่กลับมา)
    $Script:inventory.Clear()
    Add-To-Inventory "Missile" 5
    Add-To-Inventory "Laser" 1
    Add-To-Inventory "Homing" 5

    # 4. รีเซ็ตตัวแปรนับยอดบอสและการสปอน (แก้ปัญหา Lust ไม่เกิด)
    $Script:score = 0
    $Script:level = 1
    $Script:targetScore = 750
    $Script:currentTrackedLevel = 1 # <--- สำคัญมากเพื่อให้ Lust รู้ว่าเลเวลอัปแล้ว
    $Script:realPrideDefeatedTotal = 0
    $Script:totalGluttonyKills = 0
    $Script:gluttonyStage = 0
    $Script:prideKills = 0
    $Script:itemDropTimer = 0
    
    # 5. รีเซ็ตสถานะผู้เล่น
    $Script:lives = 3
    $Script:defenseHits = 0
    $Script:immortalTimer = 0
    $Script:wrathStackCount = 0
    $Script:wrathBuffLevel = 0
    $Script:silenceTimer = 0
    $Script:sirenTimer = 0
    $Script:jammerTimer = 0
    $Script:speedTimer = 0

    Write-Host ">>> SESSION CLEANED & ARSENAL REFILLED <<<" -ForegroundColor Gray
}
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
    Add-To-Inventory "Homing" 5

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
$Script:shakeOffset = New-Object System.Drawing.Point(0, 0)
$Script:gameStarted = $false
$Script:menuState = "MAIN"
$Script:menuIndex = 0
$Script:mainMenuItems = @("STORY MODE", "BATTLE MODE", "SIMULATION", "LEADERBOARD", "EXIT")
$Script:simItems = @("WATCHER", "WRATH", "ENVY", "LUST", "GREED", "SLOTH", "PRIDE", "REAL PRIDE", "GLUTTONY", "NEPHILIM", "LUCIFER", "BACK")
$Script:selectedSimTarget = "" # เก็บชื่อตัวที่จะเสก
$Script:storyItems = @("CHAPTER 1: THE 7 SINS", "CHAPTER 2: THE FALLEN ANGEL", "COMING SOON...")
$Script:chapterTwoWave = 0 # ตัวนับระลอกของ Chapter 2
$Script:battleItems = @("LUCIFER", "REAL PRIDE", "GLUTTONY", "GREED", "BACK") # รายชื่อบอส

$Script:bullets = [System.Collections.ArrayList]::new()
$Script:enemies = [System.Collections.ArrayList]::new()

$Script:rnd = New-Object System.Random
$Script:enemyBullets = [System.Collections.ArrayList]::new()

$Script:isPaused = $false
$Script:pauseIndex = 0
$Script:pauseItems = @("RESUME", "EXIT TO MENU")


$Script:inventory = [System.Collections.ArrayList]::new()
# ตอนเริ่มเกม แจกให้ก่อนเลย 5 อัน
Add-To-Inventory "Missile" 5
Add-To-Inventory "Laser" 1 
Add-To-Inventory "Homing" 5

$Script:score = 0
$Script:targetScore = 750 # <--- เพิ่มบรรทัดนี้ (ค่าเริ่มต้นของ Level 1)
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


# --- 4. Input Handling (v4.2.1: Fix Enter Key & Output) ---
$form.KeyPreview = $true 
$form.Add_KeyDown({
    $key = $_.KeyCode.ToString()
    $Script:keysPressed[$key] = $true
    
    # [Debug] เปิดบรรทัดนี้ถ้าอยากรู้ว่าปุ่มที่กดชื่ออะไรใน Console
    # Write-Host "Key Pressed: $key" -ForegroundColor Gray

    # ==========================================
    # CASE A: หน้าเครดิต
    # ==========================================
    if ($Script:showCredits) {
        if ($key -eq "Return" -or $key -eq "Enter") {
            $Script:showCredits = $false
            $Script:enemies.Clear(); $Script:enemyBullets.Clear(); $Script:bullets.Clear()
            $Script:realPrideDefeatedTotal = 0; $Script:totalGluttonyKills = 0
            Do-GameOver
        }
        return
    }

    # ==========================================
    # CASE B: หน้าเมนู (ปุ่มเลือกโหมด)
    # ==========================================
    if (-not $Script:gameStarted -and -not $Script:showLeaderboard) {
         $currentMenu = switch ($Script:menuState) {
            "MAIN"    { $Script:mainMenuItems }
            "STORY"   { $Script:storyItems }
            "BATTLE"  { $Script:battleItems }
            "SIM"     { $Script:simItems } # <--- เพิ่มหน้าใหม่
        }
        
        if ($key -eq "Up" -or $key -eq "W") {
            $Script:menuIndex--
            if ($Script:menuIndex -lt 0) { $Script:menuIndex = $currentMenu.Count - 1 }
            [System.Media.SystemSounds]::Asterisk.Play()
            $form.Invalidate()
        }
        if ($key -eq "Down" -or $key -eq "S") {
            $Script:menuIndex++
            if ($Script:menuIndex -ge $currentMenu.Count) { $Script:menuIndex = 0 }
            [System.Media.SystemSounds]::Asterisk.Play()
            $form.Invalidate()
        }

        # --- ลอจิกการกด Enter / Return เพื่อเลือกเมนู ---
        if ($key -eq "Return" -or $key -eq "Enter") {
            $selection = $currentMenu[$Script:menuIndex]
            
            # --- 1. หน้าเมนูหลัก (MAIN) ---
            if ($Script:menuState -eq "MAIN") {
                if ($selection -eq "STORY MODE") { 
                    $Script:menuState = "STORY"; $Script:menuIndex = 0 
                }
                elseif ($selection -eq "BATTLE MODE") { 
                    $Script:menuState = "BATTLE"; $Script:menuIndex = 0 
                }
                elseif ($selection -eq "SIMULATION") { # <--- เพิ่มทางเข้า SIM
                    $Script:menuState = "SIM"; $Script:menuIndex = 0 
                }
                elseif ($selection -eq "ENDLESS MODE") { 
                    Reset-Session
                    $Script:gameMode = "Endless"; $Script:gameStarted = $true; $timer.Start() 
                }
                elseif ($selection -eq "LEADERBOARD") { $Script:showLeaderboard = $true }
                elseif ($selection -eq "EXIT") { $form.Close() }
            }
            
            # --- 2. หน้าเลือก Chapter (STORY) ---
            elseif ($Script:menuState -eq "STORY") {
                if ($selection -eq "BACK") { $Script:menuState = "MAIN"; $Script:menuIndex = 0 }
                elseif ($selection -match "CHAPTER 1") { 
                    Reset-Session; $Script:gameMode = "Chapter1"; $Script:gameStarted = $true; $timer.Start() 
                }
                elseif ($selection -match "CHAPTER 2") { 
                    Reset-Session; $Script:gameMode = "Chapter2"; $Script:gameStarted = $true; $timer.Start() 
                }
            }
            
            # --- 3. หน้าเลือกบอส (BATTLE) ---
            elseif ($Script:menuState -eq "BATTLE") {
                if ($selection -eq "BACK") { $Script:menuState = "MAIN"; $Script:menuIndex = 0 }
                else {
                    Reset-Session
                    $cleanName = $selection.Replace(" ", "")
                    $Script:gameMode = "1v1_$cleanName"
                    $Script:gameStarted = $true; $timer.Start()
                }
            }

            # --- 4. [NEW] หน้าห้องทดสอบ (SIMULATION) ---
            elseif ($Script:menuState -eq "SIM") {
                if ($selection -eq "BACK") { $Script:menuState = "MAIN"; $Script:menuIndex = 0 }
                else {
                    # บันทึกชื่อตัวที่จะเทส แล้วเริ่มโหมด Simulation
                    $Script:selectedSimTarget = $selection
                    $Script:gameMode = "Simulation"
                    Reset-Session
                    $Script:gameStarted = $true
                    $timer.Start()
                    Write-Host ">>> SIMULATION START: $selection <<<" -ForegroundColor Cyan
                }
            }

            $form.Invalidate()
            return
        }

        if ($key -eq "Escape" -and $Script:menuState -ne "MAIN") {
            $Script:menuState = "MAIN"; $Script:menuIndex = 0; $form.Invalidate()
        }
        return
    }

    # ==========================================
    # CASE C: หน้า Leaderboard
    # ==========================================
    if ($Script:showLeaderboard) {
        if ($key -eq "Return" -or $key -eq "Enter" -or $key -eq "Escape") {
            $Script:showLeaderboard = $false
            $Script:gameStarted = $false
            $form.Invalidate()
        }
        return
    }

    # ==========================================
    # CASE D: ในเกม (Gameplay)
    # ==========================================
    if ($Script:gameStarted) {
        # --- [NEW] ระบบ Pause (ดักก่อนปุ่มอื่น) ---
        if ($key -eq "Escape") {
            $Script:isPaused = -not $Script:isPaused # สลับสถานะ หยุด/เล่น
            $Script:pauseIndex = 0
            return
        }
        # --- [NEW] สูตรโกง: กดปุ่ม F2 เพื่อเสก Nuke 100 ลูก ---
        if ($key -eq "F1") {
            Add-To-Inventory "Missile" 100
            Write-Host ">>> CHEAT ACTIVATED: 100 Missile ADDED! <<<" -ForegroundColor Red
            [System.Media.SystemSounds]::Hand.Play()
        }
        if ($key -eq "F2") {
            Add-To-Inventory "Nuke" 100
            Write-Host ">>> CHEAT ACTIVATED: 100 NUKES ADDED! <<<" -ForegroundColor Red
            [System.Media.SystemSounds]::Hand.Play()
        }

        # ถ้าเกมหยุดอยู่ ให้ใช้ปุ่มเลื่อนเมนูแทนปุ่มยิง
        if ($Script:isPaused) {
            if ($key -eq "Up" -or $key -eq "W") {
                $Script:pauseIndex--
                if ($Script:pauseIndex -lt 0) { $Script:pauseIndex = $Script:pauseItems.Count - 1 }
            }
            if ($key -eq "Down" -or $key -eq "S") {
                $Script:pauseIndex++
                if ($Script:pauseIndex -ge $Script:pauseItems.Count) { $Script:pauseIndex = 0 }
            }
            if ($key -eq "Return" -or $key -eq "Enter") {
                $selection = $Script:pauseItems[$Script:pauseIndex]
                
                if ($selection -eq "RESUME") { 
                    $Script:isPaused = $false 
                }
                elseif ($selection -eq "EXIT TO MENU") {
                    $Script:isPaused = $false
                    $Script:gameStarted = $false
                    $timer.Stop() # หยุดเฟรมเกม

                    # --- [เช็คกฎการถามคะแนนก่อนออก] ---
                    # ถ้าเป็นโหมด Endless หรือโหมด Battle (1v1) ให้ถามชื่อเซฟคะแนนก่อนออก
                    if ($Script:gameMode -eq "Endless" -or $Script:gameMode -match "1v1_") {
                        Write-Host ">>> EXITING ENDLESS/BATTLE: RECORDING PROGRESS... <<<" -ForegroundColor Cyan
                        Do-GameOver # เรียกหน้าต่างกรอกชื่อและพาไป Leaderboard
                    } 
                    else {
                        # ถ้าเป็นโหมด Story (Chapter1) ให้ล้างค่าแล้วกลับหน้าเมนูเงียบๆ
                        Reset-Session
                        $Script:menuState = "MAIN"
                        Write-Host ">>> STORY MODE EXITED. SESSION RESET. <<<" -ForegroundColor Gray
                    }
                }
            }
            $form.Invalidate(); return
        }




        # สลับอาวุธ (Q)
        if ($key -eq "Q") {
            if ($Script:inventory.Count -gt 1) {
                $firstType = $Script:inventory[0]; $nextIdx = -1
                for ($i = 0; $i -lt $Script:inventory.Count; $i++) {
                    if ($Script:inventory[$i] -ne $firstType) { $nextIdx = $i; break }
                }
                if ($nextIdx -ne -1) {
                    for ($j = 0; $j -lt $nextIdx; $j++) {
                        $item = $Script:inventory[0]; $Script:inventory.RemoveAt(0); [void]$Script:inventory.Add($item)
                    }
                    [System.Media.SystemSounds]::Asterisk.Play()
                }
            }
        }

        # ใช้ไอเทม (E)
    if ($key -eq "E" -and $Script:jammerTimer -le 0 -and $Script:inventory.Count -gt 0) {
        $activeItem = $Script:inventory[0]
        $fired = $false # ตั้งต้นว่ายังไม่ได้ยิง

        if ($activeItem -eq "Missile") { 
            [void]$Script:bullets.Add([Missile]::new($Script:player.X + 5, $Script:player.Y)) 
            $fired = $true
        }
        elseif ($activeItem -eq "Laser") {
            # เช็คไม่ให้ยิงเลเซอร์ซ้อน
            if (($Script:bullets | Where-Object { $_.GetType().Name -eq "PlayerLaser" }).Count -eq 0) {
                [void]$Script:bullets.Add([PlayerLaser]::new($Script:player))
                $fired = $true
            }
        }
        elseif ($activeItem -eq "Nuke") { 
            [void]$Script:bullets.Add([Nuke]::new($Script:player.X, $Script:player.Y)) 
            $fired = $true
        }
        elseif ($activeItem -eq "HolyBomb") { 
            [void]$Script:bullets.Add([HolyBomb]::new($Script:player.X + 5, $Script:player.Y)) 
            $fired = $true
        }
        elseif ($activeItem -eq "Homing") { # <--- ชื่อในกระเป๋า (String)
            # สั่งสร้างวัตถุจากคลาส HomingMissile (ชื่อ Class จริง)
            [void]$Script:bullets.Add([HomingMissile]::new($Script:player.X + 5, $Script:player.Y))
            $fired = $true
        }

        # --- [จุดสำคัญ] สั่งลบของและเล่นเสียง "ครั้งเดียว" เมื่อมีการยิงเกิดขึ้นจริงเท่านั้น ---
        if ($fired) {
            $Script:inventory.RemoveAt(0)
            [System.Media.SystemSounds]::Hand.Play()
        }
    }

        # เมนูหยุดเกม (Escape)
        if ($key -eq "Escape") {
            $timer.Stop()
            if ([System.Windows.Forms.MessageBox]::Show("Quit to Main Menu?", "Quit", 4, 32) -eq "Yes") {
                $Script:gameStarted = $false; $Script:menuState = "MAIN"
                $Script:enemies.Clear(); $Script:enemyBullets.Clear(); $Script:bullets.Clear()
            } else { $timer.Start() }
        }
    }
})
$form.Add_KeyUp({
    $Script:keysPressed[$_.KeyCode.ToString()] = $false
})

# --- 5. Game Loop ---
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 16 # ~60 FPS

$timer.Add_Tick({
     # 1. กรณีเกมหยุด (Pause) -> วาดอย่างเดียว ห้ามทำอะไรต่อ
    if ($Script:isPaused) {
        $form.Invalidate() 
        return 
    }

    # 2. กรณีปราบ Lucifer ได้แล้ว (Victory State)
    if ($Script:isLuciferDead) {
        if ($Script:victoryTimer -gt 0) {
            $Script:victoryTimer--
            
            # เมื่อป้ายประกาศชัยชนะโชว์จนครบเวลา (3 วินาที)
            if ($Script:victoryTimer -le 0) { 
                if ($Script:gameMode -eq "Endless") {
                    # --- [แก้ไขตรงนี้] สำหรับโหมด Endless: รีเซ็ตเพื่อเล่นต่อทันที ---
                    $Script:isLuciferDead = $false
                    $Script:realPrideDefeatedTotal = 0
                    $Script:totalGluttonyKills = 0
                    $Script:gluttonyStage = 0
                    # ล้างกระสุนศัตรูที่ค้างจออยู่ให้สะอาด
                    $Script:enemyBullets.Clear()
                    $Script:enemies.Clear()
                    
                    Write-Host ">>> ENDLESS REBIRTH: BEGINNING NEXT CYCLE <<<" -ForegroundColor Green
                } else {
                    # สำหรับโหมด Story: เปิดหน้าเครดิตตามปกติ
                    $Script:showCredits = $true 
                    $Script:creditY = 600.0
                }
            }
        }
        $form.Invalidate() 
        return # หยุดประมวลผลฟิสิกส์ระหว่างโชว์ป้าย Victory
    }

    if (-not $Script:gameStarted -or $Script:gameOver -or $Script:isPaused) { 
        if ($Script:isPaused) { $form.Invalidate() }
        return 
    }

    # --- A. Update Difficulty ---
    $diff = Get-GameDifficulty $Script:score
    $Script:level = $diff.Level
    $Script:spawnRate = $diff.SpawnRate
    $Script:targetScore = $diff.NextLevelScore

    # --- เช็คการเกิดของบอสพิเศษ (Lust / Pride) ---
    Check-BossSpawns

    # ในโหมด Sim ไม่ต้องดรอปกล่อง Defense (ถ้าคุณอยากทดสอบแบบเพียวๆ)
    if ($Script:gameMode -ne "Simulation") {
        Check-ItemDrops
    }

    # --- ควบคุมผู้เล่น ---
    Handle-PlayerInput

    # ==========================================
    # --- B. Spawn Enemies (ฉบับแก้ไข: สะอาดและแม่นยำ) ---
    # ==========================================

    # 1. รวบรวมสถานะสนามรบ (เช็คครั้งเดียวใช้ได้ทั้งบล็อก)
    $isDuelMode = $Script:gameMode -match "1v1_"
    $isChapter2 = $Script:gameMode -eq "Chapter2"
    $isLuciferActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" }).Count -gt 0
    $isRealPrideActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "RealPride" }).Count -gt 0
    $isGluttonyOut = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Gluttony" }).Count -gt 0
    $hasGreed = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Greed" }).Count -gt 0
    $isSimMode = $Script:gameMode -eq "Simulation"
    # 2. กฎการสปอนศัตรูทั่วไป: 
    # ห้ามเกิดถ้า: (เป็นโหมดดวล) หรือ (มีบอสใหญ่อยู่) หรือ (ศัตรูเต็มจอ 20 ตัว)
    $canSpawnMinions = (-not $isDuelMode -and -not $isChapter2 -and -not $isSimMode -and -not $isLuciferActive -and -not $isRealPrideActive)

    if ($canSpawnMinions -and $Script:enemies.Count -lt 20) {
        if ($Script:rnd.Next(0, 100) -lt $Script:spawnRate) {
            [void]$Script:enemies.Add((New-EnemySpawn 500 $Script:level $Script:rnd))
        }
    }

    # --- อัปเดตตำแหน่งไอเทมที่ดรอป (Defense D) ---
    for ($i = $Script:items.Count - 1; $i -ge 0; $i--) {
        $it = $Script:items[$i]
        $it.Update()
        # ถ้าตกจอให้ลบทิ้ง
        if ($it.Y -gt 650) { $Script:items.RemoveAt($i) }
    }

    # --- C. Update Bullets ---
    for ($i = $Script:bullets.Count - 1; $i -ge 0; $i--) {
        $b = $Script:bullets[$i]
        if ($null -eq $b) { $Script:bullets.RemoveAt($i); continue }
        $b.Update()
        
        # ลบกระสุนเมื่อ: ตกจอ หรือ ถูกดีดทิ้งจากการชน (Y = -2000)
        if ($b.Y -lt -700 -or $b.Y -gt 1000 -or $b.Y -eq -2000) { 
            $Script:bullets.RemoveAt($i) 
        }
    }

    # --- D. Update Entities Movement (เคลื่อนที่ศัตรู & กระสุนศัตรู) ---
    $pendingEnemies = [System.Collections.ArrayList]::new()

    # ใช้ .ToArray() เพื่อป้องกัน Error "Collection was modified" 100%
    foreach ($e in $Script:enemies.ToArray()) { 
        # เช็คว่าตัวตนของศัตรูยังอยู่จริงไหม
        if ($null -eq $e -or $e.PSObject -eq $null) { continue }

        try {
            # 1. อัปเดตการเคลื่อนที่ (ต้องมั่นใจว่ามี Player เสมอ)
            if ($e -is [BaseEnemy]) {
                if ($null -ne $Script:player) { 
                    $e.UpdateWithPlayer($Script:player) 
                } else { $e.Update() }
            } else {
                $e.Update()
            }
            
            # 2. เช็คการยิง/เสก (ดักจับค่า Null แฝง)
            $shotResult = $e.TryShoot($Script:level)
            
            if ($null -ne $shotResult) { 
                # จัดการผลลัพธ์ให้เป็นลิสต์เสมอเพื่อความปลอดภัย
                $itemsToAdd = if ($shotResult -is [System.Collections.IEnumerable] -and $shotResult -isnot [string]) { $shotResult } else { ,$shotResult }
                
                foreach ($item in $itemsToAdd) {
                    if ($null -eq $item) { continue }
                    if ($item -is [BaseEnemy]) { [void]$pendingEnemies.Add($item) }
                    else { [void]$Script:enemyBullets.Add($item) }
                }
            }
        } catch {
            # ถ้าตัวไหนพัง ให้ข้ามไปเลย ไม่ต้องหยุดเกม
            continue
        }
    }

    # 3. เทรวมศัตรูใหม่
    if ($pendingEnemies.Count -gt 0) {
        $Script:enemies.AddRange($pendingEnemies)
    }

    # 4. อัปเดตกระสุนศัตรู (เช็ค Null)
    foreach ($eb in $Script:enemyBullets.ToArray()) { 
        if ($null -ne $eb -and $eb.PSObject -ne $null) { $eb.Update() }
    }
    # --- E. Handle Collisions ---
    #ry {
        $collisionResult = Invoke-GameCollisions $Script:player $Script:bullets $Script:enemies $Script:enemyBullets $form.ClientSize.Height $Script:items
    # } catch {
    #     Write-Warning "Collision skipped for 1 frame due to sync issue."
    # }
     # --- [แก้ไข] ระบบสั่นจอภายใน (Internal Shake) ---
    if ($collisionResult.ShakeIntensity -gt 0) {
        $intensity = $collisionResult.ShakeIntensity
        $Script:shakeOffset.X = $Script:rnd.Next(-$intensity, $intensity)
        $Script:shakeOffset.Y = $Script:rnd.Next(-$intensity, $intensity)
    } else {
        $Script:shakeOffset.X = 0; $Script:shakeOffset.Y = 0
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

        # ใน AlienStrike.ps1 ส่วน Paint
        if (-not $Script:gameStarted -and -not $Script:showLeaderboard) {
            Draw-Menu $g $form.Width $form.Height
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