$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- 1. Load Classes ---
. "$PSScriptRoot\src\Entities\GameObject.ps1"
. "$PSScriptRoot\src\Entities\Player.ps1"
. "$PSScriptRoot\src\Entities\Bullet.ps1"
. "$PSScriptRoot\src\Entities\EnemyBullet.ps1" 
. "$PSScriptRoot\src\Entities\Enemy.ps1"

# --- 1.1 Load Managers (New) ---
. "$PSScriptRoot\src\HighScoreManager.ps1"
. "$PSScriptRoot\src\GameLogic.ps1" 
. "$PSScriptRoot\src\CollisionManager.ps1" 
. "$PSScriptRoot\src\RenderManager.ps1"

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
$form.ClientSize = New-Object System.Drawing.Size(500, 600)
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
$Script:spawnRate = 3  # โอกาสเกิด 3%
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


    if ($Script:keysPressed["A"] -or $Script:keysPressed["Left"]) { 
        $Script:player.MoveLeft() 
    }
    if ($Script:keysPressed["D"] -or $Script:keysPressed["Right"]) { 
        $Script:player.MoveRight($form.ClientSize.Width) 
    }
    
    # Shooting
    if ($Script:keysPressed["W"] -or $Script:keysPressed["Space"] -or $Script:keysPressed["Up"]) {
        if ($Script:player.CanShoot()) {
            $newBullet = [Bullet]::new($Script:player.X + 12, $Script:player.Y)
            [void]$Script:bullets.Add($newBullet)
            $Script:player.ResetCooldown()
        }
    }
    $Script:player.Update()

    # --- B. Spawn Enemies ---
    if ($Script:rnd.Next(0, 100) -lt $Script:spawnRate) {
        # เรียกฟังก์ชันสร้าง Enemy แทน Code ก้อนใหญ่
        $newEnemy = New-EnemySpawn $form.ClientSize.Width $Script:level $Script:rnd
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
        # ศัตรูยิงสวน
        $bullet = $e.TryShoot($Script:level)
        if ($null -ne $bullet) { [void]$Script:enemyBullets.Add($bullet) }
    }
    foreach ($eb in $Script:enemyBullets) { $eb.Update() }

    # --- E. Handle Collisions (เรียกใช้ CollisionManager) ---
    # ส่ง List ทั้งหมดเข้าไปเช็คทีเดียว
    $collisionResult = Invoke-GameCollisions $Script:player $Script:bullets $Script:enemies $Script:enemyBullets $form.ClientSize.Height

    # 1. อัปเดตคะแนน
    if ($collisionResult.ScoreAdded -gt 0) {
        $Script:score += $collisionResult.ScoreAdded
    }

    # 2. เช็ค Game Over
    if ($collisionResult.IsGameOver) {
        Do-GameOver
        return # ออกจาก Loop ทันที
    }

    $form.Invalidate()
})

# --- 6. Render/Paint ---
$form.Add_Paint({
    try {
        $g = $_.Graphics
        # ตั้งค่ากราฟิกให้เนียน
        $g.SmoothingMode = "AntiAlias"
        $g.TextRenderingHint = "AntiAlias"
        $g.Clear([System.Drawing.Color]::Black)

        # --- CASE 1: LEADERBOARD ---
        if ($Script:showLeaderboard) {
            Draw-Leaderboard $g $form.Width $form.Height
            return
        }

        # --- CASE 2: START SCREEN ---
        if (-not $Script:gameStarted) {
            Draw-StartScreen $g $form.Width $form.Height
            return
        }

        # --- CASE 3: GAMEPLAY ---
        Draw-Gameplay $g $Script:player $Script:bullets $Script:enemies $Script:enemyBullets $Script:score $Script:level

    } catch {
        Write-Host "Paint Error: $_"
    }
})


$form.Add_Shown({ $form.Activate(); $form.Focus() })

# --- 7. Start Game ---
$timer.Start()
Write-Host "Starting Game Loop..."
[void]$form.ShowDialog()