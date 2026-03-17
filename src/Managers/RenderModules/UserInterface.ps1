# AlienStrike\src\Managers\RenderModules\UserInterface.ps1

function Draw-HUD ($g, $score, $level, $lives, $inventory, $buffs, $debuffs, $targetScore, $enemies) {
    $fontSmall = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
    $fontLarge = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
    $sidebarX = 500
    $sidebarWidth = 200

    # --- 1. วาดกรอบ Sidebar ---
    $sideBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 20, 20, 25))
    $g.FillRectangle($sideBg, $sidebarX, 0, $sidebarWidth, 600)
    $g.DrawLine([System.Drawing.Pen]::new([System.Drawing.Color]::Cyan, 2), $sidebarX, 0, $sidebarX, 600)

    # --- 2. ข้อมูล Score / Level / Lives ---
    $g.DrawString("SCORE", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), 20)
    
    # [แก้ไข] ถ้าเป็นโหมด SIM ให้ขึ้น N/A
    $scoreDisplay = if ($Script:gameMode -eq "Simulation") { "N/A" } else { $score.ToString("N0") }
    $g.DrawString($scoreDisplay, $fontLarge, [System.Drawing.Brushes]::Yellow, ($sidebarX + 15), 35)

    # ปรับหลอด Progress ให้เป็น 0 ตลอดในโหมด SIM
    $progress = if ($Script:gameMode -eq "Simulation") { 0 } else { [math]::Min(($score / $targetScore), 1.0) }
    $g.FillRectangle([System.Drawing.Brushes]::Lime, ($sidebarX + 15), 95, (170 * $progress), 6)
    if ($null -ne $targetScore -and $targetScore -gt 0) {
        $progress = [math]::Min(($score / $targetScore), 1.0)
        $g.FillRectangle([System.Drawing.Brushes]::Lime, ($sidebarX + 15), 95, (170 * $progress), 6)
    }

    $g.DrawString("LIVES", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), 115)
    for ($l = 0; $l -lt $lives; $l++) {
        $g.FillEllipse([System.Drawing.Brushes]::Red, ($sidebarX + 15 + ($l * 25)), 135, 18, 18)
    }

    # --- 3. GAME MODE Display ---
    $g.DrawString("GAME MODE", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), 170)
    $modeText = switch ($Script:gameMode) {
        "Chapter1"    { "STORY: CH 1" }
        "Chapter2"    { "STORY: CH 2" }
        "Endless"     { "ENDLESS" }
        "1v1_LUCIFER" { "DUEL: LUCIFER" }
        default       { $Script:gameMode }
    }
    $g.DrawString($modeText, $fontSmall, [System.Drawing.Brushes]::Lime, ($sidebarX + 15), 185)

    # --- วาดบอสบาร์ของ LUCIFER (ปรับปรุงใหม่) ---
    $lucifer = $enemies | Where-Object { $_.GetType().Name -eq "Lucifer" } | Select-Object -First 1
    if ($lucifer) {
        $barX = 50; $barY = 15; $barW = 400
        $g.FillRectangle([System.Drawing.Brushes]::DimGray, $barX, $barY, $barW, 14)
        
        # หลอดเลือดขาว (Smooth) และแดง (Visual)
        $smoothW = [float](($lucifer.SmoothHP / 20000.0) * $barW)
        $g.FillRectangle([System.Drawing.Brushes]::White, $barX, $barY, $smoothW, 14.0)
        $visualW = [float](($lucifer.VisualHP / 20000.0) * $barW)
        $g.FillRectangle([System.Drawing.Brushes]::Red, $barX, $barY, $visualW, 14.0)
        
        # --- [NEW] วาดเกราะ Armor (ถ้าทำงานอยู่) ---
        if ($lucifer.ArmorHP -gt 0) {
            $armorW = [float](($lucifer.ArmorHP / 1000.0) * $barW)
            
            # เปลี่ยนจาก OrangeRed เป็น Cyan หรือ DeepSkyBlue (สีฟ้าสว่าง)
            $g.FillRectangle([System.Drawing.Brushes]::DeepSkyBlue, $barX, $barY, $armorW, 14.0)
            
            # เปลี่ยนขอบจาก Red เป็น Blue หรือ White เพื่อให้ตัดกัน
            $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Cyan, 2), $barX, $barY, $barW, 14.0)
            
            # เปลี่ยนสีข้อความเตือนเป็นสีฟ้า
            $g.DrawString("!!! ARMOR ACTIVE !!!", $fontSmall, [System.Drawing.Brushes]::Cyan, ($barX + 130), ($barY + 18))
        }
        # --- [กู้คืน] วาดชื่อบอส ---
        $g.DrawString("LUCIFER - THE FALLEN KING", $fontSmall, [System.Drawing.Brushes]::White, $barX, ($barY + 18))
    }
    
    # --- 5. POCKET ARSENAL (แนวนอน 3-Slot) ---
    $invY = 500  
    $g.DrawString("POCKET ARSENAL [Q]", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), ($invY - 20))
    
    if ($inventory.Count -gt 0) {
        $uniqueQueue = @()
        foreach ($item in $inventory) {
            if ($uniqueQueue.Count -lt 3 -and $item -notin $uniqueQueue) { $uniqueQueue += $item }
        }

        for ($i = 0; $i -lt 3; $i++) {
            $slotSize = if ($i -eq 0) { 50 } else { 38 } 
            $posX = $sidebarX + 15 + ($i * 62) 
            $posY = if ($i -eq 0) { $invY } else { $invY + 6 } 

            if ($i -lt $uniqueQueue.Count) {
                $type = $uniqueQueue[$i]
                $count = ($inventory | Where-Object { $_ -eq $type }).Count
                
                # --- [NEW] กำหนดสีตามประเภทอาวุธ ---
                $colorName = switch($type) { 
                    "Laser"    { "LimeGreen" }
                    "Nuke"     { "OrangeRed" }
                    "HolyBomb" { "White" }
                    "Homing"   { "Yellow" }
                    default    { "DarkCyan" }
                }
                # --- [NEW] กำหนดตัวอักษรไอคอน ---
                $txt = switch($type) {
                    "Laser"    { "L" }
                    "Nuke"     { "N" }
                    "HolyBomb" { "H" }
                    "Homing"   { "T" } # ใช้ T (Tracker)
                    default    { "M" }
                }

                $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromName($colorName))
                $rect = New-Object System.Drawing.Rectangle($posX, $posY, $slotSize, $slotSize)
                $g.FillRectangle($brush, $rect)

                if ($i -eq 0) {
                    $p = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 3)
                    $g.DrawRectangle($p, $rect)
                    $g.DrawString("[E]", $fontSmall, [System.Drawing.Brushes]::Lime, $posX + 12, ($posY + $slotSize + 2))
                } else {
                    $g.DrawRectangle([System.Drawing.Pens]::Gray, $rect)
                }
                
                $f = if($i -eq 0){$fontLarge} else {$fontSmall}
                $g.DrawString($txt, $f, [System.Drawing.Brushes]::Black, ($posX + ($slotSize/4)), ($posY + ($slotSize/6)))
                # --- [แก้ไข] วาดเลขจำนวนเป็นสีดำ (มุมขวาล่างของกรอบ) ---
                $g.DrawString($count.ToString(), $Global:GameFonts.Tiny, [System.Drawing.Brushes]::Black, ($posX + $slotSize - 16), ($posY + $slotSize - 14))
            } else {
                $pEmpty = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(50, 255, 255, 255), 1)
                $g.DrawRectangle($pEmpty, $posX, $posY, $slotSize, $slotSize)
            }
        }
    }

    # --- 6. ACTIVE BUFFS (กรองอาวุธออก) ---
    $bfY = 210
    $g.DrawString("ACTIVE BUFFS", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), $bfY)
    $bfY += 20
    foreach ($bf in $buffs) {
        # กรองไอคอนอาวุธ (M, L, N, H, T) ออกจากรายการ Buffs
        if ($bf.Icon -notin @("M", "L", "N", "H", "T")) {
            $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 0, 255, 255))
            $g.FillRectangle($bgBrush, ($sidebarX + 15), $bfY, 170, 30)
            $g.DrawString("$($bf.Icon) $($bf.Value)", $fontSmall, [System.Drawing.Brushes]::White, ($sidebarX + 25), ($bfY + 7))
            $bfY += 35
        }
    }

    # --- 7. DEBUFFS (ซ้ายบน) ---
    $dbY = 20
    foreach ($db in $debuffs) {
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 60, 0, 0))
        $g.FillRectangle($bgBrush, 10, $dbY, 100, 45)
        $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Red, 2), 10, $dbY, 100, 45)
        $g.DrawString($db.Icon, $fontLarge, [System.Drawing.Brushes]::White, 15, ($dbY + 8))
        $g.DrawString($db.Value, $fontSmall, [System.Drawing.Brushes]::Yellow, 50, ($dbY + 15))
        $dbY += 50
    }

    # --- 8. REALPRIDE WARNING ---
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

    # --- 9. LUCIFER WARNING ---
    if ($Script:luciferWarningTimer -gt 0 -and ($Script:luciferWarningTimer % 60) -gt 30) {
        $warnFont = New-Object System.Drawing.Font("Impact", 24)
        $warnRect = New-Object System.Drawing.Rectangle(50, 250, 400, 70)
        $g.FillRectangle([System.Drawing.Brushes]::DarkRed, $warnRect)
        $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Red, 3), $warnRect)
        $g.DrawString("!!! LUCIFER APPROACHING !!!", $warnFont, [System.Drawing.Brushes]::Yellow, 65, 265)
    }
}