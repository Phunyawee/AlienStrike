class NephilimBlade : EnemyBullet {
    [float]$RotationAngle = 0
    NephilimBlade([float]$x, [float]$y, [Object]$player) : base($x, $y, 0, 0) {
        $this.Width = 40; $this.Height = 40
        # --- [NEW] ระบบล็อคเป้าตอนโยน ---
        $dx = ($player.X + 10) - $x
        $dy = ($player.Y + 10) - $y
        $dist = [math]::Sqrt($dx*$dx + $dy*$dy)
        # ความเร็ว 18 (เพิ่มจาก 12)
        $this.SpeedX = ($dx / $dist) * 18
        $this.SpeedY = ($dy / $dist) * 18
    }
    [void] Update() {
        $this.X += $this.SpeedX
        $this.Y += $this.SpeedY
        $this.RotationAngle += 25
        if ($this.Y -gt 700 -or $this.X -lt -50 -or $this.X -gt 550) { $this.Y = 2000 }
    }
    [void] Draw([System.Drawing.Graphics]$g) {
        $state = $g.Save()
        $g.TranslateTransform(($this.X + 20), ($this.Y + 20))
        $g.RotateTransform($this.RotationAngle)
        $p = New-Object System.Drawing.Pen([System.Drawing.Color]::DeepSkyBlue, 6)
        $g.DrawLine($p, -20, -20, 20, 20); $g.DrawLine($p, -20, 20, 20, -20)
        $g.Restore($state)
    }
}