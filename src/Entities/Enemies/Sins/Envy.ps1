# src/Entities/Enemies/Sins/Envy.ps1

class Envy : BaseEnemy {
    hidden [Object]$PlayerRef
    [int]$TimesFired # <--- [NEW] เพิ่มตัวแปรนับจำนวนครั้งที่ยิง

    Envy([float]$x, [float]$y, [Object]$player) : base($x, $y, 50, 50, 1, 5, [System.Drawing.Color]::Magenta) {
        $this.ScoreValue = 5000 
        $this.PlayerRef = $player
        $this.TimesFired = 0 # <--- เซ็ตค่าเริ่มต้นเป็น 0
    }

    [void] Update() {
        # เดินลงมาข้างล่างช้าๆ และส่ายซ้ายขวาเบาๆ คล้ายงู
        $this.Y += $this.Speed
        $this.X += [math]::Sin($this.Y / 15) * 3
    }

    [Object] TryShoot([int]$currentLevel) {
        # [NEW] เช็คว่า ยิงไปน้อยกว่า 3 ครั้ง ถึงจะยอมให้สุ่มยิงต่อ
        if ($this.TimesFired -lt 3 -and $this.Rnd.Next(0, 100) -lt 2) { 
            
            $this.TimesFired++ # <--- บวกรอบการยิงเพิ่ม 1

            $bullets =[System.Collections.ArrayList]::new()
            
            $bx = $this.X + ($this.Width / 2) - 4
            $by = $this.Y + $this.Height

            # สร้างกระสุน 3 นัด
            [void]$bullets.Add([SilenceBullet]::new($bx - 20, $by, $this.PlayerRef))
            [void]$bullets.Add([SilenceBullet]::new($bx, $by + 10, $this.PlayerRef))
            [void]$bullets.Add([SilenceBullet]::new($bx + 20, $by, $this.PlayerRef))

            return $bullets
        }
        return $null
    }
}