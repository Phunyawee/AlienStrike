class Watcher : BaseEnemy {
    [int]$ActionState = 0 
    [float]$TargetX; [float]$TargetY
    [int]$ActionTimer = 0
    [string]$Type 

    # --- ตัวแปรสำหรับโหมด Orbit (หมุน) ---
    [float]$Angle = 0
    [float]$Radius = 80
    [float]$OrbitCX; [float]$OrbitCY

    # --- ตัวแปรสำหรับโหมด Ace (ยานแดง) ---
    [int]$ShotCount = 0

    Watcher([float]$x, [float]$y, [float]$tx, [float]$ty, [string]$type) 
        : base($x, $y, 35, 35, 4, 3, [System.Drawing.Color]::Blue) {
        $this.TargetX = $tx; $this.TargetY = $ty
        $this.Type = $type
        if ($type -eq "Leader") { $this.Color = [System.Drawing.Color]::Red; $this.HP = 10 }
        elseif ($type -eq "Ace") { 
            $this.Color = [System.Drawing.Color]::Red; $this.HP = 5; $this.Speed = 8 # สปีด 2 เท่า
        }
    }

    [void] Update() {
        if ($this.FlashTimer -gt 0) { $this.FlashTimer-- }
        $this.ActionTimer++

        if ($this.Type -eq "Orbit") {
            $this.Angle += 0.05
            $this.X = $this.OrbitCX + [math]::Cos($this.Angle) * $this.Radius
            $this.Y = $this.OrbitCY + [math]::Sin($this.Angle) * $this.Radius
            if ($this.ActionTimer -gt 350) { $this.Y = 2000 } 
        }
        elseif ($this.Type -eq "Ace") {
            if ($this.ActionState -eq 0) {
                $this.X += $this.Speed
                if ($this.X -gt 230) { $this.ActionState = 1 } 
            }
            elseif ($this.ActionState -eq 1) {
                $this.X += $this.Speed; $this.Y -= 1
                if ($this.Y -lt 40) { $this.ActionState = 2; $this.ActionTimer = 0 }
            }
            elseif ($this.ActionState -eq 2) {
                if ($this.ActionTimer -gt 150) { $this.Y = -200 }
            }
        }
        else {
            switch ($this.ActionState) {
                0 { $this.X += ($this.TargetX - $this.X) * 0.08; $this.Y += ($this.TargetY - $this.Y) * 0.08
                    if ([math]::Abs($this.Y - $this.TargetY) -lt 2) { $this.ActionState = 1 } }
                1 { $this.X += [math]::Sin($this.ActionTimer / 15.0) * 2
                    if ($this.ActionTimer -gt 300) { $this.ActionState = 2 } }
                2 { $this.Y -= 5; if ($this.Y -lt -100) { $this.Y = 2000 } }
            }
        }

        # --- [NEW] บังคับไม่ให้หลุดไปใน Sidebar (0 - 465) ---
        if ($this.X -gt 465 -and $this.Y -lt 600) { $this.X = 465 }
        if ($this.X -lt 0) { $this.X = 0 }
    }

    [Object] TryShoot([int]$level) {
        # ถ้าเป็นแบบ Passive จะไม่ยิงอะไรเลย
        if ($this.Type -eq "Passive") { return $null }

        if ($this.ActionState -eq 1 -or $this.Type -eq "Orbit") {
            if ($this.Type -eq "Orbit") {
                if ($this.Rnd.Next(0, 100) -lt 1.5) { return [EnemyBullet]::new($this.X + 15, $this.Y + 30) }
            }
            elseif ($this.Type -eq "Ace") {
                # ลอจิกการยิงของ Ace (เหมือนเดิม)
                if ($this.ActionState -eq 1 -and $this.ShotCount -eq 0) {
                    $this.ShotCount = 1; return [EnemyMissile]::new($this.X, $this.Y)
                }
                if ($this.ActionState -eq 2 -and $this.ActionTimer % 40 -eq 0 -and $this.ShotCount -lt 3) {
                    $this.ShotCount++; return [EnemyBullet]::new($this.X + 15, $this.Y + 30)
                }
            }
            elseif ($this.Type -eq "Leader") {
                 # หัวหน้ากองยิงมิสไซล์ทุกๆ 60 เฟรม
                 if ($this.ActionTimer % 60 -eq 0) { return [EnemyMissile]::new($this.X + 10, $this.Y + 30) }
            }
            elseif ($this.Type -eq "Minion") {
                if ($this.Rnd.Next(0, 100) -lt 4) { return [EnemyBullet]::new($this.X + 15, $this.Y + 30) }
            }
        }
        return $null
    }

    # ฟังก์ชัน Draw เหมือนเดิม (วาดสามเหลี่ยมคว่ำ + หลอดเลือด)
    [void] Draw([System.Drawing.Graphics]$g) {
        $color = if ($this.FlashTimer -gt 0) { [System.Drawing.Color]::White } else { $this.Color }
        $brush = New-Object System.Drawing.SolidBrush($color)
        
        $pts = [System.Drawing.PointF[]]::new(3)
        $pts[0] = New-Object System.Drawing.PointF([float]$this.X, [float]$this.Y)
        $pts[1] = New-Object System.Drawing.PointF([float]($this.X + $this.Width), [float]$this.Y)
        $pts[2] = New-Object System.Drawing.PointF([float]($this.X + ($this.Width/2)), [float]($this.Y + $this.Height))
        $g.FillPolygon($brush, $pts)

        # วาดหลอดเลือดเฉพาะเมื่อโดนยิง
        if ($this.HP -lt $this.MaxHP -and $this.HP -gt 0) {
            $ratio = [float]($this.HP / $this.MaxHP)
            $g.FillRectangle([System.Drawing.Brushes]::DarkRed, [float]$this.X, [float]($this.Y - 8), [float]$this.Width, 4.0)
            $g.FillRectangle([System.Drawing.Brushes]::Lime, [float]$this.X, [float]($this.Y - 8), [float]($this.Width * $ratio), 4.0)
        }
    }
}