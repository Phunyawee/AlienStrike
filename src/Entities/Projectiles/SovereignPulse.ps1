class SovereignPulse : EnemyBullet {
    [int]$LifeTime = 30 
    SovereignPulse([float]$y) : base(0, $y, 0, 0) {
        $this.Width = 700; $this.Height = 15; $this.Color = [System.Drawing.Color]::SkyBlue
    }
    [void] Update() { $this.LifeTime--; if($this.LifeTime -le 0) { $this.Y = 2000 } }
    [void] Draw([System.Drawing.Graphics]$g) {
        $brush = New-Object System.Drawing.SolidBrush($this.Color)
        $g.FillRectangle($brush, 0, [float]$this.Y, 700.0, [float]$this.Height)
    }
}