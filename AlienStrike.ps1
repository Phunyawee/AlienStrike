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
. "$PSScriptRoot\src\Entities\Projectiles\PrideLaser.ps1" 
. "$PSScriptRoot\src\Entities\Enemies\Sins\Pride.ps1"
. "$PSScriptRoot\src\Entities\Projectiles\Missile.ps1"
. "$PSScriptRoot\src\Entities\Projectiles\SirenBullet.ps1" 
. "$PSScriptRoot\src\Entities\Enemies\Sins\Lust.ps1"
. "$PSScriptRoot\src\Entities\Projectiles\SlothBomb.ps1" 
. "$PSScriptRoot\src\Entities\Enemies\Sins\Sloth.ps1"


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
    $Script:sirenTimer = 0   # ตัวนับเวลาติดสถานะ Siren (เดินสลับทิศ)
    $Script:wrathStackCount = 0  # ตัวนับ Stack (0-5)
    $Script:currentTrackedLevel = 1 # ใส่ไว้ตอนเริ่มเกม / ในฟังก์ชัน Do-GameOver
    $Script:jammerTimer = 0    # ตัวนับเวลาติดสถานะ Jammer (ห้ามใช้ Item)
    $Script:prideKills = 0     # ตัวนับจำนวนการฆ่า Pride (สะสมเพื่อเรียก Sloth)

    $Script:speedTimer = 0  # ตัวนับเวลา Buff Speed

    # --- RESET GAME OBJECTS ---
    # สร้าง Player ใหม่ที่จุดเริ่มต้น
    $Script:player = [Player]::new(225, 500)
    
    # ล้างศัตรูและกระสุนให้เกลี้ยง
    if ($null -ne $Script:bullets) { $Script:bullets.Clear() }
    if ($null -ne $Script:enemies) { $Script:enemies.Clear() }
    
    # ล้างกระสุนศัตรู (สร้างใหม่เลยกันเหนียว)
    $Script:enemyBullets = [System.Collections.ArrayList]::new()

    $Script:inventory = [System.Collections.ArrayList]::new()
    # ตอนเริ่มเกม แจกให้ก่อนเลย 5 อัน
    1..5 | ForEach-Object { [void]$Script:inventory.Add("Missile") }
    
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
1..5 | ForEach-Object { [void]$Script:inventory.Add("Missile") }

$Script:score = 0
$Script:nextPrideScoreTarget = 5000 # เป้าหมายคะแนนแรกที่ Pride จะเกิด
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
$Script:spawnRate = 3  
$Script:gameStarted = $false
$Script:gameOver = $false
$Script:showLeaderboard = $false
$Script:speedTimer = 0  # ตัวนับเวลา Buff Speed
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

    # --- A. Update Difficulty ---
    $diff = Get-GameDifficulty $Script:score
    $Script:level = $diff.Level
    $Script:spawnRate = $diff.SpawnRate
    $Script:targetScore = $diff.NextLevelScore

    # --- เช็คการเกิดของบอสพิเศษ (Lust / Pride) ---
    Check-BossSpawns

    # --- ควบคุมผู้เล่น ---
    Handle-PlayerInput

    # --- B. Spawn Enemies (ศัตรูธรรมดา) ---
    if ($Script:rnd.Next(0, 100) -lt $Script:spawnRate) {
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
    $collisionResult = Invoke-GameCollisions $Script:player $Script:bullets $Script:enemies $Script:enemyBullets $form.ClientSize.Height

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

        if ($Script:showLeaderboard) {
            Draw-Leaderboard $g $form.Width $form.Height
            return
        }

        if (-not $Script:gameStarted) {
            Draw-StartScreen $g $form.Width $form.Height
            return
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