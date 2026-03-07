# src/Entities/Enemies/Sins/Wrath.ps1

class Wrath : BaseEnemy {
    [int]$SinLevel
    [bool]$HasFiredShotgun = $false # <--- เคาะลงมาให้อยู่บรรทัดใหม่แบบนี้ครับ

    # Constructor
    Wrath([float]$x, [float]$y, [int]$sinLevel) 
        # สังเกตตรง Speed: เอาไปหาร 2 เพื่อลดความเร็วลงครึ่งนึง และบังคับไม่ให้ต่ำกว่า 1
        : base($x, $y, 40, 40,[math]::Max([math]::Floor(($sinLevel * 2 + 5) / 2), 1), 7, [System.Drawing.Color]::Red) {
        
        $this.SinLevel = $sinLevel
        $this.ScoreValue = 1000 
    }

    # Override การเดิน: เดินช้าลง แต่ยังส่ายบ้าคลั่งอยู่
    [void] Update() {
        $this.Y += $this.Speed
        $this.X += $this.Rnd.Next(-5, 6) 
    }

    # Override ท่ายิง: ท่าไม้ตายลูกซอง 5 นัด!
    [Object] TryShoot([int]$currentLevel) {
        # เงื่อนไข: เลเวลเกมด่าน >= 4, ยังไม่เคยยิง, และลงมาในหน้าจอระยะนึงแล้ว (Y > 60)
        if ($currentLevel -ge 4 -and -not $this.HasFiredShotgun -and $this.Y -gt 60) {
            
            # สุ่มโอกาสนิดหน่อย จะได้ไม่ยิงพร้อมกันเป๊ะๆ ถ้าโผล่มาหลายตัว
            if ($this.Rnd.Next(0, 100) -lt 5) {
                $this.HasFiredShotgun = $true  # ล็อกว่ายิงแล้ว จะไม่ยิงอีก
                
                $bullets =[System.Collections.ArrayList]::new()
                
                # จุดศูนย์กลางที่กระสุนจะออก
                $bx = $this.X + ($this.Width / 2) - 2
                $by = $this.Y + $this.Height

                # สร้างกระสุน 5 นัด บานออกเป็นพัด (ส่งค่า X-Speed, Y-Speed)
                [void]$bullets.Add([EnemyBullet]::new($bx, $by, -4, 8))  # ซ้ายสุด
                [void]$bullets.Add([EnemyBullet]::new($bx, $by, -2, 9))  # ซ้ายเฉียง
                [void]$bullets.Add([EnemyBullet]::new($bx, $by, 0, 10))  # ตรงกลาง
                [void]$bullets.Add([EnemyBullet]::new($bx, $by, 2, 9))   # ขวาเฉียง
                [void]$bullets.Add([EnemyBullet]::new($bx, $by, 4, 8))   # ขวาสุด

                return $bullets # คืนค่ากลับไปทีเดียว 5 นัด!
            }
        }
        return $null
    }
}