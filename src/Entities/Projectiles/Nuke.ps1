# src/Entities/Projectiles/Nuke.ps1

class Nuke : Bullet {
    [bool]$Exploded = $false
    [int]$LifeTime = 2 # ค้างไว้ 2 เฟรมเพื่อให้ระบบตรวจจับดาเมจทัน

    Nuke([float]$x, [float]$y) : base($x, $y) {
        $this.Width = 20; $this.Height = 35; $this.Color = [System.Drawing.Color]::OrangeRed
        $this.Speed = 9
    }
    [void] Update() {
        if (-not $this.Exploded) {
            $this.Y -= $this.Speed
            if ($this.Y -le 300) { $this.Exploded = $true }
        } else {
            $this.LifeTime--
            if ($this.LifeTime -le 0) { $this.Y = -2000 } # หายไปหลังระเบิดเสร็จ
        }
    }
    [void] Draw([System.Drawing.Graphics]$g) {
        $b = New-Object System.Drawing.SolidBrush($this.Color)
        if (-not $this.Exploded) {
            $g.FillRectangle($b, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
        } else {
            # วาดวงกลมระเบิดขยายตัว
            $g.FillEllipse($b, [float]($this.X - 50), [float]($this.Y - 50), 120.0, 120.0)
        }
    }
}