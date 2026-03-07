# AlienStrike\src\RenderManager.ps1

Add-Type -AssemblyName System.Drawing

# --- Helper: Settings (Font/Brush) ---
# ประกาศตัวแปร Font ไว้ข้างนอก เพื่อไม่ต้อง New-Object ทุกเฟรม (ช่วยลดอาการกระตุก)
$Global:GameFonts = @{
    Title   = New-Object System.Drawing.Font("Impact", 36)
    Header  = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
    Text    = New-Object System.Drawing.Font("Consolas", 12)
    BigText = New-Object System.Drawing.Font("Arial", 28, [System.Drawing.FontStyle]::Bold)
    SubText = New-Object System.Drawing.Font("Arial", 14)
    Small   = New-Object System.Drawing.Font("Arial", 10)
    HUD     = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
}

function Draw-StartScreen ($g, $width, $height) {
    $center = New-Object System.Drawing.StringFormat
    $center.Alignment = "Center"
    
    $g.DrawString("ALIEN STRIKE", $Global:GameFonts.BigText, [System.Drawing.Brushes]::Cyan, ($width/2), 180, $center)
    $g.DrawString("Press ENTER to Start", $Global:GameFonts.SubText, [System.Drawing.Brushes]::Yellow, ($width/2), 280, $center)
    $g.DrawString("[ L ] View Leaderboard", $Global:GameFonts.Small, [System.Drawing.Brushes]::LightGray, ($width/2), 320, $center)
}

function Draw-Leaderboard ($g, $width, $height) {
    # เพื่อประสิทธิภาพ เราจะเรียก Get-HighScores จากไฟล์หลักแล้วส่งมา หรือเรียกที่นี่ก็ได้
    # แต่ในที่นี้ขอเรียกผ่าน HighScoreManager ที่เราทำไว้ก่อนหน้านี้
    $scores = try { Get-HighScores } catch { @() }

    $center = New-Object System.Drawing.StringFormat; $center.Alignment = "Center"
    $right  = New-Object System.Drawing.StringFormat; $right.Alignment = "Far"

    # Title
    $g.DrawString("HALL OF FAME", $Global:GameFonts.Title, [System.Drawing.Brushes]::Gold, ($width/2), 30, $center)
    $g.DrawLine([System.Drawing.Pens]::DimGray, 50, 100, ($width-50), 100)

    # Headers
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

            # Color Logic
            if ($rank -eq 1) { $brush = [System.Drawing.Brushes]::Gold }
            elseif ($rank -eq 2) { $brush = [System.Drawing.Brushes]::Silver }
            elseif ($rank -eq 3) { $brush = [System.Drawing.Brushes]::SandyBrown }
            else { $brush = [System.Drawing.Brushes]::White }

            # Data Safe Check
            $pName = if ($s.Name) { $s.Name } else { "Unknown" }
            $pLevel = if ($s.Level) { "$($s.Level)" } else { "1" }
            $rawScore = if ($s.Score -and $s.Score -is [ValueType]) { $s.Score } else { 0 }
            $pScore = "{0:N0}" -f $rawScore

            # Draw Row
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

function Draw-Gameplay ($g, $player, $bullets, $enemies, $enemyBullets, $score, $level, $lives, $targetScore) {
    # --- 1. Draw Entities (วาดวัตถุในเกมปกติ) ---
    if ($null -ne $player) { $player.Draw($g) }
    
    if ($null -ne $bullets) { foreach ($b in $bullets) { if($b){$b.Draw($g)} } }
    if ($null -ne $enemies) { foreach ($e in $enemies) { if($e){$e.Draw($g)} } }
    if ($null -ne $enemyBullets) { foreach ($eb in $enemyBullets) { if($eb){$eb.Draw($g)} } }

    # --- 2. Draw Sidebar Background (วาดพื้นหลังแถบ UI ด้านขวา) ---
    # สร้างกรอบสี่เหลี่ยมสีเทาเข้ม ทับพื้นที่ตั้งแต่ X=500 ถึง 700
    $sidebarBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 30, 40))
    $g.FillRectangle($sidebarBrush, 500, 0, 200, 600)
    
    # วาดเส้นขอบสีขาวกั้นระหว่างพื้นที่เกมกับ UI
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 2)
    $g.DrawLine($pen, 500, 0, 500, 600)

    # --- 3. Draw HUD Data (วาดตัวหนังสือใน Sidebar) ---
    # ใช้ Font เดิมของคุณ แต่เล่นสีให้ดูน่าสนใจขึ้น
    $font = $Global:GameFonts.HUD
    
    # LEVEL
    $g.DrawString("LEVEL", $font, [System.Drawing.Brushes]::Cyan, 520, 30)
    $g.DrawString([string]$level, $font, [System.Drawing.Brushes]::White, 520, 60)

    # SCORE
    $g.DrawString("SCORE", $font, [System.Drawing.Brushes]::Yellow, 520, 110)
    $g.DrawString([string]$score, $font, [System.Drawing.Brushes]::White, 520, 140)

    # NEXT LEVEL (คะแนนเป้าหมาย)
    $g.DrawString("NEXT LVL", $font, [System.Drawing.Brushes]::Orange, 520, 190)
    $g.DrawString([string]$targetScore, $font, [System.Drawing.Brushes]::White, 520, 220)

    # LIVES (จำนวนชีวิต)
    $g.DrawString("LIVES", $font, [System.Drawing.Brushes]::LightGreen, 520, 280)
    # ใช้สัญลักษณ์หัวใจ หรือเปลี่ยนเป็นตัว "O" หรือ "A" ก็ได้ถ้าระบบไม่รองรับ Emoji
    $livesText = "A " * $lives 
    $g.DrawString($livesText, $font, [System.Drawing.Brushes]::Red, 520, 310)
    
    # คำใบ้ควบคุม (แถมให้ ผู้เล่นจะได้รู้ว่ากดอะไรได้บ้าง)
    $smallFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
    $g.DrawString("CONTROLS:", $smallFont, [System.Drawing.Brushes]::Gray, 520, 500)
    $g.DrawString("A D / Arrow = Move", $smallFont, [System.Drawing.Brushes]::Gray, 520, 520)
    $g.DrawString("W / Space = Shoot", $smallFont, [System.Drawing.Brushes]::Gray, 520, 540)
}