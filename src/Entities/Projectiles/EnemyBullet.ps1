# src/Entities/Projectiles/EnemyBullet.ps1

class EnemyBullet : GameObject {
    [float]$SpeedY
    [float]$SpeedX  # <--- เพิ่มความเร็วแนวนอน

    # Constructor แบบเดิม (ยิงลงมาตรงๆ สำหรับศัตรูทั่วไป)
    EnemyBullet([float]$x, [float]$y) : base($x, $y, 5, 10, [System.Drawing.Color]::Yellow) {
        $this.SpeedY = 10
        $this.SpeedX = 0
    }

    # Constructor แบบใหม่ (กำหนดความเร็ว X และ Y เองได้ ใช้สำหรับท่าลูกซอง)
    EnemyBullet([float]$x, [float]$y, [float]$speedX, [float]$speedY) : base($x, $y, 5, 10, [System.Drawing.Color]::Orange) {
        $this.SpeedX = $speedX
        $this.SpeedY = $speedY
    }

    [void] Update() {
        $this.Y += $this.SpeedY
        $this.X += $this.SpeedX  # <--- ให้กระสุนขยับซ้าย/ขวาได้ด้วย
    }
}