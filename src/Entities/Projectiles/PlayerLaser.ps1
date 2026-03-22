# src/Entities/Projectiles/PlayerLaser.ps1

class PlayerLaser : Bullet {
    [int]$LifeTime = 60 
    [float]$DamageMultiplier = 1.0
    hidden [Object]$Owner

    PlayerLaser([Object]$player) : base($player.X, $player.Y) {
        $this.Owner = $player
        $this.Width = 13
        $this.Height = 600
        $this.Color = [System.Drawing.Color]::Lime
        $this.Speed = 0
    }

    [void] Update() {
        if ($null -eq $this.Owner) { $this.Y = 2000; return }
        $this.X = [float]($this.Owner.X + ($this.Owner.Width / 2.0) - ($this.Width / 2.0))
        $this.Y = 0 
        $this.Height = [float]$this.Owner.Y 

        $this.LifeTime--
        if ($this.LifeTime -le 0) { $this.Y = 2000 }
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        if ($this.LifeTime -gt 0) {
            # ใช้สีประจำ Object (Red/Lime)
            $coreBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $glowPen = New-Object System.Drawing.Pen($this.Color, 3)
            
            $g.FillRectangle($coreBrush, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
            $g.DrawRectangle($glowPen, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
        }
    }
}

class RedPlayerLaser : PlayerLaser {
    RedPlayerLaser([Object]$player) : base($player) {
        $this.Color = [System.Drawing.Color]::Red
        $this.DamageMultiplier = 2.0 
        $this.Width = 18 # ทำให้หนาขึ้นหน่อยให้ดูพลังเยอะ
    }
}