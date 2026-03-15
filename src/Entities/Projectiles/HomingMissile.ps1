class HomingMissile : Bullet {
    [Object]$Target = $null
    [float]$TurnSpeed = 0.18 # เลี้ยวคมขึ้นนิดนึง
    [bool]$IsExploding = $false
    [int]$LifeTimer = 15 # ระยะเวลาที่ระเบิดจะค้างบนจอ
    [float]$RealVX; [float]$RealVY 

    HomingMissile([float]$x, [float]$y) : base($x, $y) {
        $this.Width = 16; $this.Height = 16
        $this.Color = [System.Drawing.Color]::Yellow
        $this.Speed = 9
        $this.RealVX = 0; $this.RealVY = -[float]$this.Speed
    }

    # --- ฟังก์ชันระเบิด (เลียนแบบ Missile รุ่นแรก) ---
    [void] Explode() {
        if (-not $this.IsExploding) {
            $this.IsExploding = $true
            $cx = $this.X + ($this.Width / 2.0)
            $cy = $this.Y + ($this.Height / 2.0)
            
            # --- [แก้ไข] ขยายวงระเบิดเป็น 150px ---
            $this.Width = 150 
            $this.Height = 150
            $this.X = $cx - 75.0
            $this.Y = $cy - 75.0
            
            $this.RealVX = 0; $this.RealVY = 0
        }
    }

    [void] Update() {
        if ($this.IsExploding) {
            $this.LifeTimer--
            if ($this.LifeTimer -le 0) { $this.Y = -2000 } # เคลียร์ทิ้ง
            return
        }

        # ระบบค้นหาเป้าหมาย
        if ($null -eq $this.Target -or $this.Target.Y -gt 600) {
            $minDist = 2000
            foreach ($e in $Script:enemies) {
                $dist = [math]::Sqrt([math]::Pow($this.X - $e.X, 2) + [math]::Pow($this.Y - $e.Y, 2))
                if ($dist -lt $minDist) { $minDist = $dist; $this.Target = $e }
            }
        }

        # ระบบติดตามเป้าหมาย
        if ($null -ne $this.Target) {
            $dx = ($this.Target.X + ($this.Target.Width/2.0)) - $this.X
            $dy = ($this.Target.Y + ($this.Target.Height/2.0)) - $this.Y
            $dist = [math]::Sqrt($dx*$dx + $dy*$dy)
            if ($dist -gt 5) {
                $targetVX = ($dx / $dist) * $this.Speed
                $targetVY = ($dy / $dist) * $this.Speed
                $this.RealVX += ($targetVX - $this.RealVX) * $this.TurnSpeed
                $this.RealVY += ($targetVY - $this.RealVY) * $this.TurnSpeed
            }
            # [Proximity Fuse] ระเบิดก่อนชนนิดนึงถ้าเข้าใกล้เป้าหมายมากพอ
            if ($dist -lt 25) { $this.Explode() }
        }

        $this.X += $this.RealVX
        $this.Y += $this.RealVY

        # ลบถ้าหลุดขอบจอเยอะๆ
        if ($this.Y -lt -100 -or $this.X -lt -100 -or $this.X -gt 600 -or $this.Y -gt 700) { $this.Y = -2000 }
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        if ($this.IsExploding) {
            # วาดวงระเบิดสีส้มแดงเข้ม (เพิ่ม Opacity เป็น 220 ให้ชัดๆ)
            $b = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 255, 69, 0))
            $g.FillEllipse($b, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
            return
        }
        # วาดหัวลูกศรหมุนตามทิศทาง
        $state = $g.Save()
        $g.TranslateTransform(($this.X + ($this.Width/2.0)), ($this.Y + ($this.Height/2.0)))
        $angle = [math]::Atan2($this.RealVY, $this.RealVX) * (180 / [math]::PI) + 90
        $g.RotateTransform($angle)

        $g.FillRectangle([System.Drawing.Brushes]::Orange, -3, 6, 6, 12) # หางไฟ
        $pts = [System.Drawing.PointF[]]::new(3)
        $pts[0] = New-Object System.Drawing.PointF(0, -10)
        $pts[1] = New-Object System.Drawing.PointF(-8, 6)
        $pts[2] = New-Object System.Drawing.PointF(8, 6)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush($this.Color)), $pts)
        $g.Restore($state)
    }
}