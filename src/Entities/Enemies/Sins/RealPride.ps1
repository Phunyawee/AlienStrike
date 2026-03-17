class RealPride : BaseEnemy {
    [int]$State = 0 
    [float]$Timer = 0
    [int]$LaserCount = 0 
    [bool]$TargetOnPlayer = $false
    hidden [Object]$PlayerRef

    RealPride([float]$x, [float]$y, [Object]$player) 
        : base($x, $y, 80, 60, 3, 2000, [System.Drawing.Color]::Gold) {
        $this.PlayerRef = $player
        $this.ScoreValue = 250000
    }

    [void] UpdateWithPlayer([Object]$player) {
        # --- 1. Entry: พุ่งลงมาจากฟ้า (Smooth Entry) ---
        if ($this.Y -lt 80) {
            $this.Y += (80 - $this.Y) * 0.1 + 1 # ค่อยๆ ชะลอเมื่อถึงจุดหยุด
            return 
        }

        # --- 2. Smooth Movement (ใช้ระบบค่อยๆ ขยับตาม X) ---
        $this.Timer += 0.016 
        
        # การส่ายแบบนุ่มนวล (ใช้ Ticks หารเยอะขึ้น)
        $this.X += [math]::Sin([DateTime]::Now.Ticks / 8000000.0) * 1.5

        # เช็ค Crosshair
        $centerX = $this.X + ($this.Width / 2.0)
        if ([math]::Abs($centerX - ($player.X + 10)) -lt 30) { $this.TargetOnPlayer = $true } 
        else { $this.TargetOnPlayer = $false }

        switch ($this.State) {
            0 { # Tracking: ตามผู้เล่นแบบนุ่มนวล
                $targetX = $player.X - 30.0
                $this.X += ($targetX - $this.X) * 0.08 # ลดค่าเลขลงเพื่อให้ความรู้สึกไหล ไม่กระตุก
                if ($this.Timer -gt 1.5) { $this.State = 1; $this.Timer = 0 }
            }
            1 { # Locked (0.5s)
                if ($this.Timer -gt 0.5) { 
                    $this.State = 2; $this.Timer = 0; $this.LaserCount++ 
                }
            }
            2 { # Firing (1.5s)
                if ($this.Timer -gt 1.5) { $this.State = 3; $this.Timer = 0 }
            }
            3 { # Cooldown
                if ($this.Timer -gt 1.2) { $this.State = 0; $this.Timer = 0 }
            }
        }
    }

    [Object] TryShoot([int]$level) {
        if ($this.LaserCount -ge 15) {
            $this.LaserCount = 0 
            return [CataclysmWave]::new(0, [float]($this.Y + 60))
        }
        return $null
    }
   
    [void] Draw([System.Drawing.Graphics]$g) {
        $b = New-Object System.Drawing.SolidBrush($this.GetFlashColor())
        $centerX = [float]($this.X + ($this.Width / 2.0))
        
        # 1. วาดตัวยาน (Rectangle แกนกลาง)
        $g.FillRectangle($b, [float]($this.X + 15), [float]$this.Y, 50.0, 30.0)
        
        # 2. วาดสามเหลี่ยม 3 ชิ้น (ห้ามใช้ฟังก์ชันย่อยเพื่อกันบั๊ก PointF)
        $pts = [System.Drawing.PointF[]]::new(3)
        
        # --- ซ้าย (หันขึ้น) ---
        $pts[0] = New-Object System.Drawing.PointF([float]$this.X, [float]($this.Y + 30))
        $pts[1] = New-Object System.Drawing.PointF([float]($this.X + 15), [float]$this.Y)
        $pts[2] = New-Object System.Drawing.PointF([float]($this.X + 15), [float]($this.Y + 30))
        $g.FillPolygon($b, $pts)

        # --- ขวา (หันขึ้น) ---
        $pts[0] = New-Object System.Drawing.PointF([float]($this.X + 80), [float]($this.Y + 30))
        $pts[1] = New-Object System.Drawing.PointF([float]($this.X + 65), [float]$this.Y)
        $pts[2] = New-Object System.Drawing.PointF([float]($this.X + 65), [float]($this.Y + 30))
        $g.FillPolygon($b, $pts)

        # --- กลาง (หันลง - ปากกระบอกเลเซอร์) ---
        $pts[0] = New-Object System.Drawing.PointF([float]($this.X + 30), [float]($this.Y + 30))
        $pts[1] = New-Object System.Drawing.PointF([float]($this.X + 50), [float]($this.Y + 30))
        $pts[2] = New-Object System.Drawing.PointF([float]($this.X + 40), [float]($this.Y + 55))
        $g.FillPolygon($b, $pts)

        # 3. วาดเลเซอร์และเส้นเล็ง
        if ($this.State -eq 0 -or $this.State -eq 1) {
            $p = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 2)
            $p.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
            $g.DrawLine($p, $centerX, [float]($this.Y + 55), $centerX, 600.0)
        }
        if ($this.State -eq 2) {
            $laserB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 255, 255))
            $g.FillRectangle($laserB, [float]($centerX - 15), [float]($this.Y + 55), 30.0, 600.0)
            $g.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::Red, 4), [float]($centerX - 15), [float]($this.Y + 55), 30.0, 600.0)
        }

        # 4. วาดเป้าเล็งที่ยานผู้เล่น
        if ($this.TargetOnPlayer -and $this.State -lt 2) {
            $pTarget = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 3)
            $g.DrawEllipse($pTarget, [float]($this.PlayerRef.X - 5), [float]($this.PlayerRef.Y - 5), 31.0, 31.0)
        }

        $font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        $g.DrawString("FATAL ENTITY HP: $($this.HP)", $font, [System.Drawing.Brushes]::Red, [float]$this.X, [float]($this.Y - 20))
    }
}