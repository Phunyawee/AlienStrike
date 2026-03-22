# \src\Managers\RenderManager.ps1

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
# สร้างคลังเก็บฟอนต์และแปรงสี (Cache)
$Global:GameCache = @{
    Fonts = @{
        Small = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        Large = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
        Fatal = New-Object System.Drawing.Font("Impact", 12, [System.Drawing.FontStyle]::Italic)
    }
    Brushes = @{
        Yellow = [System.Drawing.Brushes]::Yellow
        White  = [System.Drawing.Brushes]::White
        Red    = [System.Drawing.Brushes]::Red
        Cyan   = [System.Drawing.Brushes]::Cyan
    }
}
function Draw-Gameplay ($g, $player, $bullets, $enemies, $enemyBullets, $score, $level, $lives, $targetScore, $buffs, $debuffs, $inventory) {
    # --- 1. เริ่มการสั่น (วาดทุกอย่างที่ต้องสั่นในนี้) ---
    $g.TranslateTransform($Script:shakeX, $Script:shakeY)
    
    # วาดพื้นหลัง (ถ้าอยากให้ดาวสั่นด้วย)
    Draw-Background $g 700 600 $level

    # วาดวัตถุในเกม
    $showPlayer = (($Script:immortalTimer -eq 0) -or (($Script:immortalTimer % 10) -lt 5))
    if ($showPlayer) { $player.Draw($g) }

    foreach ($e in $enemies) { $e.Draw($g) }
    foreach ($eb in $enemyBullets) { $eb.Draw($g) }
    foreach ($b in $bullets) { $b.Draw($g) }

    if ($Script:defenseHits -gt 0) {
        $shieldPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 0, 255, 255), 2)
        $g.DrawEllipse($shieldPen, ($player.X - 10), ($player.Y - 10), 41, 41)
    }

    # --- 2. จบการสั่น (คืนค่าพิกัดให้กลับมานิ่ง) ---
    $g.ResetTransform()

    # --- 3. วาดสิ่งที่ต้องการให้นิ่ง (HUD และ Menu) ---
    # วาด HUD (ซึ่งมี Pocket Arsenal อยู่ข้างใน)
    Draw-HUD $g $score $level $lives $inventory $buffs $debuffs $targetScore $enemies

    # วาดเมนูหยุดเกม (เอามาไว้นอก ResetTransform เพื่อให้เมนูนิ่ง อ่านง่าย)
    if ($Script:isPaused) {
        Draw-PauseMenu $g $score 
    }
}
