# src/Entities/Projectiles/Missile.ps1

class Missile : Bullet {
    [int]$LifeTimer = 15 # ระยะเวลาที่ระเบิดจะแสดงผลบนจอ (เฟรม)
    [bool]$IsExploding = $false

    Missile([float]$x, [float]$y) : base($x, $y) {
        $this.Width = 12
        $this.Height = 24
        $this.Color = [System.Drawing.Color]::Cyan
        $this.Speed = 8
    }

    # ฟังก์ชันสั่งระเบิด (เรียกใช้เมื่อชน หรือ เมื่อถึงระยะ)
    [void] Explode() {
        if (-not $this.IsExploding) {
            $this.IsExploding = $true
            # ขยายขนาดระเบิดเป็น 300x300 (ใหญ่กว่าเดิม 2 เท่า)
            $oldCenterX = $this.X + ($this.Width / 2)
            $oldCenterY = $this.Y + ($this.Height / 2)
            
            $this.Width = 300
            $this.Height = 300
            # ปรับตำแหน่งให้จุดศูนย์กลางระเบิด อยู่ที่เดียวกับหัวมิสไซล์เดิม
            $this.X = $oldCenterX - ($this.Width / 2)
            $this.Y = $oldCenterY - ($this.Height / 2)
            
            $this.Speed = 0 # หยุดนิ่ง
            $this.Color = [System.Drawing.Color]::FromArgb(180, 255, 165, 0) # ส้มโปร่งแสงนิดๆ
        }
    }

    [void] Update() {
        if (-not $this.IsExploding) {
            $this.Y -= $this.Speed
            # ถ้าวิ่งเลยขอบบน ให้ระเบิดเอง
            if ($this.Y -lt 0) { $this.Explode() }
        } else {
            # ถ้าระเบิดอยู่ ให้ลดเวลาชีวิต
            $this.LifeTimer--
            if ($this.LifeTimer -le 0) {
                $this.Y = -1000 # ย้ายทิ้งเพื่อรอการทำลาย
            }
        }
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $brush = New-Object System.Drawing.SolidBrush($this.Color)
        if (-not $this.IsExploding) {
            # วาดตัวมิสไซล์
            $g.FillRectangle($brush, $this.X, $this.Y, $this.Width, $this.Height)
        } else {
            # วาดวงกลมระเบิด
            $g.FillEllipse($brush, $this.X, $this.Y, $this.Width, $this.Height)
        }
    }
}