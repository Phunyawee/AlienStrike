class Greed : BaseEnemy {
    [float]$Angle = 0
    [float]$CenterX; [float]$CenterY
    [float]$OrbitRadius = 60
    [int]$LifeTimer = 0
    [bool]$HasFired = $false
    hidden [Object]$PlayerRef

    Greed([float]$x, [float]$y, [Object]$player) : base($x, $y, 40, 40, 12, 3, [System.Drawing.Color]::Gold) {
        $this.CenterX = $x; $this.CenterY = $y
        $this.PlayerRef = $player
        $this.ScoreValue = 10000
    }

    [void] Update() {
        $this.LifeTimer++
        
        # บินเป็นวงกลม (ความเร็วเร็วกว่า Lust 50% -> ปรับมุม Angle เพิ่มขึ้นเร็วๆ)
        $this.Angle += 0.25 
        $this.X = $this.CenterX + [math]::Cos($this.Angle) * $this.OrbitRadius
        $this.Y = $this.CenterY + [math]::Sin($this.Angle) * $this.OrbitRadius

        # ถ้าครบ 2 วินาที (120 เฟรม) ระเบิดตัวเองหายไป
        if ($this.LifeTimer -gt 120) {
            $this.Y = 2000 
        }
    }

    [Object] TryShoot([int]$level) {
        # ยิงทันทีหลังจากโชว์ตัวไปได้ 0.5 วินาที
        if (-not $this.HasFired -and $this.LifeTimer -gt 30) {
            $this.HasFired = $true
            return [GreedArrow]::new($this.X + 12, $this.Y + 12, $this.PlayerRef)
        }
        return $null
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $brush = New-Object System.Drawing.SolidBrush($this.GetFlashColor())
        
        # สร้างอาเรย์พิกัดแบบระบุชนิดชัดเจน (วิธีนี้ปลอดภัยที่สุด)
        $starPoints = [System.Drawing.PointF[]]::new(10)
        
        for ($i = 0; $i -lt 10; $i++) {
            $r = if ($i % 2 -eq 0) { 20.0 } else { 8.0 }
            $angleRad = ($i * 36) * ([math]::PI / 180)
            
            # บังคับทุกตัวแปรเป็น [float] ก่อนทำการบวก (+) เพื่อกันบั๊ก op_Addition
            $px = [float]$this.X + [float]20.0 + [float]($r * [math]::Cos($angleRad))
            $py = [float]$this.Y + [float]20.0 + [float]($r * [math]::Sin($angleRad))
            
            $starPoints[$i] = New-Object System.Drawing.PointF($px, $py)
        }
        
        $g.FillPolygon($brush, $starPoints)

        # วาดหลอดเลือด
        if ($this.HP -lt $this.MaxHP) {
            $hpBarWidth = [float]($this.Width * ($this.HP / $this.MaxHP))
            $g.FillRectangle([System.Drawing.Brushes]::Red, [float]$this.X, [float]($this.Y - 10), [float]$this.Width, 4.0)
            $g.FillRectangle([System.Drawing.Brushes]::Lime, [float]$this.X, [float]($this.Y - 10), $hpBarWidth, 4.0)
        }
    }
}