# AlienStrike\src\Managers\RenderModules\UserInterface.ps1
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
    
    # เช็คกันหารด้วยศูนย์ (Divide by zero protection)
    if ($null -ne $targetScore -and $targetScore -gt 0) {
        $progress = [math]::Min(($score / $targetScore), 1.0)
        $g.FillRectangle([System.Drawing.Brushes]::Lime, ($sidebarX + 15), 95, (170 * $progress), 6)
    }

    $g.FillRectangle([System.Drawing.Brushes]::Lime, ($sidebarX + 15), 95, (170 * $progress), 6)

    $g.DrawString("LIVES", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), 115)
    for ($l = 0; $l -lt $lives; $l++) {
        $g.FillEllipse([System.Drawing.Brushes]::Red, ($sidebarX + 15 + ($l * 25)), 135, 18, 18)
    }

    # --- เพิ่มส่วนบอก MODE (ใน Sidebar) ---
    $g.DrawString("GAME MODE", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), 170)
    
    $modeText = switch ($Script:gameMode) {
        "Chapter1"    { "STORY: CH 1" }
        "Endless"     { "ENDLESS" }
        "1v1_Lucifer" { "BOSS RUSH" }
        default       { $Script:gameMode }
    }
    
    # วาดชื่อโหมดเป็นสีเขียว Lime
    $g.DrawString($modeText, $fontSmall, [System.Drawing.Brushes]::Lime, ($sidebarX + 15), 185)

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
            # คำนวณความกว้างหลอดฟ้า (เต็มที่ 1000)
            $armorW = ($lucifer.ArmorHP / 1000) * $barW
            # วาดหลอดสีฟ้าสว่าง
            $g.FillRectangle([System.Drawing.Brushes]::DeepSkyBlue, $barX, $barY, $armorW, 14)
            # วาดกรอบสี Cyan ให้รู้ว่าเป็นเกราะพิเศษ
            $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Cyan, 2), $barX, $barY, $barW, 14)
            
            $g.DrawString("ARMOR ACTIVE", $fontSmall, [System.Drawing.Brushes]::Cyan, $barX + 150, $barY + 18)
        }
        $g.DrawString("LUCIFER - THE FALLEN", $fontSmall, [System.Drawing.Brushes]::White, $barX, ($barY + 18))
    }

    # --- 4. ระบบ Inventory (Sidebar) ---
    # --- [ส่วนที่ 1: เพิ่มช่องไฟ Inventory] ---
    $invY = 500  
    $g.DrawString("POCKET ARSENAL [Q]", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), ($invY - 20))
    
    if ($inventory.Count -gt 0) {
        $uniqueQueue = @()
        foreach ($item in $inventory) {
            if ($uniqueQueue.Count -lt 3 -and $item -notin $uniqueQueue) { $uniqueQueue += $item }
        }

        for ($i = 0; $i -lt 3; $i++) {
            $slotSize = if ($i -eq 0) { 50 } else { 38 } 
            
            # --- ปรับระยะห่างตรงนี้ ($i * 65) เพื่อเพิ่มช่องไฟ ---
            $posX = $sidebarX + 15 + ($i * 62) 
            $posY = if ($i -eq 0) { $invY } else { $invY + 6 } 

            if ($i -lt $uniqueQueue.Count) {
                # ... (โค้ดวาดสีอาวุธเหมือนเดิม) ...
                $type = $uniqueQueue[$i]
                $count = ($inventory | Where-Object { $_ -eq $type }).Count
                $colorName = switch($type) { "Laser"{"LimeGreen"}; "Nuke"{"OrangeRed"}; "HolyBomb"{"White"}; default{"DarkCyan"} }
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
                
                $txt = $type.Substring(0,1); $f = if($i -eq 0){$fontLarge} else {$fontSmall}
                $g.DrawString($txt, $f, [System.Drawing.Brushes]::Black, ($posX + ($slotSize/4)), ($posY + ($slotSize/6)))
                $g.DrawString($count.ToString(), $Global:GameFonts.Tiny, [System.Drawing.Brushes]::Yellow, ($posX + $slotSize - 18), ($posY + $slotSize - 15))
            } else {
                # วาดช่องว่าง
                $pEmpty = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(50, 255, 255, 255), 1)
                $g.DrawRectangle($pEmpty, $posX, $posY, $slotSize, $slotSize)
            }
        }
    }

    # --- [ส่วนที่ 2: กรองอาวุธออกจากช่อง ACTIVE BUFFS] ---
    $bfY = 200
    $g.DrawString("ACTIVE BUFFS", $fontSmall, [System.Drawing.Brushes]::Gray, ($sidebarX + 15), $bfY)
    $bfY += 20
    foreach ($bf in $buffs) {
        # กรองไอคอนอาวุธ (M, L, N, H) ออกจากรายการ Buffs
        if ($bf.Icon -notin @("M", "L", "N", "H")) {
            $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 0, 255, 255))
            $g.FillRectangle($bgBrush, ($sidebarX + 15), $bfY, 170, 30)
            $g.DrawString("$($bf.Icon) $($bf.Value)", $fontSmall, [System.Drawing.Brushes]::White, ($sidebarX + 25), ($bfY + 7))
            $bfY += 35
        }
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
        # 180 เฟรม = 3 วินาที. หาร 60 เพื่อดูว่าอยู่คิววินาทีที่เท่าไหร่
        # ใน 1 วินาที (60 เฟรม) ให้โชว์แค่ 30 เฟรมแรกเพื่อให้เกิดการกะพริบ (Flash)
        if (($Script:luciferWarningTimer % 60) -gt 30) {
            $warnFont = New-Object System.Drawing.Font("Impact", 24)
            $warnRect = New-Object System.Drawing.Rectangle(50, 250, 400, 70)
            
            # วาดพื้นหลังป้ายเตือน
            $g.FillRectangle([System.Drawing.Brushes]::DarkRed, $warnRect)
            $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Red, 3), $warnRect)
            
            # วาดข้อความ
            $g.DrawString("!!! LUCIFER APPROACHING !!!", $warnFont, [System.Drawing.Brushes]::Yellow, 65, 265)
        }
    }
}

