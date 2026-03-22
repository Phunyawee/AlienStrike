# src/Entities/Projectiles/EnemyMissile.ps1

class EnemyMissile : EnemyBullet {
    [bool]$IsExploding = $false
    [int]$LifeTimer = 15

    EnemyMissile([float]$x, [float]$y) : base($x, $y, 0, 6) {
        $this.Width = 12; $this.Height = 20
        $this.Color = [System.Drawing.Color]::OrangeRed
    }

    [void] Explode() {
        if (-not $this.IsExploding) {
            $this.IsExploding = $true
            $this.Width = 150; $this.Height = 150 # รัศมีน้อยกว่าเราครึ่งหนึ่ง
            $this.X -= 70; $this.Y -= 70
            $this.SpeedY = 0
        }
    }

    [void] Update() {
        if (-not $this.IsExploding) {
            $this.Y += $this.SpeedY
            if ($this.Y -gt 500) { $this.Explode() } # ระเบิดเมื่อใกล้ถึงพื้นจอ
        } else {
            $this.LifeTimer--
            if ($this.LifeTimer -le 0) { $this.Y = 2000 }
        }
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $b = New-Object System.Drawing.SolidBrush($this.Color)
        if (-not $this.IsExploding) {
            $g.FillRectangle($b, $this.X, $this.Y, $this.Width, $this.Height)
        } else {
            $g.FillEllipse($b, $this.X, $this.Y, $this.Width, $this.Height)
        }
    }
}