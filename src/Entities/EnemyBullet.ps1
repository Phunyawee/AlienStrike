# src/Entities/EnemyBullet.ps1

class EnemyBullet : GameObject {
    # ความเร็วครึ่งหนึ่งของกระสุน Player (สมมติ Player=15, อันนี้เอาซัก 7-8)
    EnemyBullet([float]$x, [float]$y) : base($x, $y, 8, 8, [System.Drawing.Color]::OrangeRed) {
    }

    [void] Update() {
        $this.Y += 7 # วิ่งลงข้างล่าง
    }
}