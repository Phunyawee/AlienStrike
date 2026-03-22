# \src\Managers\RenderModules\ScreenManager.ps1

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
function Draw-Credits ($g, $width, $height) {
    # 1. ถมพื้นหลังสีดำโปร่งแสงทับหน้าจอ
    $overlay = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 0, 0, 0))
    $g.FillRectangle($overlay, 0, 0, $width, $height)

    $titleF = New-Object System.Drawing.Font("Impact", 40, [System.Drawing.FontStyle]::Bold)
    $textF = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
    $center = New-Object System.Drawing.StringFormat; $center.Alignment = "Center"

    # 2. ป้ายประกาศชัยชนะ
    $bannerW = 600
    $bannerH = 120
    $bannerX = ($width - $bannerW) / 2
    $bannerY = 200

    $g.FillRectangle([System.Drawing.Brushes]::DarkBlue, $bannerX, $bannerY, $bannerW, $bannerH)
    $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Gold, 4), $bannerX, $bannerY, $bannerW, $bannerH)
    
    $g.DrawString("LUCIFER DESTROYED", $titleF, [System.Drawing.Brushes]::Yellow, ($width/2), ($bannerY + 15), $center)
    $g.DrawString("THE AGE OF SIN IS OVER", $textF, [System.Drawing.Brushes]::Cyan, ($width/2), ($bannerY + 75), $center)

    # 3. ตัวหนังสือเครดิต
    if ($Script:showCredits) {
        $lines = @(
            "", "", "", "", "", "", "",
            "--- MISSION COMPLETE ---",
            "GALAXY STATUS: RESTORED",
            "",
            "--- CREDITS ---",
            "LEAD ARCHITECT: YOU",
            "SYSTEM ADVISOR: AI ASSISTANT",
            "",
            "--- ENGINE ---",
            "POWERSHELL GAME CORE 4.1",
            "",
            "THANK YOU FOR PLAYING!",
            ""
        )

        $Script:creditY -= 0.7 
        $currentY = $Script:creditY

        foreach ($line in $lines) {
            # แก้ไข operators ที่นี่
            if ($currentY -gt ($bannerY + $bannerH) -or $currentY -lt $bannerY) {
                $brush = if ($line -match "---") { [System.Drawing.Brushes]::Yellow } else { [System.Drawing.Brushes]::White }
                $g.DrawString($line, $textF, $brush, ($width/2), $currentY, $center)
            }
            $currentY += 40
        }

        # 4. ปุ่ม Enter to Continue (กะพริบ)
        if (([DateTime]::Now.Millisecond % 1000) -gt 500) {
            $g.DrawString("- PRESS [ENTER] TO CONTINUE -", $textF, [System.Drawing.Brushes]::Lime, ($width/2), 540, $center)
        }
    }
}
function Draw-Menu ($g, $width, $height) {
    # 1. เตรียม Font แบบระบุสเปคชัดเจน (ห้ามใช้เลขลัด)
    $titleF = New-Object System.Drawing.Font("Impact", 45)
    $menuF  = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
    $smallF = New-Object System.Drawing.Font("Arial", 10)
    $hintF  = New-Object System.Drawing.Font("Arial", 9)
    $center = New-Object System.Drawing.StringFormat; $center.Alignment = "Center"
    
    # 2. วาดชื่อเกมและหัวข้อ
    $g.DrawString("ALIEN STRIKE", $titleF, [System.Drawing.Brushes]::Cyan, [float]($width/2), 100.0, $center)
    
    # --- [แก้ไข] ขยับลงมาที่ 185.0 (เดิม 160.0) เพื่อให้มีช่องไฟ ---
    $stateText = if ($Script:menuState -eq "SIM") { "LABORATORY: TARGET SELECTION" } else { $Script:menuState }
    $g.DrawString($stateText, $smallF, [System.Drawing.Brushes]::Gray, [float]($width/2), 185.0, $center)

    # --- [แก้ไข] ขยับจุดเริ่มเมนูลงมาอีกนิดเป็น 280.0 (เดิม 250.0) ---
    $startY = 280.0
    
    # 3. เลือกรายการเมนู
    $items = switch ($Script:menuState) {
        "MAIN"   { $Script:mainMenuItems }
        "STORY"  { $Script:storyItems }
        "BATTLE" { $Script:battleItems }
        "SIM"    { $Script:simItems }
        default  { $Script:mainMenuItems }
    }

    # --- ลอจิกการทำ Scrolling (แสดงแค่ 6 บรรทัด) ---
    $maxVisible = 6
    $startY = 250.0
    $spacing = 45.0
    
    $viewStart = 0
    if ($Script:menuIndex -ge $maxVisible) {
        $viewStart = $Script:menuIndex - ($maxVisible - 1)
    }
    $viewEnd = [math]::Min($viewStart + $maxVisible - 1, $items.Count - 1)

    # 4. วาดรายการที่อยู่ในขอบเขตการมองเห็น
    $drawCount = 0
    for ($i = $viewStart; $i -le $viewEnd; $i++) {
        $isHovered = ($i -eq $Script:menuIndex)
        $color = if ($isHovered) { [System.Drawing.Brushes]::Yellow } else { [System.Drawing.Brushes]::White }
        $currentY = [float]($startY + ($drawCount * $spacing))

        if ($isHovered) {
            $g.DrawString(">", $menuF, [System.Drawing.Brushes]::Lime, [float]($width/2 - 160), $currentY)
        }

        $g.DrawString($items[$i], $menuF, $color, [float]($width/2), $currentY, $center)
        $drawCount++
    }

    # 5. วาดสัญลักษณ์บอกว่ามีรายการเหลือ (บน/ล่าง) ด้วยรูปทรงสามเหลี่ยม
    $cx = [float]($width / 2.0)
    $indicatorBrush = [System.Drawing.Brushes]::Gray

    if ($viewStart -gt 0) { 
        # วาดสามเหลี่ยมชี้ขึ้น
        $upPts = [System.Drawing.PointF[]]::new(3)
        $upPts[0] = New-Object System.Drawing.PointF($cx, [float]($startY - 35.0))
        $upPts[1] = New-Object System.Drawing.PointF([float]($cx - 10), [float]($startY - 20.0))
        $upPts[2] = New-Object System.Drawing.PointF([float]($cx + 10), [float]($startY - 20.0))
        $g.FillPolygon($indicatorBrush, $upPts)
    }
    
    if ($viewEnd -lt ($items.Count - 1)) { 
        # วาดสามเหลี่ยมชี้ลง
        $downY = [float]($startY + ($maxVisible * $spacing) + 10.0)
        $downPts = [System.Drawing.PointF[]]::new(3)
        $downPts[0] = New-Object System.Drawing.PointF([float]($cx - 10), $downY)
        $downPts[1] = New-Object System.Drawing.PointF([float]($cx + 10), $downY)
        $downPts[2] = New-Object System.Drawing.PointF($cx, [float]($downY + 15.0))
        $g.FillPolygon($indicatorBrush, $downPts)
    }

    $g.DrawString("[W/S] Scroll  [ENTER] Select", $hintF, [System.Drawing.Brushes]::Gray, [float]($width/2), 560.0, $center)
}
function Draw-PauseMenu ($g, $width, $height) {
    # 1. ถมสีดำโปร่งแสงทับสนามรบ
    $overlay = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 0, 0, 0))
    $g.FillRectangle($overlay, 0, 0, 500, 600) # บังเฉพาะ Play Area

    $pauseF = New-Object System.Drawing.Font("Impact", 30)
    $itemF = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
    $center = New-Object System.Drawing.StringFormat; $center.Alignment = "Center"

    # 2. วาดคำว่า PAUSED
    $g.DrawString("PAUSED", $pauseF, [System.Drawing.Brushes]::White, 250, 200, $center)

    # 3. วาดรายการเมนู
    for ($i = 0; $i -lt $Script:pauseItems.Count; $i++) {
        $color = if ($i -eq $Script:pauseIndex) { [System.Drawing.Brushes]::Yellow } else { [System.Drawing.Brushes]::Gray }
        $text = $Script:pauseItems[$i]
        
        if ($i -eq $Script:pauseIndex) {
            $g.DrawString(">", $itemF, [System.Drawing.Brushes]::Lime, 150, (300 + ($i * 40)))
        }
        $g.DrawString($text, $itemF, $color, 250, (300 + ($i * 40)), $center)
    }
}