class HolyBomb : Bullet {
    HolyBomb([float]$x, [float]$y) : base($x, $y) {
        $this.Width = 25; $this.Height = 25
        $this.Color = [System.Drawing.Color]::White # สีขาวศักดิ์สิทธิ์
        $this.Speed = 7
    }
    [void] Draw([System.Drawing.Graphics]$g) {
        $b = New-Object System.Drawing.SolidBrush($this.Color)
        # วาดเป็นรูปข้าวหลามตัด (Diamond)
        $pts = [System.Drawing.PointF[]]::new(4)
        $pts[0] = New-Object System.Drawing.PointF(($this.X + 12), $this.Y)
        $pts[1] = New-Object System.Drawing.PointF(($this.X + 25), ($this.Y + 12))
        $pts[2] = New-Object System.Drawing.PointF(($this.X + 12), ($this.Y + 25))
        $pts[3] = New-Object System.Drawing.PointF($this.X, ($this.Y + 12))
        $g.FillPolygon($b, $pts)
        $g.DrawPolygon([System.Drawing.Pens]::Cyan, $pts)
    }
}