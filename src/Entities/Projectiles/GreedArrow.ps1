class GreedArrow : EnemyBullet {
    GreedArrow([float]$x, [float]$y, [Object]$player) : base($x, $y, 0, 0) {
        $this.Width = 15; $this.Height = 15
        $this.Color = [System.Drawing.Color]::Gold

        # คำนวณทิศทางพุ่งหา Player ครั้งเดียว (แบบ Projectile)
        $dx = ($player.X + 15) - $x
        $dy = ($player.Y + 15) - $y
        $distance = [math]::Sqrt($dx*$dx + $dy*$dy)
        
        # ความเร็วสูงมาก (18)
        $this.SpeedX = ($dx / $distance) * 16
        $this.SpeedY = ($dy / $distance) * 16
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $brush = New-Object System.Drawing.SolidBrush($this.Color)
        
        # สร้างอาเรย์ 3 จุดสำหรับสามเหลี่ยมหัวศร
        $pts = [System.Drawing.PointF[]]::new(3)
        
        $pts[0] = New-Object System.Drawing.PointF(([float]$this.X + ([float]$this.Width / 2.0)), [float]$this.Y)
        $pts[1] = New-Object System.Drawing.PointF([float]$this.X, ([float]$this.Y + [float]$this.Height))
        $pts[2] = New-Object System.Drawing.PointF(([float]$this.X + [float]$this.Width), ([float]$this.Y + [float]$this.Height))
        
        $g.FillPolygon($brush, $pts)
    }
}