# src/Entities/Projectiles/SlothBomb.ps1

class SlothBomb : EnemyBullet {
    [int]$Timer = 0
    [int]$State = 0 
    [float]$TargetY

    SlothBomb([float]$x, [float]$y, [float]$targetY) : base($x, $y, 0, 4) {
        $this.Width = 20; $this.Height = 20
        $this.TargetY = $targetY
        $this.Color = [System.Drawing.Color]::Lime
    }

    [void] Update() {
        if ($this.State -lt 3) {
            if ($this.Y -lt $this.TargetY) {
                $this.Y += $this.SpeedY 
            } else {
                $this.Y = $this.TargetY # ล็อคตำแหน่ง Y ให้แม่นยำ
                $this.Timer++
                if ($this.Timer -gt 30 -and $this.State -eq 0) { $this.Color = [System.Drawing.Color]::Yellow; $this.State = 1 }
                if ($this.Timer -gt 60 -and $this.State -eq 1) { $this.Color = [System.Drawing.Color]::Red; $this.State = 2 }
                if ($this.Timer -gt 80 -and $this.State -eq 2) { $this.State = 3 } 
            }
        }
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $brush = New-Object System.Drawing.SolidBrush($this.Color)
        $g.FillEllipse($brush, $this.X, $this.Y, $this.Width, $this.Height)
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 1)
        $g.DrawEllipse($pen, $this.X, $this.Y, $this.Width, $this.Height)
    }

    [Object] GetShockwave() {
        # คำนวณจุดศูนย์กลางระเบิดให้เป๊ะ
        $centerX = $this.X + ($this.Width / 2)
        $centerY = $this.Y + ($this.Height / 2)
        
        # ลดความกว้างลง 30% (จาก 350 เหลือ 250)
        # และส่งค่า Y ปัจจุบันของลูกระเบิดไป
        return [SlothShockwave]::new($centerX - 125, $centerY)
    }
}

class SlothShockwave : EnemyBullet {
    [int]$Life = 40 

    SlothShockwave([float]$x, [float]$y) : base($x, $y, 0, 0) {
        $this.Width = 250  # ลดความกว้างลงตามสั่ง (ประมาณ 30%)
        $this.Height = 150 # ความสูงกำลังดี
        $this.Color = [System.Drawing.Color]::FromArgb(150, 255, 69, 0)
    }

    [void] Update() { 
        $this.Life--
        if ($this.Life -le 0) { $this.Y = 2000 } 
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $brush = New-Object System.Drawing.SolidBrush($this.Color)
        
        # วาดครึ่งวงกลมโดยเริ่มจากจุด Y ของระเบิดพอดี
        # FillPie(Brush, X, Y, Width, Height, StartAngle, SweepAngle)
        # 0 ถึง 180 องศา คือครึ่งวงกลมคว่ำลง
        $g.FillPie($brush, $this.X, $this.Y, $this.Width, $this.Height * 2, 0, 180)
        
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Orange, 3)
        $g.DrawArc($pen, $this.X, $this.Y, $this.Width, $this.Height * 2, 0, 180)
    }
}