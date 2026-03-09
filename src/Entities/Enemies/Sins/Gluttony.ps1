class Gluttony : BaseEnemy {
    [int]$State = 0 
    [int]$ChargeTimer = 0
    hidden [Object]$PlayerRef

    Gluttony([float]$x, [float]$y, [Object]$player) 
        : base($x, $y, 80, 60, 2, 200, [System.Drawing.Color]::Purple) {
        $this.PlayerRef = $player
        $this.ScoreValue = 50000
    }

    [void] Update() {
        # ลอยไปมาแนวขวาง
        $this.X += [math]::Sin([DateTime]::Now.Ticks / 5000000.0) * 4
        $this.Y += 0.5
        if ($this.Y -gt 120) { $this.Y = 120 }

        $this.ChargeTimer++
        if ($this.ChargeTimer -gt 120) { 
            $this.State = 1 # เข้าสถานะพร้อมยิง
        }
    }

    [Object] TryShoot([int]$level) {
        if ($this.State -eq 1) {
            $this.State = 0
            $this.ChargeTimer = 0
            
            # จุดเกิดกระสุน: ให้เริ่มจากใต้ตัวบอสลงมาหน่อย (Y + 60)
            $spawnX = [float]($this.X + ($this.Width / 2) - 30)
            $spawnY = [float]($this.Y + $this.Height + 10)
            
            # สร้างและส่งกระสุนออกไป
            return [GluttonyBlast]::new($spawnX, $spawnY, $this.PlayerRef)
        }
        return $null
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $b = New-Object System.Drawing.SolidBrush($this.Color)
        
        # 1. วาดสี่เหลี่ยมแกนกลาง
        $g.FillRectangle($b, [float]($this.X + 15), [float]($this.Y + 10), 50.0, 30.0)
        
        # ฟังก์ชันช่วยวาดสามเหลี่ยม (ป้องกันบั๊ก PointF Casting)
        $drawTriangle = {
            param($p1x, $p1y, $p2x, $p2y, $p3x, $p3y)
            $pts = [System.Drawing.PointF[]]::new(3)
            $pts[0] = New-Object System.Drawing.PointF([float]$p1x, [float]$p1y)
            $pts[1] = New-Object System.Drawing.PointF([float]$p2x, [float]$p2y)
            $pts[2] = New-Object System.Drawing.PointF([float]$p3x, [float]$p3y)
            $g.FillPolygon($b, $pts)
        }

        # วาดสามเหลี่ยม 3 ชิ้น
        & $drawTriangle ($this.X) ($this.Y + 40) ($this.X + 15) ($this.Y + 10) ($this.X + 15) ($this.Y + 40)
        & $drawTriangle ($this.X + 80) ($this.Y + 40) ($this.X + 65) ($this.Y + 10) ($this.X + 65) ($this.Y + 40)
        & $drawTriangle ($this.X + 30) ($this.Y + 40) ($this.X + 50) ($this.Y + 40) ($this.X + 40) ($this.Y + 60)

        # วาดเลข HP (โชว์ความถึก)
        $font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
        $g.DrawString("HP: $($this.HP)", $font, [System.Drawing.Brushes]::White, [float]($this.X + 15), [float]($this.Y - 20))

        # สัญลักษณ์ชาร์จยิง (วงกลมกะพริบ)
        if ($this.ChargeTimer -gt 60) {
            $alpha = [int]([math]::Abs([math]::Sin($this.ChargeTimer * 0.15)) * 255)
            $p = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, 255, 255, 255), 3)
            $g.DrawEllipse($p, [float]($this.X + 10), [float]($this.Y), 60.0, 60.0)
        }
    }
}