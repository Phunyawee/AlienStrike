class Player : GameObject {
    [int]$Cooldown = 0

    Player([float]$x, [float]$y) : base($x, $y, 30, 30, [System.Drawing.Color]::Cyan) {}

    # แก้ให้รับค่า speed เข้ามาโดยตรง
    [void] Move([float]$step) {
        $this.X += $step
        # กันหลุดขอบจอ
        if ($this.X -lt 0) { $this.X = 0 }
        if ($this.X -gt 470) { $this.X = 470 }
    }

    [void] Update() {
        if ($this.Cooldown -gt 0) { $this.Cooldown-- }
    }

    [bool] CanShoot() { return ($this.Cooldown -le 0) }
    
    [void] ResetCooldown() { $this.Cooldown = 8 }
}