# src/Entities/DefenseDrop.ps1

class DefenseDrop : GameObject {
    [int]$Speed = 6 # ความเร็วตามที่คุณสั่ง
    DefenseDrop([float]$x, [float]$y) : base($x, $y, 30, 30, [System.Drawing.Color]::Gold) {}
    [void] Update() { $this.Y += $this.Speed }
    [void] Draw([System.Drawing.Graphics]$g) {
        $b = New-Object System.Drawing.SolidBrush($this.Color)
        $g.FillEllipse($b, [float]$this.X, [float]$this.Y, 30.0, 30.0)
        $f = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $g.DrawString("D", $f, [System.Drawing.Brushes]::Black, [float]($this.X + 8), [float]($this.Y + 6))
    }
}