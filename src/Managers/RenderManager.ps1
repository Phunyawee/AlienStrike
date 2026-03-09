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

# ฟังก์ชันวาด HUD แบบใหม่ (Inventory + Health + Status)
function Draw-HUD ($g, $score, $level, $lives, $inventory, $buffs, $debuffs, $targetScore) {
    $fontSmall = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
    $fontLarge = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
    $sidebarX = 500
    $sidebarWidth = 200

    # --- 1. วาดกรอบ Sidebar ด้านขวา (Semi-Transparent) ---
    $sideBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 20, 20, 25))
    $g.FillRectangle($sideBg, $sidebarX, 0, $sidebarWidth, 600)
    $g.DrawLine([System.Drawing.Pen]::new([System.Drawing.Color]::Cyan, 2), $sidebarX, 0, $sidebarX, 600)

    # --- 2. ข้อมูลผู้เล่น (ใน Sidebar) ---
    $g.DrawString("SCORE", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), 20)
    $g.DrawString("$score", $fontLarge, [System.Drawing.Brushes]::Yellow, ($sidebarX + 15), 35)

    $g.DrawString("LEVEL $level", $fontSmall, [System.Drawing.Brushes]::White, ($sidebarX + 15), 75)
    # Progress Bar (เลเวลอัป)
    $g.FillRectangle([System.Drawing.Brushes]::DarkSlateGray, ($sidebarX + 15), 95, 170, 6)
    $progress = [math]::Min(($score / $targetScore), 1.0)
    $g.FillRectangle([System.Drawing.Brushes]::Lime, ($sidebarX + 15), 95, (170 * $progress), 6)

    # วาดดวงใจ (Health)
    $g.DrawString("LIVES", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), 120)
    for ($l = 0; $l -lt $lives; $l++) {
        $g.FillEllipse([System.Drawing.Brushes]::Red, ($sidebarX + 15 + ($l * 25)), 140, 18, 18)
    }

    # --- ระบบ Inventory Slot (Sidebar) ---
    $invY = 450
    $g.DrawString("WEAPON [Q:Swap]", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), $invY)
    
    # --- ระบบ Inventory Slot (Sidebar) ---
    if ($inventory.Count -gt 0) {
        $activeType = $inventory[0]
        $count = ($inventory | Where-Object { $_ -eq $activeType }).Count
        
        # 1. วาด Slot
        $rect = New-Object System.Drawing.Rectangle(($sidebarX + 15), ($invY + 20), 50, 50)
        
        # [แก้ไข] เพิ่มสีสำหรับ Nuke (OrangeRed)
        $activeBrush = if ($activeType -eq "Laser") { 
            [System.Drawing.Brushes]::LimeGreen 
        } elseif ($activeType -eq "Nuke") { 
            [System.Drawing.Brushes]::OrangeRed # สีสำหรับ Nuke
        } else { 
            [System.Drawing.Brushes]::DarkCyan 
        }

        $g.FillRectangle($activeBrush, $rect)
        $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::White, 2), $rect)
        
        # 2. วาดตัวอักษร (เพิ่มเงื่อนไข N)
        $txt = if ($activeType -eq "Laser") { "L" } elseif ($activeType -eq "Nuke") { "N" } else { "M" }
        $g.DrawString($txt, $fontLarge, [System.Drawing.Brushes]::White, ($sidebarX + 27), ($invY + 31))
        
        # 3. วาดจำนวน xCount
        $g.DrawString("x$count", $fontLarge, [System.Drawing.Brushes]::Yellow, ($sidebarX + 70), ($invY + 31))

        # 4. แสดงประเภทถัดไป (Preview)
        $nextType = $null
        foreach($it in $inventory) { if($it -ne $activeType) { $nextType = $it; break } }
        if ($nextType) {
            $g.DrawString("NEXT: $nextType", $fontSmall, [System.Drawing.Brushes]::Cyan, ($sidebarX + 15), ($invY + 75))
        }
    }

    # --- 4. สถานะ Buffs (ใน Sidebar กลาง) ---
    $bfY = 200
    $g.DrawString("ACTIVE BUFFS", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), $bfY)
    $bfY += 20
    foreach ($bf in $buffs) {
        if ($bf.Icon -ne "M") { # ไม่วาด Missile ซ้ำ
            $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 0, 255, 255))
            $g.FillRectangle($bgBrush, ($sidebarX + 15), $bfY, 170, 30)
            $g.DrawString("$($bf.Icon) $($bf.Value)", $fontSmall, [System.Drawing.Brushes]::White, ($sidebarX + 25), ($bfY + 7))
            $bfY += 35
        }
    }

    # --- 5. สถานะ Debuffs (บนจอ Play Area - เพื่อให้ผู้เล่นตกใจ!) ---
    $dbY = 20 # เริ่มวาดจากด้านบนสุด
    foreach ($db in $debuffs) {
        # พื้นหลังสีแดงเข้มกึ่งโปร่งแสงเพื่อให้ตัวอักษรสีเหลือง/ขาวอ่านง่าย
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 60, 0, 0))
        $g.FillRectangle($bgBrush, 10, $dbY, 100, 45)
        $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Red, 2), 10, $dbY, 100, 45)
        
        # วาดไอคอน (ตัวใหญ่) และ เวลาถอยหลัง (สีเหลือง)
        $g.DrawString($db.Icon, $fontLarge, [System.Drawing.Brushes]::White, 15, ($dbY + 8))
        $g.DrawString($db.Value, $fontSmall, [System.Drawing.Brushes]::Yellow, 50, ($dbY + 15))
        
        $dbY += 50 # เว้นระยะห่างลงมาสำหรับ Debuff ตัวถัดไป
    }
}

# แก้ไขฟังก์ชันหลักให้เรียกใช้ HUD
function Draw-Gameplay ($g, $player, $bullets, $enemies, $enemyBullets, $score, $level, $lives, $targetScore, $buffs, $debuffs, $inventory) {
    # 1. วาดวัตถุในเกม
    $player.Draw($g)
    foreach ($b in $bullets) { $b.Draw($g) }
    foreach ($e in $enemies) { $e.Draw($g) }
    foreach ($eb in $enemyBullets) { $eb.Draw($g) }

     # วาดวงกลมโล่ (ถ้ามีแต้มป้องกัน)
    if ($Script:defenseHits -gt 0) {
        $shieldPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 0, 255, 255), 2)
        # วาดวงกลมครอบยาน (ยานขนาด 21 เราวาดวงกลมขนาด 40)
        $g.DrawEllipse($shieldPen, ($player.X - 10), ($player.Y - 10), 41, 41)
    }

    # 2. วาด HUD ทับด้านบน
    Draw-HUD $g $score $level $lives $inventory $buffs $debuffs $targetScore
}