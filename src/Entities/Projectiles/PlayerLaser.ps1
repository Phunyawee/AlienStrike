class PlayerLaser : Bullet {
    [int]$LifeTime = 60 
    hidden [Object]$Owner

    PlayerLaser([Object]$player) : base($player.X, $player.Y) {
        $this.Owner = $player
        $this.Width = 13
        $this.Height = 600 # ความยาวเลเซอร์
        $this.Color = [System.Drawing.Color]::Lime
        $this.Speed = 0
    }

    [void] Update() {
        # ป้องกัน Owner (Player) หายไปชั่วขณะ
        if ($null -eq $this.Owner) { $this.Y = 2000; return }

        $this.X = [float]($this.Owner.X + ($this.Owner.Width / 2.0) - ($this.Width / 2.0))
        $this.Y = 0 
        $this.Height = [float]$this.Owner.Y 

        $this.LifeTime--
        if ($this.LifeTime -le 0) {
            $this.Y = 2000 
        }
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        if ($this.LifeTime -gt 0) {
            $coreBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $glowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Lime, 3)
            
            # วาดเส้นเลเซอร์จากขอบบน (0) ลงมาถึงตัวยาน
            $g.FillRectangle($coreBrush, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
            $g.DrawRectangle($glowPen, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
        }
    }
}