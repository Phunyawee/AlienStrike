class Lucifer : BaseEnemy {
    [float]$VisualHP; [float]$SmoothHP
    [int]$ArmorHP = 0
    [float]$ChargeTimer = 0
    [int]$SummonTimer = 0
    [System.Collections.ArrayList]$Parts
    [int]$Phase = 0 # 0: Side Cannons, 1: Top Turrets, 2: Core
    hidden [Object]$PlayerRef

    Lucifer([float]$x, [float]$y, [Object]$player) 
        : base($x, $y, 100, 100, 1, 20000, [System.Drawing.Color]::BlueViolet) {
        $this.PlayerRef = $player
        $this.VisualHP = 20000; $this.SmoothHP = 20000
        $this.Parts = [System.Collections.ArrayList]::new()
        $this.ScoreValue = 1000000

        # สร้างปืน (RelX, RelY, HP, W, H, Type)
        [void]$this.Parts.Add([LuciferPart]::new(-80, 30, 2000, 40, 80, "Cannon")) # ซ้าย
        [void]$this.Parts.Add([LuciferPart]::new(140, 30, 2000, 40, 80, "Cannon")) # ขวา
        [void]$this.Parts.Add([LuciferPart]::new(10, -50, 400, 35, 35, "Turret")) # บนซ้าย
        [void]$this.Parts.Add([LuciferPart]::new(55, -50, 400, 35, 35, "Turret")) # บนขวา
    }

    [void] UpdateWithPlayer([Object]$player) {
        # 1. Smooth HP Animation
        if ($this.VisualHP -gt $this.HP) { $this.VisualHP = $this.HP }
        if ($this.SmoothHP -gt $this.VisualHP) { $this.SmoothHP -= 40 } # เลือดขาวไหลตาม

        # 2. Movement (Tracking ช้าๆ แบบกดดัน)
        $this.X += ($player.X - 40 - $this.X) * 0.02
        if ($this.Y -lt 100) { $this.Y += 0.5 }

        # 3. Phase Control
        $activeCannons = ($this.Parts | Where-Object { $_.Type -eq "Cannon" -and -not $_.IsDestroyed }).Count
        $activeTurrets = ($this.Parts | Where-Object { $_.Type -eq "Turret" -and -not $_.IsDestroyed }).Count
        
        if ($activeCannons -eq 0 -and $this.Phase -eq 0) { $this.Phase = 1 }
        if ($activeTurrets -eq 0 -and $this.Phase -eq 1) { $this.Phase = 2 }

        # 4. Special Events
        if ($this.HP -lt 1000 -and $this.ArmorHP -eq 0) { $this.ArmorHP = 1000 }
        if ($this.HP -lt 7000) { $this.SummonTimer++ }

        # 5. Charging Fatal Laser
        $this.ChargeTimer += 0.016
        if ($this.ChargeTimer -gt 4.0) { $this.ChargeTimer = 0 }
    }

    [Object] TryShoot([int]$level) {
        $results = [System.Collections.ArrayList]::new()

        # Summon Wrath (HP < 7000)
        if ($this.SummonTimer -ge 180) {
            $this.SummonTimer = 0
            [void]$results.Add([Wrath]::new($this.X + 40, $this.Y + 100, 5))
        }

        # Phase 1: Side Cannons (Fatal Beams - ทำดาเมจใน CollisionManager)
        # Phase 2: Top Turrets (Fast Bullets -5 Def)
        if ($this.Phase -eq 1 -and ([math]::Floor($this.ChargeTimer * 60) % 30 -eq 0)) {
            foreach ($p in ($this.Parts | Where-Object { $_.Type -eq "Turret" -and -not $_.IsDestroyed })) {
                # กระสุนความเร็วสูงพิเศษ (สปีด 15)
                [void]$results.Add([EnemyBullet]::new($this.X + $p.RelX + 15, $this.Y + $p.RelY + 20, 0, 15))
            }
        }

        # HP < 10000: Greed Blast (สุ่มยิง)
        if ($this.HP -lt 10000 -and ([math]::Floor($this.ChargeTimer * 60) % 120 -eq 0)) {
            [void]$results.Add([GreedArrow]::new($this.X + 40, $this.Y + 50, $this.PlayerRef))
        }

        return if ($results.Count -gt 0) { $results } else { $null }
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $coreB = New-Object System.Drawing.SolidBrush($this.Color)
        $redB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
        
        # 1. วาดโครงสร้างกากบาทสีแดงด้านหลัง
        $g.FillRectangle($redB, [float]($this.X - 50), [float]($this.Y + 40), 200.0, 20.0)
        $pX = [System.Drawing.PointF[]]@(
            (New-Object System.Drawing.PointF($this.X-20, $this.Y-20)),
            (New-Object System.Drawing.PointF($this.X+120, $this.Y+120)),
            (New-Object System.Drawing.PointF($this.X+100, $this.Y+120)),
            (New-Object System.Drawing.PointF($this.X-40, $this.Y-20))
        )
        $g.FillPolygon($redB, $pX)

        # 2. วาดชิ้นส่วน (Parts)
        foreach ($p in $this.Parts) {
            if (-not $p.IsDestroyed) {
                $color = if ($p.Type -eq "Cannon") { [System.Drawing.Color]::Blue } else { [System.Drawing.Color]::DarkBlue }
                $g.FillEllipse((New-Object System.Drawing.SolidBrush($color)), [float]($this.X + $p.RelX), [float]($this.Y + $p.RelY), [float]$p.Width, [float]$p.Height)
                $g.DrawString("▼", [System.Drawing.Font]::new("Arial", 14), [System.Drawing.Brushes]::Orange, [float]($this.X + $p.RelX + 8), [float]($this.Y + $p.RelY + 10))
            }
        }

        # 3. วาดตัวเครื่องหลัก (Core)
        $g.FillRectangle($coreB, [float]$this.X, [float]$this.Y, 100.0, 100.0)
        $g.DrawString("$( [math]::Floor($this.HP / 1000) )K", [System.Drawing.Font]::new("Consolas", 14, [System.Drawing.FontStyle]::Bold), [System.Drawing.Brushes]::White, $this.X + 25, $this.Y + 40)

        # 4. วาดหลอดเลือด Smooth (ด้านบนสุด)
        $g.FillRectangle([System.Drawing.Brushes]::DimGray, 50, 15, 400, 15)
        $g.FillRectangle([System.Drawing.Brushes]::White, 50, 15, [float](400 * ($this.SmoothHP / 20000)), 15)
        $g.FillRectangle([System.Drawing.Brushes]::Red, 50, 15, [float](400 * ($this.VisualHP / 20000)), 15)
        
        if ($this.ArmorHP -gt 0) {
            $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Cyan, 3), 48, 13, 404, 19)
        }

        # 5. วาด Laser Charging Gauge (เมื่อจะยิง Fatal)
        if ($this.ChargeTimer -gt 2.5) {
            $g.FillRectangle([System.Drawing.Brushes]::Yellow, [float]($this.X), [float]($this.Y - 15), [float](100 * (($this.ChargeTimer - 2.5) / 1.5)), 6)
        }

        # 6. Portal (HP < 7000)
        if ($this.HP -lt 7000 -and ([DateTime]::Now.Millisecond -lt 500)) {
            $g.DrawEllipse([System.Drawing.Pen]::new([System.Drawing.Color]::Magenta, 4), [float]($this.X - 20), [float]($this.Y - 20), 140.0, 140.0)
        }
    }
}