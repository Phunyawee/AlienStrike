#AlienStrike.ps1
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- 1. Load Classes ---
. "$PSScriptRoot\src\Entities\GameObject.ps1"
. "$PSScriptRoot\src\Entities\Player.ps1"
. "$PSScriptRoot\src\Entities\Projectiles\Bullet.ps1"
. "$PSScriptRoot\src\Entities\Projectiles\EnemyBullet.ps1" 
. "$PSScriptRoot\src\Entities\Enemy.ps1"

# --- 1.0 Load New Enemy Types (ต้องเพิ่มตรงนี้ครับ!) ---
. "$PSScriptRoot\src\Entities\Enemies\BaseEnemy.ps1"
. "$PSScriptRoot\src\Entities\Enemies\Sins\Wrath.ps1"
. "$PSScriptRoot\src\Entities\Projectiles\SilenceBullet.ps1" 
. "$PSScriptRoot\src\Entities\Enemies\Sins\Envy.ps1"

# --- 1.1 Load Managers (New) ---
. "$PSScriptRoot\src\Managers\HighScoreManager.ps1"
. "$PSScriptRoot\src\Managers\GameLogic.ps1" 
. "$PSScriptRoot\src\Managers\CollisionManager.ps1" 
. "$PSScriptRoot\src\Managers\RenderManager.ps1"

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

    # --- RESET GAME OBJECTS ---
    # สร้าง Player ใหม่ที่จุดเริ่มต้น
    $Script:player = [Player]::new(225, 500)
    
    # ล้างศัตรูและกระสุนให้เกลี้ยง
    if ($null -ne $Script:bullets) { $Script:bullets.Clear() }
    if ($null -ne $Script:enemies) { $Script:enemies.Clear() }
    
    # ล้างกระสุนศัตรู (สร้างใหม่เลยกันเหนียว)
    $Script:enemyBullets = [System.Collections.ArrayList]::new()
    
    # รีเซ็ตค่าคะแนนและเลเวล
    $Script:score = 0
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
$Script:player = [Player]::new(225, 500)

if ($null -eq $Script:player) {
    [System.Windows.Forms.MessageBox]::Show("Failed to load player! Check Player.ps1", "Error")
    exit
}

$Script:bullets = [System.Collections.ArrayList]::new()
$Script:enemies = [System.Collections.ArrayList]::new()

$Script:rnd = New-Object System.Random
$Script:enemyBullets = [System.Collections.ArrayList]::new()

$Script:score = 0
$Script:level = 1
$Script:lives = 3   
$Script:wrathKills = 0     # สำหรับนับจำนวนโกรธ
$Script:silenceTimer = 0   # ตัวนับเวลาติดใบ้
$Script:wrathBuffTimer = 0  # ตัวจับเวลา Buff 7 วินาที (420 เฟรม)
$Script:wrathBuffLevel = 0  # 0=ปกติ, 1=ยิง 2 นัด(Blue), 2=ยิง 4 นัด(Red)
$Script:spawnRate = 3  
$Script:gameStarted = $false
$Script:gameOver = $false
$Script:showLeaderboard = $false
$Script:keysPressed = @{}

# --- 4. Input Handling ---
$form.KeyPreview = $true 
$form.Add_KeyDown({
    $Script:keysPressed[$_.KeyCode.ToString()] = $true
    
    # Press Esc to pause/exit
    if ($_.KeyCode -eq "Escape") { 
        $timer.Stop()
        $ans = [System.Windows.Forms.MessageBox]::Show("Do you want to exit?", "Quit Game", 4, 32)
        if ($ans -eq "Yes") { $form.Close() }
        else { $timer.Start() }
    }

     # กด Enter
    if ($_.KeyCode -eq "Enter") {
        # กรณี 1: ถ้าดู Leaderboard อยู่ -> ให้กลับไปหน้า Start Screen
        if ($Script:showLeaderboard) {
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
    if (-not $Script:gameStarted -or $Script:gameOver) { return }

    # --- A. Update Difficulty (เรียกจาก GameLogic.ps1) ---
    $diff = Get-GameDifficulty $Script:score
    $Script:level = $diff.Level
    $Script:spawnRate = $diff.SpawnRate
    $Script:targetScore = $diff.NextLevelScore


    if ($Script:keysPressed["A"] -or $Script:keysPressed["Left"]) { 
        $Script:player.MoveLeft() 
    }
    if ($Script:keysPressed["D"] -or $Script:keysPressed["Right"]) { 
        #$Script:player.MoveRight($form.ClientSize.Width) 
        $Script:player.MoveRight(500) 
    }
    
    # Shooting
    if ($Script:keysPressed["W"] -or $Script:keysPressed["Space"] -or $Script:keysPressed["Up"]) {
        if ($Script:silenceTimer -le 0 -and $Script:player.CanShoot()) {
            
            $px = $Script:player.X
            $py = $Script:player.Y

            if ($Script:wrathBuffLevel -eq 2) {
                # [บัฟแดง - ยิง 4 นัด]
                # 2 นัดคู่ตรงกลาง (SpeedX = 0)
                [void]$Script:bullets.Add([Bullet]::new($px + 4, $py, 0))    
                [void]$Script:bullets.Add([Bullet]::new($px + 20, $py, 0))   
                # 2 นัดเฉียงออกซ้าย-ขวา (SpeedX = -4 และ 4)
                [void]$Script:bullets.Add([Bullet]::new($px - 4, $py, -4))   
                [void]$Script:bullets.Add([Bullet]::new($px + 28, $py, 4))   
            } 
            elseif ($Script:wrathBuffLevel -eq 1) {
                # [บัฟฟ้า - ยิง 2 นัดคู่] (SpeedX = 0 ยิงตรง)
                [void]$Script:bullets.Add([Bullet]::new($px + 4, $py, 0))
                [void]$Script:bullets.Add([Bullet]::new($px + 20, $py, 0))
            } 
            else {
                # [ปกติ - ยิง 1 นัด] 
                # เรียก Constructor เดิมแบบไม่ใส่ SpeedX เลย
                [void]$Script:bullets.Add([Bullet]::new($px + 12, $py))
            }

            $Script:player.ResetCooldown()
        }
    }
    $Script:player.Update()

    # --- B. Spawn Enemies ---
    if ($Script:rnd.Next(0, 100) -lt $Script:spawnRate) {
        # ของเดิมโยน $form.ClientSize.Width เข้าไป ทำให้ศัตรูไปเกิดตรง X=500-700 ได้
        # ให้เปลี่ยนเป็นเลข 500 ถ้วนๆ ครับ
        $newEnemy = New-EnemySpawn 500 $Script:level $Script:rnd
        [void]$Script:enemies.Add($newEnemy)
    }

    # --- C. Update Bullets ---
    for ($i = $Script:bullets.Count - 1; $i -ge 0; $i--) {
        $b = $Script:bullets[$i]
        $b.Update()
        if ($b.Y -lt -20) { $Script:bullets.RemoveAt($i) }
    }

    # --- D. Update Entities Movement (เคลื่อนที่ศัตรู & กระสุนศัตรู) ---
    # เราแยกแค่การเคลื่อนที่ไว้ตรงนี้ ส่วนการชนไปให้ Manager จัดการ
    foreach ($e in $Script:enemies) { 
        $e.Update() 
        $shotResult = $e.TryShoot($Script:level)
        
        if ($null -ne $shotResult) { 
            # เช็คว่าส่งกระสุนมาเป็นกลุ่ม (Array) หรือส่งมานัดเดียว
            if ($shotResult -is [System.Collections.IEnumerable]) {
                foreach ($b in $shotResult) {[void]$Script:enemyBullets.Add($b) 
                }
            } else {
                [void]$Script:enemyBullets.Add($shotResult)
            }
        }
    }

    foreach ($eb in $Script:enemyBullets) { $eb.Update() }

    # --- E. Handle Collisions ---
    $collisionResult = Invoke-GameCollisions $Script:player $Script:bullets $Script:enemies $Script:enemyBullets $form.ClientSize.Height

    # -----------------------------------
    # [NEW] ระบบสุ่ม Buff จากการฆ่า Wrath
    # -----------------------------------
    if ($collisionResult.WrathKills -gt 0) {
        for ($k = 0; $k -lt $collisionResult.WrathKills; $k++) {
            $roll = $Script:rnd.Next(1, 101) # สุ่ม 1-100
            
            if ($roll -le 5) {
                # โอกาส 5% ได้บัฟระดับ 2 (Red - ยิง 4 นัด)
                $Script:wrathBuffLevel = 2
                $Script:wrathBuffTimer = 420 
            } else {
                # โอกาส 95% ได้บัฟระดับ 1 (Blue - ยิง 2 นัด)
                if ($Script:wrathBuffLevel -lt 2) {
                    $Script:wrathBuffLevel = 1
                }
                $Script:wrathBuffTimer = 420 
            }
        }
    }

    # ลดเวลา Buff 
    if ($Script:wrathBuffTimer -gt 0) { 
        $Script:wrathBuffTimer -= 1 
        if ($Script:wrathBuffTimer -le 0) {
            $Script:wrathBuffLevel = 0 
        }
    }


    # ลดเวลาสถานะใบ้ลงเรื่อยๆ ทุกเฟรม
    if ($Script:silenceTimer -gt 0) { 
        $Script:silenceTimer -= 1 
    }

    # ถ้าโดนกระสุนใบ้ ให้ตั้งเวลาเป็น 180 เฟรม (3 วินาที)
    if ($collisionResult.ApplySilence) {
        $Script:silenceTimer = 180 
    }
    # 1. อัปเดตคะแนน
    if ($collisionResult.ScoreAdded -gt 0) {
        $Script:score += $collisionResult.ScoreAdded
    }

    # 2. เช็คว่าผู้เล่นโดนดาเมจไหม
    if ($collisionResult.IsPlayerHit) {
        $Script:lives -= 1   # ลดชีวิต 1 ดวง
        
        if ($Script:lives -le 0) {
            # ชีวิตหมดแล้ว ค่อยสั่งจบเกม
            Do-GameOver
            return 
        } else {
            # ถ้ายังมีชีวิตเหลืออยู่ ให้เคลียร์หน้าจอเพื่อให้เริ่มลุยใหม่แบบยุติธรรม (ไม่โดนรุมตายซ้ำ)
            $Script:player.X = 225
            $Script:player.Y = 500
            
            # เคลียร์ศัตรูและกระสุนทิ้งทั้งหมด ให้มันเกิดใหม่ (ป้องกันตายเกิดมาโดนกระสุนเดิมซ้ำ)
            $Script:enemies.Clear()
            $Script:enemyBullets.Clear()
            $Script:bullets.Clear()
        }
    }

    $form.Invalidate()
})

# --- 6. Render/Paint ---
$form.Add_Paint({
    try {
        $g = $_.Graphics
        $g.SmoothingMode = "AntiAlias"
        $g.TextRenderingHint = "AntiAlias"
        $g.Clear([System.Drawing.Color]::Black)

        if ($Script:showLeaderboard) {
            Draw-Leaderboard $g $form.Width $form.Height
            return
        }

        if (-not $Script:gameStarted) {
            Draw-StartScreen $g $form.Width $form.Height
            return
        }

       # ==========================================
        #[NEW] คำนวณ Buff และ Debuff ของจริงเพื่อส่งไป UI
        # ==========================================
        $activeBuffs = @()
        $activeDebuffs = @()

        # --- 1. เช็ค BUFF: Wrath (ปืนคู่ / ปืนกระจาย) ---
        if ($Script:wrathBuffTimer -gt 0) {
            $bSecondsLeft = [math]::Round(($Script:wrathBuffTimer / 60.0), 1)
            $bFormattedTime = "{0:N1}" -f $bSecondsLeft

            # กำหนดสี: Level 2 = แดง (ยิง 4), Level 1 = ฟ้า (ยิง 2)
            $bColor = if ($Script:wrathBuffLevel -eq 2) { [System.Drawing.Brushes]::Red } else { [System.Drawing.Brushes]::DeepSkyBlue }

            $newBuff = [PSCustomObject]@{
                Icon  = "W" 
                Value = $bFormattedTime
                Color = $bColor 
            }
            $activeBuffs += $newBuff

            # [DEBUG ต้นทาง Buff] 
            # Write-Host "PAINT EVENT (BUFF) -> Level: $($Script:wrathBuffLevel), Formatted: $bFormattedTime, Buffs Count: $($activeBuffs.Count)"
        }

        # --- 2. เช็ค DEBUFF: Silence (สถานะใบ้) ---
        if ($Script:silenceTimer -gt 0) {
            $dSecondsLeft = [math]::Round(($Script:silenceTimer / 60.0), 1)
            $dFormattedTime = "{0:N1}" -f $dSecondsLeft

            $newDebuff = [PSCustomObject]@{
                Icon  = "Z" 
                Value = $dFormattedTime
                Color = [System.Drawing.Brushes]::Magenta 
            }
            $activeDebuffs += $newDebuff

            # [DEBUG ต้นทาง Debuff]
            # Write-Host "PAINT EVENT (DEBUFF) -> Timer: $($Script:silenceTimer), Formatted: $dFormattedTime, Debuffs Count: $($activeDebuffs.Count)"
        }

        # --- CASE 3: GAMEPLAY ---
        Draw-Gameplay $g $Script:player $Script:bullets $Script:enemies $Script:enemyBullets $Script:score $Script:level $Script:lives $Script:targetScore $activeBuffs $activeDebuffs
    } catch {
        Write-Host "Paint Error: $_"
    }
})


$form.Add_Shown({ $form.Activate(); $form.Focus() })

# --- 7. Start Game ---
$timer.Start()
Write-Host "Starting Game Loop..."
[void]$form.ShowDialog()