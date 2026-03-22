# src/Entities/Projectiles/GluttonyBlast.ps1

class GluttonyBlast : EnemyBullet {
    GluttonyBlast([float]$x, [float]$y, [Object]$player) : base($x, $y, 0, 0) {
        $this.Width = 60
        $this.Height = 60
        $this.Color = [System.Drawing.Color]::MediumPurple

        # คำนวณทิศทาง (บวก Offset ให้เล็งไปที่กลางยานผู้เล่น)
        $targetX = [float]($player.X + 10.0)
        $targetY = [float]($player.Y + 10.0)
        
        $dx = $targetX - $x
        $dy = $targetY - $y
        $dist = [math]::Sqrt($dx*$dx + $dy*$dy)

        # ปรับความเร็วให้เหลือ 10 เพื่อให้เห็นชัดๆ (ความเร็ว 20 มันวาร์ปครับ)
        if ($dist -gt 0) {
            $this.SpeedX = [float](($dx / $dist) * 10.0)
            $this.SpeedY = [float](($dy / $dist) * 10.0)
        }
    }

    [void] Update() {
        # ขยับตามความเร็ว X และ Y
        $this.X += $this.SpeedX
        $this.Y += $this.SpeedY
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $brush = New-Object System.Drawing.SolidBrush($this.Color)
        # วาดวงกลมม่วง
        $g.FillEllipse($brush, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
        
        # เพิ่ม Aura วงกลมสีขาวกะพริบรอบๆ ให้ดูน่ากลัว
        $glowAlpha = [int]([math]::Abs([math]::Sin([DateTime]::Now.Ticks / 1000000.0)) * 255)
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($glowAlpha, 255, 255, 255), 4)
        $g.DrawEllipse($pen, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
    }
}