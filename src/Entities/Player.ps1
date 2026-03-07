class Player : GameObject {
    [int]$Speed = 8
    [int]$Cooldown = 0

    Player([float]$x, [float]$y) : base($x, $y, 30, 30, [System.Drawing.Color]::Cyan) {}

    [void] MoveLeft() {
        if ($this.X -gt 0) { $this.X -= $this.Speed }
    }

    [void] MoveRight([int]$screenWidth) {
        if ($this.X -lt ($screenWidth - $this.Width)) { $this.X += $this.Speed }
    }[void] Update() {
        if ($this.Cooldown -gt 0) { $this.Cooldown-- }
    }

    [bool] CanShoot() {
        return ($this.Cooldown -le 0)
    }
    
    [void] ResetCooldown() {
        $this.Cooldown = 8 
    }
}