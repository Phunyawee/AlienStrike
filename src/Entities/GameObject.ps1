class GameObject {
    [float]$X
    [float]$Y
    [int]$Width
    [int]$Height
    [System.Drawing.Color]$Color

    GameObject([float]$x,[float]$y, [int]$w, [int]$h, [System.Drawing.Color]$c) {
        $this.X = $x
        $this.Y = $y
        $this.Width = $w
        $this.Height = $h
        $this.Color = $c
    }

    [System.Drawing.Rectangle] GetBounds() {
        return [System.Drawing.Rectangle]::new([int]$this.X, [int]$this.Y, $this.Width, $this.Height)
    }

    [void] Update() {}
    
    [void] Draw([System.Drawing.Graphics]$g) {
        $brush = New-Object System.Drawing.SolidBrush($this.Color)
        $g.FillRectangle($brush, $this.GetBounds())
        $brush.Dispose()
    }
}