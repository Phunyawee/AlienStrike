# src/Entities/Projectiles/Bullet.ps1
class Bullet : GameObject {
    [int]$Speed = 12
    [float]$SpeedX = 0  # เพิ่มความเร็วแกน X สำหรับยิงเฉียง (ค่าเริ่มต้นคือ 0 = ยิงตรง)

    # Constructor แบบเดิม: รับแค่ตำแหน่ง X, Y (ยิงตรงขึ้นข้างบนเสมอ)
    # ขนาด 6x15 สีเหลืองตามที่คุณตั้งไว้
    Bullet([float]$x, [float]$y) : base($x, $y, 6, 15, [System.Drawing.Color]::Yellow) {}

    # Constructor แบบใหม่: สำหรับยิงเฉียงโดยเฉพาะ (รับค่า X, Y และความเร็วแกน X)
    Bullet([float]$x, [float]$y, [float]$vx) : base($x, $y, 6, 15, [System.Drawing.Color]::Yellow) {
        $this.SpeedX = $vx
    }

    [void] Update() {
        # ขยับแกน Y ขึ้นข้างบน (ยิงตรง)
        $this.Y -= $this.Speed
        
        # ขยับแกน X ซ้าย-ขวา (ยิงเฉียง) 
        # ถ้า $SpeedX เป็น 0 มันก็จะไม่ขยับซ้ายขวา (เหมือนยิงตรงปกติ)
        $this.X += $this.SpeedX
    }
}