# src/Entities/Enemy.ps1

class Enemy : GameObject {
    [int]$Speed
    [int]$Ammo = 2  # จำกัดกระสุน 2 นัด
    hidden [System.Random]$Rnd = [System.Random]::new() # ตัวสุ่มส่วนตัว

    Enemy([float]$x, [float]$y, [int]$speed, [System.Drawing.Color]$color) 
        : base($x, $y, 30, 30, $color) {
        $this.Speed = $speed
    }

    [void] Update() {
        $this.Y += $this.Speed
    }

    # ฟังก์ชันลองยิงกระสุน (คืนค่าเป็น EnemyBullet หรือ $null)
    [Object] TryShoot([int]$currentLevel) {
        # เงื่อนไข: Level >= 4 และ กระสุนยังไม่หมด
        if ($currentLevel -ge 7 -and $this.Ammo -gt 0) {
            
            # สุ่มโอกาส (แนะนำ 2% คือเลข 0-1 จาก 100)
            if ($this.Rnd.Next(0, 100) -lt 2) { 
                $this.Ammo--
                # สร้างกระสุนให้ออกมาจากกลางตัวศัตรู
                return [EnemyBullet]::new($this.X + 10, $this.Y + 30)
            }
        }
        return $null
    }
}