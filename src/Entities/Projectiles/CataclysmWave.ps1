# src/Entities/Projectiles/CataclysmWave.ps1

class CataclysmWave : EnemyBullet {
    CataclysmWave([float]$x, [float]$y) : base(0, $y, 0, 3) { # ความเร็ว 3 ให้ดูค่อยๆ ถล่มลงมา
        $this.Width = 500 # ครอบคลุมพื้นที่เล่นเกมทั้งหมด
        $this.Height = 100 # ความหนาของกำแพงแสง
        $this.Color = [System.Drawing.Color]::FromArgb(120, 255, 105, 180) # ชมพูจางๆ (Opacity 120)
    }

    [void] Update() {
        $this.Y += $this.SpeedY
        # เมื่อคลื่นเลื่อนลงมาเรื่อยๆ ให้มันขยายความสูงขึ้นเหมือนถมหน้าจอ
        $this.Height += 1 
        
        # ถ้าพ้นจอแล้วให้ลบทิ้ง (แต่ปกติผู้เล่นน่าจะ Game Over ก่อน)
        if ($this.Y -gt 700) { $this.Y = 2000 }
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $brush = New-Object System.Drawing.SolidBrush($this.Color)
        $g.FillRectangle($brush, 0, [float]$this.Y, 500.0, [float]$this.Height)
        
        # เพิ่มขอบเรืองแสงด้านบนของคลื่น
        $p = New-Object System.Drawing.Pen([System.Drawing.Color]::DeepPink, 5)
        $g.DrawLine($p, 0, [float]$this.Y, 500.0, [float]$this.Y)
    }
}