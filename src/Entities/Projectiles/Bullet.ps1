class Bullet : GameObject {
    [int]$Speed = 12

    # สร้างกระสุน สีเหลือง ขนาด 6x15
    Bullet([float]$x, [float]$y) : base($x, $y, 6, 15, [System.Drawing.Color]::Yellow) {}

    [void] Update() {
        $this.Y -= $this.Speed
    }
}