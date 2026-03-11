# AlienStrike\src\Managers\RenderManager.ps1

Add-Type -AssemblyName System.Drawing

# --- Helper: Settings (Font/Brush) ---
$Global:GameFonts = @{
    Title   = New-Object System.Drawing.Font("Impact", 36)
    Header  = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
    Text    = New-Object System.Drawing.Font("Consolas", 12)
    BigText = New-Object System.Drawing.Font("Arial", 28, [System.Drawing.FontStyle]::Bold)
    SubText = New-Object System.Drawing.Font("Arial", 14)
    Small   = New-Object System.Drawing.Font("Arial", 10)
    HUD     = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
    Icon    = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold) # ฟอนต์สำหรับตัวย่อไอคอน
    Tiny    = New-Object System.Drawing.Font("Consolas", 8)  # ฟอนต์สำหรับตัวเลขบัพ
}

function Draw-StartScreen ($g, $width, $height) {
    $center = New-Object System.Drawing.StringFormat
    $center.Alignment = "Center"
    
    $g.DrawString("ALIEN STRIKE", $Global:GameFonts.BigText, [System.Drawing.Brushes]::Cyan, ($width/2), 180, $center)
    $g.DrawString("Press ENTER to Start", $Global:GameFonts.SubText, [System.Drawing.Brushes]::Yellow, ($width/2), 280, $center)
    $g.DrawString("[ L ] View Leaderboard", $Global:GameFonts.Small, [System.Drawing.Brushes]::LightGray, ($width/2), 320, $center)
}

function Draw-Leaderboard ($g, $width, $height) {
    $scores = try { Get-HighScores } catch { @() }

    $center = New-Object System.Drawing.StringFormat; $center.Alignment = "Center"
    $right  = New-Object System.Drawing.StringFormat; $right.Alignment = "Far"

    $g.DrawString("HALL OF FAME", $Global:GameFonts.Title, [System.Drawing.Brushes]::Gold, ($width/2), 30, $center)
    $g.DrawLine([System.Drawing.Pens]::DimGray, 50, 100, ($width-50), 100)

    $y = 120
    $g.DrawString("RANK", $Global:GameFonts.Header, [System.Drawing.Brushes]::Gray, 60, $y)
    $g.DrawString("NAME", $Global:GameFonts.Header, [System.Drawing.Brushes]::Gray, 150, $y)
    $g.DrawString("LEVEL", $Global:GameFonts.Header, [System.Drawing.Brushes]::Gray, 300, $y, $center)
    $g.DrawString("SCORE", $Global:GameFonts.Header, [System.Drawing.Brushes]::Gray, 430, $y, $right)
    
    $y += 35
    $rank = 1

    if ($null -ne $scores) {
        foreach ($s in $scores) {
            if ($null -eq $s) { continue }

            if ($rank -eq 1) { $brush = [System.Drawing.Brushes]::Gold }
            elseif ($rank -eq 2) { $brush = [System.Drawing.Brushes]::Silver }
            elseif ($rank -eq 3) { $brush = [System.Drawing.Brushes]::SandyBrown }
            else { $brush =[System.Drawing.Brushes]::White }

            $pName = if ($s.Name) { $s.Name } else { "Unknown" }
            $pLevel = if ($s.Level) { "$($s.Level)" } else { "1" }
            $rawScore = if ($s.Score -and $s.Score -is [ValueType]) { $s.Score } else { 0 }
            $pScore = "{0:N0}" -f $rawScore

            $g.DrawString("#$rank", $Global:GameFonts.Text, [System.Drawing.Brushes]::DimGray, 60, $y)
            $g.DrawString($pName, $Global:GameFonts.Text, $brush, 150, $y)
            $g.DrawString($pLevel, $Global:GameFonts.Text, [System.Drawing.Brushes]::Cyan, 300, $y, $center)
            $g.DrawString($pScore, $Global:GameFonts.Text, $brush, 430, $y, $right)

            $y += 25
            $rank++
        }
    }
    
    $g.DrawString("Press ENTER to Return", $Global:GameFonts.Text, [System.Drawing.Brushes]::DarkGray, ($width/2), 520, $center)
}

# --- เพิ่มพารามิเตอร์ $enemies เข้าไปในฟังก์ชัน Draw-HUD ---
function Draw-HUD ($g, $score, $level, $lives, $inventory, $buffs, $debuffs, $targetScore, $enemies) {
    $fontSmall = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
    $fontLarge = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
    $sidebarX = 500
    $sidebarWidth = 200

    # --- 1. วาดกรอบ Sidebar ด้านขวา ---
    $sideBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 20, 20, 25))
    $g.FillRectangle($sideBg, $sidebarX, 0, $sidebarWidth, 600)
    $g.DrawLine([System.Drawing.Pen]::new([System.Drawing.Color]::Cyan, 2), $sidebarX, 0, $sidebarX, 600)

    # --- 2. ข้อมูล Score / Level / Lives ใน Sidebar ---
    $g.DrawString("SCORE", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), 20)
    $g.DrawString("$score", $fontLarge, [System.Drawing.Brushes]::Yellow, ($sidebarX + 15), 35)
    $g.DrawString("LEVEL $level", $fontSmall, [System.Drawing.Brushes]::White, ($sidebarX + 15), 75)
    
    $g.FillRectangle([System.Drawing.Brushes]::DarkSlateGray, ($sidebarX + 15), 95, 170, 6)
    $progress = [math]::Min(($score / $targetScore), 1.0)
    $g.FillRectangle([System.Drawing.Brushes]::Lime, ($sidebarX + 15), 95, (170 * $progress), 6)

    $g.DrawString("LIVES", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), 115)
    for ($l = 0; $l -lt $lives; $l++) {
        $g.FillEllipse([System.Drawing.Brushes]::Red, ($sidebarX + 15 + ($l * 25)), 135, 18, 18)
    }

    # --- 3. [NEW] วาดบอสบาร์ของ LUCIFER (ถ้าบอสออกมาแล้ว) ---
    $lucifer = $enemies | Where-Object { $_.GetType().Name -eq "Lucifer" } | Select-Object -First 1
    if ($lucifer) {
        $barX = 50; $barY = 15; $barW = 400
        # พื้นหลังเทา
        $g.FillRectangle([System.Drawing.Brushes]::DimGray, $barX, $barY, $barW, 14)
        # เลือดสีขาว (Smooth HP - ไหลตาม)
        $smoothW = ($lucifer.SmoothHP / 20000) * $barW
        $g.FillRectangle([System.Drawing.Brushes]::White, $barX, $barY, $smoothW, 14)
        # เลือดสีแดง (Visual HP - ลดทันที)
        $visualW = ($lucifer.VisualHP / 20000) * $barW
        $g.FillRectangle([System.Drawing.Brushes]::Red, $barX, $barY, $visualW, 14)
        
        # ถ้ามีเกราะ (Armor < 1000 HP) วาดกรอบสีฟ้าครอบ
        if ($lucifer.ArmorHP -gt 0) {
            $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Cyan, 3), ($barX - 2), ($barY - 2), ($barW + 4), 18)
        }
        $g.DrawString("LUCIFER - THE FALLEN", $fontSmall, [System.Drawing.Brushes]::White, $barX, ($barY + 18))
    }

    # --- 4. ระบบ Inventory (Sidebar) ---
    $invY = 430
    $g.DrawString("WEAPON [Q:Swap]", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), $invY)
    if ($inventory.Count -gt 0) {
        $activeType = $inventory[0]
        $count = ($inventory | Where-Object { $_ -eq $activeType }).Count
        $rect = New-Object System.Drawing.Rectangle(($sidebarX + 15), ($invY + 20), 50, 50)
        $activeBrush = if ($activeType -eq "Laser") { [System.Drawing.Brushes]::LimeGreen } elseif ($activeType -eq "Nuke") { [System.Drawing.Brushes]::OrangeRed } else { [System.Drawing.Brushes]::DarkCyan }
        $g.FillRectangle($activeBrush, $rect)
        $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::White, 2), $rect)
        $txt = if ($activeType -eq "Laser") { "L" } elseif ($activeType -eq "Nuke") { "N" } else { "M" }
        $g.DrawString($txt, $fontLarge, [System.Drawing.Brushes]::White, ($sidebarX + 27), ($invY + 31))
        $g.DrawString("x$count", $fontLarge, [System.Drawing.Brushes]::Yellow, ($sidebarX + 70), ($invY + 31))
    }

    # --- 5. Buffs & Debuffs ---
    # (โค้ดส่วน Buffs/Debuffs เดิมของคุณ ปรับตำแหน่ง Y เล็กน้อยถ้าทับกัน)
    $bfY = 200
    $g.DrawString("ACTIVE BUFFS", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), $bfY)
    $bfY += 20
    foreach ($bf in $buffs) {
        if ($bf.Icon -ne "M") {
            $g.FillRectangle([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(100, 0, 255, 255)), ($sidebarX + 15), $bfY, 170, 30)
            $g.DrawString("$($bf.Icon) $($bf.Value)", $fontSmall, [System.Drawing.Brushes]::White, ($sidebarX + 25), ($bfY + 7))
            $bfY += 35
        }
    }

    $dbY = 20
    foreach ($db in $debuffs) {
        $g.FillRectangle([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(200, 60, 0, 0)), 10, $dbY, 100, 45)
        $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Red, 2), 10, $dbY, 100, 45)
        $g.DrawString($db.Icon, $fontLarge, [System.Drawing.Brushes]::White, 15, ($dbY + 8))
        $g.DrawString($db.Value, $fontSmall, [System.Drawing.Brushes]::Yellow, 50, ($dbY + 15))
        $dbY += 50
    }

    # --- 6. Warnings (RealPride & Lucifer) ---
    $realPride = $enemies | Where-Object { $_.GetType().Name -eq "RealPride" } | Select-Object -First 1
    if ($realPride) {
        $fatalFont = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
        $rectFatal = New-Object System.Drawing.Rectangle(($sidebarX + 15), 310, 170, 70)
        $g.FillRectangle([System.Drawing.Brushes]::DarkRed, $rectFatal)
        $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Red, 2), $rectFatal)
        $g.DrawString(">> FATAL ENTITY <<", $fontSmall, [System.Drawing.Brushes]::Yellow, ($sidebarX + 22), 315)
        $remaining = 15 - $realPride.LaserCount
        $g.DrawString("CATACLYSM IN: $remaining", $fatalFont, [System.Drawing.Brushes]::White, ($sidebarX + 25), 345)
    }

    # Lucifer Approach Warning
    if ($Script:luciferWarningTimer -gt 0) {
        if (([math]::Floor($Script:luciferWarningTimer / 10) % 2) -eq 0) {
            $g.Clear([System.Drawing.Color]::DarkRed)
            $f = New-Object System.Drawing.Font("Impact", 30)
            $g.DrawString("!!! WARNING: LUCIFER APPROACHING !!!", $f, [System.Drawing.Brushes]::White, 30, 250)
        }
    }
}

# --- แก้ไขฟังก์ชัน Draw-Gameplay ให้ส่ง $enemies ไปด้วย ---
function Draw-Gameplay ($g, $player, $bullets, $enemies, $enemyBullets, $score, $level, $lives, $targetScore, $buffs, $debuffs, $inventory) {
    # 1. วาดวัตถุ
    $showPlayer = $true
    if ($Script:immortalTimer -gt 0 -and ($Script:immortalTimer % 10) -lt 5) { $showPlayer = $false }
    if ($showPlayer) { $player.Draw($g) }

    foreach ($b in $bullets) { $b.Draw($g) }
    foreach ($e in $enemies) { $e.Draw($g) }
    foreach ($eb in $enemyBullets) { $eb.Draw($g) }

    if ($Script:defenseHits -gt 0) {
        $shieldPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 0, 255, 255), 2)
        $g.DrawEllipse($shieldPen, ($player.X - 10), ($player.Y - 10), 41, 41)
    }

    # 2. วาด HUD (เพิ่มพารามิเตอร์ $enemies)
    Draw-HUD $g $score $level $lives $inventory $buffs $debuffs $targetScore $enemies
}