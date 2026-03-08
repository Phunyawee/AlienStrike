class Lust : BaseEnemy {
    [float]$StartX
    [int]$DirectionX 
    [int]$LifeTimer = 0
    [bool]$HasShot = $false

    Lust([float]$x, [float]$y, [int]$dirX) 
        # ตรงนี้ครับ! เปลี่ยนเลข 2 เป็น 3 (Speed=8, HP=3)
        : base($x, $y, 30, 30, 8, 3, [System.Drawing.Color]::DeepPink) {
        $this.ScoreValue = 2000
        $this.StartX = $x
        $this.DirectionX = $dirX
    }

    [void] Update() {
        $this.LifeTimer++
        $this.X += ($this.Speed * $this.DirectionX)
        $this.Y += [math]::Sin($this.LifeTimer / 10.0) * 6

        if ($this.X -lt -200 -or $this.X -gt 900) {
            $this.Y = 2000 
        }
    }

    [Object] TryShoot([int]$currentLevel) {
        if (-not $this.HasShot -and $this.X -gt 100 -and $this.X -lt 400) {
            if ($this.Rnd.Next(0, 100) -lt 5) {
                $this.HasShot = $true
                return [SirenBullet]::new($this.X + 15, $this.Y + 30)
            }
        }
        return $null
    }

    # Override การวาด ให้วาดสามเหลี่ยม + หลอดเลือด
    [void] Draw([System.Drawing.Graphics]$g) {
        # 1. วาดตัวยานสามเหลี่ยม
        $brush = New-Object System.Drawing.SolidBrush($this.Color)
        $p1 = New-Object System.Drawing.PointF($this.X, $this.Y)
        $p2 = New-Object System.Drawing.PointF(($this.X + $this.Width), $this.Y)
        $p3 = New-Object System.Drawing.PointF(($this.X + ($this.Width / 2)), ($this.Y + $this.Height))
        
        $points = [System.Drawing.PointF[]]@($p1, $p2, $p3)
        $g.FillPolygon($brush, $points)

        # 2. [NEW] วาดหลอดเลือดบนหัว
        if ($this.HP -lt $this.MaxHP -and $this.HP -gt 0) {
            $healthPercent = $this.HP / $this.MaxHP
            $barWidth = $this.Width * $healthPercent
            
            $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::DarkRed)
            $hpBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Lime)
            
            $g.FillRectangle($bgBrush, $this.X, ($this.Y - 6), $this.Width, 3)
            $g.FillRectangle($hpBrush, $this.X, ($this.Y - 6), $barWidth, 3)
        }
    }
}