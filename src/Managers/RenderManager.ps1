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

# สังเกตว่าผมเพิ่มพารามิเตอร์ $buffs และ $debuffs ไว้ท้ายสุด (เผื่ออนาคตส่งข้อมูลจริงมาได้)
function Draw-Gameplay ($g, $player, $bullets, $enemies, $enemyBullets, $score, $level, $lives, $targetScore, $buffs, $debuffs) {
    
    # --- 1. Draw Entities ---
    if ($null -ne $player) { $player.Draw($g) }
    if ($null -ne $bullets) { foreach ($b in $bullets) { if($b){$b.Draw($g)} } }
    if ($null -ne $enemies) { foreach ($e in $enemies) { if($e){$e.Draw($g)} } }
    if ($null -ne $enemyBullets) { foreach ($eb in $enemyBullets) { if($eb){$eb.Draw($g)} } }

    # --- 2. Draw Sidebar Background ---
    $sidebarBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 30, 40))
    $g.FillRectangle($sidebarBrush, 500, 0, 200, 600)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 2)
    $g.DrawLine($pen, 500, 0, 500, 600)

    # --- 3. Draw HUD Data ---
    $font = $Global:GameFonts.HUD
    
    $g.DrawString("LEVEL", $font, [System.Drawing.Brushes]::Cyan, 520, 20)
    $g.DrawString([string]$level, $font,[System.Drawing.Brushes]::White, 520, 45)

    $g.DrawString("SCORE", $font, [System.Drawing.Brushes]::Yellow, 520, 90)
    $g.DrawString([string]$score, $font,[System.Drawing.Brushes]::White, 520, 115)

    $g.DrawString("NEXT LVL", $font, [System.Drawing.Brushes]::Orange, 520, 160)
    $g.DrawString([string]$targetScore, $font, [System.Drawing.Brushes]::White, 520, 185)

    $g.DrawString("LIVES", $font, [System.Drawing.Brushes]::LightGreen, 520, 230)
    $livesText = "A " * $lives 
    $g.DrawString($livesText, $font, [System.Drawing.Brushes]::Red, 520, 255)

    # =========================================================
    # --- 4. Draw Buffs & Debuffs (Max 5 Each) ---
    # =========================================================
    $startX = 520
    $boxSize = 28
    $spacing = 34

    # [DEBUG] โชว์ให้เห็นจะๆ ว่าของส่งมาถึงหน้าวาดรูปจริงๆ
    # Write-Host "DRAW FUNC -> Buffs: $buffs | Debuffs: $debuffs"

    # --- BUFFS SECTION ---
    $g.DrawString("BUFFS", $Global:GameFonts.Small,[System.Drawing.Brushes]::LimeGreen, 520, 310)
    $startY = 330
    
    $bCount = 0
    if ($buffs) {
        foreach ($b in $buffs) {
            $x = $startX + ($bCount * $spacing)
            
            $boxRect = New-Object System.Drawing.Rectangle($x, $startY, $boxSize, $boxSize)
            $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 60, 20))), $boxRect)
            $g.DrawRectangle([System.Drawing.Pens]::LimeGreen, $boxRect)

            $g.DrawString($b.Icon, $Global:GameFonts.Icon, $b.Color, ($x + 4), ($startY + 4))
            $g.DrawString($b.Value, $Global:GameFonts.Tiny, [System.Drawing.Brushes]::White, ($x + 12), ($startY + 16))
            
            $bCount++
            if ($bCount -ge 5) { break } # วาดสูงสุดแค่ 5 อัน
        }
    }

    # --- DEBUFFS SECTION ---
    $g.DrawString("DEBUFFS", $Global:GameFonts.Small,[System.Drawing.Brushes]::OrangeRed, 520, 380)
    $startY = 400
    
    $dCount = 0
    if ($debuffs) {
        foreach ($d in $debuffs) {
            $x = $startX + ($dCount * $spacing)
            
            $boxRect = New-Object System.Drawing.Rectangle($x, $startY, $boxSize, $boxSize)
            $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 20, 20))), $boxRect)
            $g.DrawRectangle([System.Drawing.Pens]::Red, $boxRect)

            # แกะค่ามาวาดตรงๆ ไม่ต้องสนเรื่อง .Count
            $g.DrawString($d.Icon, $Global:GameFonts.Icon, $d.Color, ($x + 4), ($startY + 4))
            $g.DrawString($d.Value, $Global:GameFonts.Tiny, [System.Drawing.Brushes]::White, ($x + 6), ($startY + 16))
            
            $dCount++
            if ($dCount -eq 5) { 
                $startY += 35 # ปัดลงมาบรรทัดล่าง
                $dCount = 0   # เริ่มวาดกล่องใหม่ชิดซ้าย
            }
        }
    }
    # --- 5. Controls Hint ---
    $g.DrawString("CONTROLS:", $Global:GameFonts.Small, [System.Drawing.Brushes]::Gray, 520, 480)
    $g.DrawString("A D / Arrow = Move", $Global:GameFonts.Small,[System.Drawing.Brushes]::Gray, 520, 500)
    $g.DrawString("W/Space/Up  = Shoot", $Global:GameFonts.Small,[System.Drawing.Brushes]::Gray, 520, 520)
    $g.DrawString("ESC         = Pause", $Global:GameFonts.Small, [System.Drawing.Brushes]::Gray, 520, 540)

}