# src/Entities/Projectiles/SirenBullet.ps1

class SirenBullet : EnemyBullet {
    # กระสุนนี้จะเร็วกว่าปกติ 1.5 เท่า (ปกติ 10 อันนี้ให้ 15)
    SirenBullet([float]$x, [float]$y) : base($x, $y, 0, 15) {
        $this.Width = 8
        $this.Height = 15
        $this.Color = [System.Drawing.Color]::DeepPink # สีชมพูเตือนภัย
    }
}