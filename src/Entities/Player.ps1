class Player : GameObject {
    [int]$Cooldown = 0
    # ปรับขนาดยานให้เล็กลงเพื่อความพริ้ว
    Player([float]$x, [float]$y) : base($x, $y, 21, 21, [System.Drawing.Color]::Cyan) {}

    [void] Move([float]$step) {
        $this.X += $step
        if ($this.X -lt 0) { $this.X = 0 }
        if ($this.X -gt 479) { $this.X = 479 } # ปรับขอบจอตามขนาดยานใหม่
    }

    [void] Update() {
        if ($this.Cooldown -gt 0) { $this.Cooldown-- }
    }

    [bool] CanShoot() { return ($this.Cooldown -le 0) }
    
    [void] ResetCooldown() { $this.Cooldown = 8 }
}