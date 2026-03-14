
# AlienStrike\src\Managers\RenderModules\EnvironmentEngine.ps1
# --- ระบบพื้นหลังอวกาศ (v4.1.1: Saturn & X-Rings Edition) ---
function Draw-Background ($g, $width, $height, $level) {
    # 1. วาดดวงดาว (Starfield)
    $t = [DateTime]::Now.Ticks / 1000000
    for ($i = 0; $i -lt 40; $i++) {
        $speedMult = 1 + ($i % 3) 
        $sx = ($i * 123.45) % 500
        $sy = ($i * 150 + $t * $speedMult) % 600
        $g.FillEllipse([System.Drawing.Brushes]::White, [float]$sx, [float]$sy, 1.0, 1.0)
    }

    # 2. ระบบดาวเคราะห์ (สุ่มเกิดทุก 10 เลเวล)
    if ($level -gt 0 -and $level % 10 -eq 0 -and $Script:planets.Count -eq 0) {
        $pColors = @([System.Drawing.Color]::DarkSlateBlue, [System.Drawing.Color]::Sienna, [System.Drawing.Color]::FromArgb(60, 40, 80))
        $newPlanet = [PSCustomObject]@{
            X = [float]($Script:rnd.Next(50, 300))
            Y = -350.0
            Size = [float]($Script:rnd.Next(120, 180))
            Color = $pColors[$Script:rnd.Next(0, $pColors.Count)]
            # สุ่มประเภท: 0=ปกติ, 1=ดาวเสาร์ (1 วง), 2=X-Rings (2 วงไขว้)
            Type = $Script:rnd.Next(0, 3) 
        }
        [void]$Script:planets.Add($newPlanet)
    }

    # 3. วาดและเคลื่อนที่ดาวเคราะห์
    for ($idx = $Script:planets.Count - 1; $idx -ge 0; $idx--) {
        $p = $Script:planets[$idx]
        $p.Y += 0.25 
        
        $pBrush = New-Object System.Drawing.SolidBrush($p.Color)
        $ringPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 200, 200, 255), 4) # วงแหวนสีใสๆ

        # --- วาดส่วนหลังของวงแหวน (เพื่อให้ดาวทับ) ---
        if ($p.Type -eq 1) { # แบบดาวเสาร์ (วงเดียว)
            $g.DrawArc($ringPen, ($p.X - 30), ($p.Y + $p.Size/3), ($p.Size + 60), ($p.Size/3), 180, 180)
        }
        elseif ($p.Type -eq 2) { # แบบ X-Rings (วงที่ 1)
            $g.DrawEllipse($ringPen, ($p.X - 20), ($p.Y + 10), ($p.Size + 40), ($p.Size - 20))
        }

        # --- วาดตัวดาวเคราะห์ ---
        $g.FillEllipse($pBrush, $p.X, $p.Y, $p.Size, $p.Size)
        
        # วาดแสงเงาไล่เฉด
        $shadowBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.RectangleF($p.X, $p.Y, $p.Size, $p.Size)),
            [System.Drawing.Color]::FromArgb(80, 255, 255, 255),
            [System.Drawing.Color]::FromArgb(200, 0, 0, 0),
            45.0
        )
        $g.FillEllipse($shadowBrush, $p.X, $p.Y, $p.Size, $p.Size)

        # --- วาดส่วนหน้าของวงแหวน (เพื่อให้ทับดาว) ---
        if ($p.Type -eq 1) {
            $g.DrawArc($ringPen, ($p.X - 30), ($p.Y + $p.Size/3), ($p.Size + 60), ($p.Size/3), 0, 180)
        }
        elseif ($p.Type -eq 2) { # แบบ X-Rings (วงที่ 2 ไขว้กัน)
            $g.DrawEllipse($ringPen, ($p.X + 10), ($p.Y - 20), ($p.Size - 20), ($p.Size + 40))
        }

        if ($p.Y -gt 700) { $Script:planets.RemoveAt($idx) }
    }
}
