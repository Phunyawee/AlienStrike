$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- 1. Load Classes ---
. "$PSScriptRoot\src\Entities\GameObject.ps1"
. "$PSScriptRoot\src\Entities\Player.ps1"
. "$PSScriptRoot\src\Entities\Bullet.ps1"
. "$PSScriptRoot\src\Entities\EnemyBullet.ps1" 
. "$PSScriptRoot\src\Entities\Enemy.ps1"


# --- Helper Functions: Score System ---
$scoreFile = "$PSScriptRoot\scores.json"

function Get-HighScores {
    if (Test-Path $scoreFile) {
        return Get-Content $scoreFile | ConvertFrom-Json | Sort-Object Score -Descending | Select-Object -First 10
    }
    return @()
}

function Save-Score ($name, $score, $lvl) {
    $scores = @(Get-HighScores)
    $scores += @{ Name = $name; Score = $score; Level = $lvl; Date = (Get-Date).ToString("yyyy-MM-dd HH:mm") }
    $scores | Sort-Object Score -Descending | Select-Object -First 10 | ConvertTo-Json | Out-File $scoreFile
}

function Do-GameOver {
    $timer.Stop()
    
    # ถามชื่อและเซฟ (ตามเดิม)
    $name = Show-NameInputBox $Script:score
    Save-Score $name $Script:score $Script:level

    $Script:gameOver = $false
    $Script:gameStarted = $false
    $Script:showLeaderboard = $true

    # Reset Player
    $Script:player = [Player]::new(225, 500)
    
    # Safe Clear: เช็คก่อนว่าไม่เป็น $null ค่อย Clear
    if ($null -ne $Script:bullets) { $Script:bullets.Clear() }
    if ($null -ne $Script:enemies) { $Script:enemies.Clear() }
    
    # จุดที่น่าจะพังคือตรงนี้ ให้แก้เป็นแบบนี้ครับ
    if ($null -ne $Script:enemyBullets) { 
        $Script:enemyBullets.Clear() 
    } else {
        # ถ้ามันยังไม่มี ก็สร้างใหม่เลย
        $Script:enemyBullets = [System.Collections.ArrayList]::new()
    }
    
    $Script:score = 0
    $Script:level = 1

    $form.Invalidate()
}

function Show-NameInputBox ($score) {
    # สร้าง Form เล็กๆ สำหรับกรอกชื่อ (Pop-up)
    $inputForm = New-Object System.Windows.Forms.Form
    $inputForm.Text = "NEW HIGH SCORE!"
    $inputForm.Size = New-Object System.Drawing.Size(300, 180)
    $inputForm.StartPosition = "CenterScreen"
    $inputForm.BackColor = "Black"
    $inputForm.FormBorderStyle = "FixedToolWindow"

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "SCORE: $score`nEnter Your Name:"
    $lbl.ForeColor = "Yellow"
    $lbl.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point(20, 20)
    $inputForm.Controls.Add($lbl)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(20, 70)
    $txt.Size = New-Object System.Drawing.Size(240, 30)
    $txt.Font = New-Object System.Drawing.Font("Arial", 12)
    $inputForm.Controls.Add($txt)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "SAVE"
    $btn.DialogResult = "OK"
    $btn.BackColor = "Green"
    $btn.ForeColor = "White"
    $btn.FlatStyle = "Flat"
    $btn.Location = New-Object System.Drawing.Point(180, 110)
    $inputForm.Controls.Add($btn)
    
    $inputForm.AcceptButton = $btn
    
    $result = $inputForm.ShowDialog()
    if ($result -eq "OK" -and $txt.Text.Trim() -ne "") {
        return $txt.Text.Trim()
    }
    return "Unknown"
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

    if ($_.KeyCode -eq "Enter") {
        if ($Script:showLeaderboard) {
            # ออกจากหน้า Leaderboard กลับไปหน้า Start
            $Script:showLeaderboard = $false
            $Script:gameStarted = $false
            $Script:gameOver = $false
        } elseif (-not $Script:gameStarted) { 
            $Script:gameStarted = $true 
        }
    }

    # กด L ที่หน้า Start Screen เพื่อดู Leaderboard
    if ($_.KeyCode -eq "L" -and -not $Script:gameStarted -and -not $Script:showLeaderboard) {
        $Script:showLeaderboard = $true
        $form.Invalidate()
    }

    # Press Enter to start or restart on game over
    if ($_.KeyCode -eq "Enter") {
        if (-not $Script:gameStarted) { $Script:gameStarted = $true }
        elseif ($Script:gameOver) { $form.Close() }
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

    # >> เพิ่มตรงนี้: ถ้าคะแนนเกิน 5000 ให้เป็น Level 4 <<
    if ($Script:score -ge 5000) {
        $Script:level = 4
        $Script:spawnRate = 10 # มาถี่ขึ้นอีก!
    } 
    elseif ($Script:score -ge 3000) {
        $Script:level = 3
        $Script:spawnRate = 8
    } 
    elseif ($Script:score -ge 1000) {
        $Script:level = 2
        $Script:spawnRate = 5
    }


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
        $ex = $Script:rnd.Next(0, ($form.ClientSize.Width - 30))
        
        if ($Script:level -eq 1) {
            $newEnemy = [Enemy]::new($ex, -40, $Script:rnd.Next(3, 6), [System.Drawing.Color]::Red)
        } elseif ($Script:level -eq 2) {
            $newEnemy = [Enemy]::new($ex, -40, $Script:rnd.Next(5, 9), [System.Drawing.Color]::Orange)
        } elseif ($Script:level -eq 3) {
            $newEnemy = [Enemy]::new($ex, -40, $Script:rnd.Next(8, 12), [System.Drawing.Color]::Purple)
        } else {
            # >> Level 4+: สีเงิน (Silver) เร็วและยิงสวนได้! <<
            # (Logic ยิงสวนอยู่ใน Class Enemy แล้ว มันจะทำงานเองเมื่อ Level >= 4)
            $newEnemy = [Enemy]::new($ex, -40, $Script:rnd.Next(9, 13), [System.Drawing.Color]::Silver)
        }
        
        [void]$Script:enemies.Add($newEnemy)
    }

    # --- C. Update Bullets ---
    for ($i = $Script:bullets.Count - 1; $i -ge 0; $i--) {
        $b = $Script:bullets[$i]
        $b.Update()
        if ($b.Y -lt -20) { $Script:bullets.RemoveAt($i) }
    }

    # --- D. Update Enemies & Collisions ---
    for ($i = $Script:enemies.Count - 1; $i -ge 0; $i--) {
        $e = $Script:enemies[$i]
        $e.Update()

        $bullet = $e.TryShoot($Script:level)
        if ($null -ne $bullet) {
            [void]$Script:enemyBullets.Add($bullet)
        }

        # 1. Check Collision with Player (Game Over)
        if ($e.GetBounds().IntersectsWith($Script:player.GetBounds())) {
            Do-GameOver  # <--- แก้เหลือแค่นี้พอ
        return
    }

        # 2. Check Collision with Bullets
        $isHit = $false
        for ($j = $Script:bullets.Count - 1; $j -ge 0; $j--) {
            if ($e.GetBounds().IntersectsWith($Script:bullets[$j].GetBounds())) {
                $Script:bullets.RemoveAt($j)
                $isHit = $true
                $Script:score += 100
                break
            }
        }

        if ($isHit) {
            $Script:enemies.RemoveAt($i)
        } elseif ($e.Y -gt $form.ClientSize.Height) {
            $Script:enemies.RemoveAt($i)
        }
    }

    # --- E. Update Enemy Bullets ---
    for ($i = $Script:enemyBullets.Count - 1; $i -ge 0; $i--) {
        $eb = $Script:enemyBullets[$i]
        $eb.Update()

        # 1. เช็คชนผู้เล่น (Game Over)
        # ปรับ Hitbox เล็กนิดนึงจะได้ไม่หัวร้อน (Inflate -5)
        $bulletHitbox = $eb.GetBounds()
        $bulletHitbox.Inflate(-5, -5) 

        if ($bulletHitbox.IntersectsWith($Script:player.GetBounds())) {
            Do-GameOver  # <--- เรียกฟังก์ชันเดียวกันเลย
            return
        }

        # 2. ลบทิ้งเมื่อหลุดขอบจอ
        if ($eb.Y -gt $form.ClientSize.Height) {
            $Script:enemyBullets.RemoveAt($i)
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

        # --- 1. LEADERBOARD SCREEN ---
        if ($Script:showLeaderboard) {
            $titleFont = New-Object System.Drawing.Font("Impact", 36)
            $headFont  = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
            $rowFont   = New-Object System.Drawing.Font("Consolas", 12)
            $center    = New-Object System.Drawing.StringFormat; $center.Alignment = "Center"
            
            # วาดหัวข้อ
            $g.DrawString("HALL OF FAME", $titleFont, [System.Drawing.Brushes]::Gold, ($form.Width/2), 30, $center)
            $g.DrawLine([System.Drawing.Pens]::DimGray, 50, 100, 450, 100)

            # หัวตาราง
            $y = 120
            $g.DrawString("RANK", $headFont, [System.Drawing.Brushes]::Gray, 60, $y)
            $g.DrawString("NAME", $headFont, [System.Drawing.Brushes]::Gray, 150, $y)
            $g.DrawString("LEVEL", $headFont, [System.Drawing.Brushes]::Gray, 280, $y)
            $g.DrawString("SCORE", $headFont, [System.Drawing.Brushes]::Gray, 380, $y)
            
            $y += 30
            $rank = 1
            
            # โหลดคะแนน (ถ้าพังให้คืนค่าว่าง)
            $scores = @()
            try { $scores = Get-HighScores } catch { }

            if ($null -ne $scores) {
                foreach ($s in $scores) {
                    if ($null -eq $s) { continue } # ข้ามถ้าข้อมูลเสีย

                    # เลือกสี
                    if ($rank -eq 1) { $brush = [System.Drawing.Brushes]::Gold }
                    elseif ($rank -eq 2) { $brush = [System.Drawing.Brushes]::Silver }
                    elseif ($rank -eq 3) { $brush = [System.Drawing.Brushes]::SandyBrown }
                    else { $brush = [System.Drawing.Brushes]::White }

                    $sfRight = New-Object System.Drawing.StringFormat; $sfRight.Alignment = "Far"
                    $sfCenter = New-Object System.Drawing.StringFormat; $sfCenter.Alignment = "Center"

                    # --- จุดแก้บั๊ก: แปลงค่าให้ชัวร์ก่อนวาด ---
                    $pName = if ($s.Name) { $s.Name } else { "Unknown" }
                    $pLevel = if ($s.Level) { "$($s.Level)" } else { "1" }
                    
                    # เช็ค Score ว่ามีค่าไหม ถ้าไม่มีให้เป็น 0
                    $rawScore = 0
                    if ($s.Score -and $s.Score -is [ValueType]) { $rawScore = $s.Score }
                    $pScore = "{0:N0}" -f $rawScore

                    $g.DrawString("#$rank", $rowFont, [System.Drawing.Brushes]::DimGray, 60, $y)
                    $g.DrawString($pName, $rowFont, $brush, 150, $y)
                    $g.DrawString($pLevel, $rowFont, [System.Drawing.Brushes]::Cyan, 305, $y, $sfCenter)
                    $g.DrawString($pScore, $rowFont, $brush, 430, $y, $sfRight)

                    $y += 25
                    $rank++
                }
            }
            
            $g.DrawString("Press ENTER to Return", $rowFont, [System.Drawing.Brushes]::DarkGray, ($form.Width/2), 520, $center)
            
            return # <--- สำคัญมาก! ต้อง Return เพื่อไม่ให้วาดเกมต่อ
        }

        # --- 2. START SCREEN ---
        if (-not $Script:gameStarted) {
            $font1 = New-Object System.Drawing.Font("Arial", 28, [System.Drawing.FontStyle]::Bold)
            $font2 = New-Object System.Drawing.Font("Arial", 14)
            $fontS = New-Object System.Drawing.Font("Arial", 10)
            $format = New-Object System.Drawing.StringFormat
            $format.Alignment = "Center"
            
            $g.DrawString("ALIEN STRIKE", $font1, [System.Drawing.Brushes]::Cyan, ($form.ClientSize.Width/2), 180, $format)
            $g.DrawString("Press ENTER to Start", $font2, [System.Drawing.Brushes]::Yellow, ($form.ClientSize.Width/2), 280, $format)
            $g.DrawString("[ L ] View Leaderboard", $fontS, [System.Drawing.Brushes]::LightGray, ($form.ClientSize.Width/2), 320, $format)
            return
        }

        # --- 3. GAMEPLAY ---
        # วาด Player (เช็คก่อนว่าไม่ null)
        if ($null -ne $Script:player) { $Script:player.Draw($g) }
        
        # วาด Bullets
        if ($null -ne $Script:bullets) {
            foreach ($b in $Script:bullets) { if ($b) { $b.Draw($g) } }
        }
        
        # วาด Enemies
        if ($null -ne $Script:enemies) {
            foreach ($e in $Script:enemies) { if ($e) { $e.Draw($g) } }
        }

        # วาด Enemy Bullets (อันใหม่)
        if ($null -ne $Script:enemyBullets) {
            foreach ($eb in $Script:enemyBullets) { if ($eb) { $eb.Draw($g) } }
        }

        # Draw UI
        $scoreFont = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
        $g.DrawString("Score: $($Script:score)", $scoreFont, [System.Drawing.Brushes]::White, 10, 10)
        $g.DrawString("Level: $($Script:level)", $scoreFont, [System.Drawing.Brushes]::Yellow, 10, 35)

    } catch {
        # ถ้ายัง Error ให้พิมพ์บอกใน Console แทนการเด้ง Popup
        Write-Host "Paint Error: $_"
    }
})

$form.Add_Shown({ $form.Activate(); $form.Focus() })

# --- 7. Start Game ---
$timer.Start()
Write-Host "Starting Game Loop..."
[void]$form.ShowDialog()