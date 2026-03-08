# src/Entities/Projectiles/PrideLaser.ps1

class PrideLaser : EnemyBullet {
    [int]$LifeTime = 15 # เลเซอร์จะค้างบนจอ 15 เฟรม (ประมาณ 0.25 วินาที) แล้วหายไป

    # Constructor
    PrideLaser([float]$x, [float]$y) : base($x, $y, 0, 0) {
        $this.Width = 26   # ความกว้างของเลเซอร์
        $this.Height = 600 # ความยาวทะลุจอ (โดนทันที)
        $this.Color = [System.Drawing.Color]::White
    }

    [void] Update() {
        # นับถอยหลังอายุของเลเซอร์
        $this.LifeTime--
        
        # ถ้าหมดเวลา ให้ย้ายเลเซอร์ออกไปนอกจอสุดๆ เพื่อให้ระบบเกมเตะมันทิ้ง
        if ($this.LifeTime -le 0) {
            $this.Y = 2000 
        }
    }

    # อัปเกรดการวาดเลเซอร์ให้ดูอลังการขึ้น (สีขาว ขอบม่วง)
    [void] Draw([System.Drawing.Graphics]$g) {
        $coreBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $glowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Fuchsia, 4)
        
        $g.FillRectangle($coreBrush, $this.X, $this.Y, $this.Width, $this.Height)
        $g.DrawRectangle($glowPen, $this.X, $this.Y, $this.Width, $this.Height)
    }
}