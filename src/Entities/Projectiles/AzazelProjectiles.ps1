# src/Entities/Projectiles/AzazelProjectiles.ps1

class AzazelTriangle : EnemyBullet {
    AzazelTriangle([float]$x, [float]$y, [float]$sx, [float]$sy) : base($x, $y, $sx, $sy) {
        $this.Width = 20; $this.Height = 20; $this.Color = [System.Drawing.Color]::OrangeRed
    }
    
    [void] Draw([System.Drawing.Graphics]$g) {
        $b = New-Object System.Drawing.SolidBrush($this.Color)
        $px = [float]$this.X; $py = [float]$this.Y
        $pw = [float]$this.Width; $ph = [float]$this.Height

        # --- [แก้จุดบั๊ก PointF] วาดหัวกระสุนสามเหลี่ยมชี้ลง ---
        $pts = [System.Drawing.PointF[]]::new(3)
        $pts[0] = New-Object System.Drawing.PointF($px, $py)
        $pts[1] = New-Object System.Drawing.PointF([float]($px + $pw), $py)
        $pts[2] = New-Object System.Drawing.PointF([float]($px + ($pw / 2.0)), [float]($py + $ph))
        
        $g.FillPolygon($b, $pts)
    }
}

class AzazelGrenade : EnemyMissile {
    [int]$GState = 0 # 0:Falling, 1:Priming1, 2:Explode1, 3:Priming2, 4:Explode2
    [int]$Timer = 0
    [float]$RealVX
    [float]$RealVY
    [float]$CenterX = 0 
    [float]$CenterY = 0 

    AzazelGrenade([float]$x, [float]$y,[float]$vx, [float]$vy) : base($x, $y) {
        $this.RealVX = $vx
        $this.RealVY = $vy
        $this.Width = 20
        $this.Height = 20
        $this.Color = [System.Drawing.Color]::Red
        $this.IsExploding = $false # เริ่มต้นยังไม่ระเบิด
    }

    [void] Update() {
        $this.Timer++
        switch ($this.GState) {
            0 { # Falling
                $this.X += $this.RealVX
                $this.Y += $this.RealVY
                if ($this.Y -gt 500) { 
                    $this.Y = 500
                    $this.GState = 1
                    $this.Timer = 0 
                    $this.CenterX = $this.X + 10.0
                    $this.CenterY = $this.Y + 10.0
                }
            }
            1 { # Priming 1 (กะพริบก่อนระเบิดครั้งแรก)
                $this.Color = if (($this.Timer % 10) -lt 5) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Red }
                if ($this.Timer -gt 30) { 
                    $this.GState = 2
                    $this.Timer = 0
                    
                    # ขยายวงระเบิดรอบแรก 1.5 เท่า (จาก 80 เป็น 120)
                    $this.Width = 120
                    $this.Height = 120
                    $this.X = $this.CenterX - 60.0
                    $this.Y = $this.CenterY - 60.0
                    $this.IsExploding = $true # เปิด Damage
                }
            }
            2 { # Explode 1 (ระเบิดวงเล็ก - ตอนนี้ขนาด 120 แล้ว)
                if ($this.Timer -gt 15) { 
                    $this.GState = 3
                    $this.Timer = 0
                    $this.Width = 20
                    $this.Height = 20
                    $this.X = $this.CenterX - 10.0
                    $this.Y = $this.CenterY - 10.0
                    $this.IsExploding = $false # ปิด Damage ชั่วคราวช่วงพักระเบิด
                }
            }
            3 { # Priming 2 (กะพริบก่อนระเบิดยักษ์)
                $this.Color = if (($this.Timer % 6) -lt 3) { [System.Drawing.Color]::Yellow } else {[System.Drawing.Color]::OrangeRed }
                if ($this.Timer -gt 40) { 
                    $this.GState = 4
                    $this.Timer = 0
                    $this.Width = 180
                    $this.Height = 180
                    $this.X = $this.CenterX - 90.0
                    $this.Y = $this.CenterY - 90.0
                    $this.IsExploding = $true # เปิด Damage อีกรอบ (ระเบิดยักษ์)
                }
            }
            4 { # Explode 2 (ระเบิดยักษ์)
                if ($this.Timer -gt 20) { 
                    $this.IsExploding = $false
                    $this.Y = 2000 # หายไปจริง
                }
            }
        }
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        if ($this.GState -eq 0) {
            $b = New-Object System.Drawing.SolidBrush($this.Color)
            $g.FillEllipse($b, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
        } 
        elseif ($this.GState -eq 1) {
            $b = New-Object System.Drawing.SolidBrush($this.Color)
            $g.FillEllipse($b, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
            # แก้เส้นวงเตือนตามขนาดใหม่ (120)
            $pWarn = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 2)
            $g.DrawEllipse($pWarn, [float]($this.CenterX - 60.0), [float]($this.CenterY - 60.0), 120.0, 120.0)
        }
        elseif ($this.GState -eq 3) {
            $b = New-Object System.Drawing.SolidBrush($this.Color)
            $g.FillEllipse($b, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
            $pWarn = New-Object System.Drawing.Pen([System.Drawing.Color]::OrangeRed, 2)
            $pWarn.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
            $g.DrawEllipse($pWarn, [float]($this.CenterX - 90.0),[float]($this.CenterY - 90.0), 180.0, 180.0)
        } 
        else {
            $alpha = if ($this.GState -eq 2) { 150 } else { 200 }
            $expB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 69, 0))
            $g.FillEllipse($expB, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
        }
    }
}