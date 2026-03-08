# src/Entities/Enemies/Sins/Pride.ps1

class Pride : BaseEnemy {
    [int]$State = 0        # 0=เดินตาม, 1=ล็อกเป้า(หยุดนิ่ง 1 วิ), 2=ยิงเลเซอร์, 3=พุ่งทะลวง
    [int]$StateTimer = 0   # ตัวจับเวลาการเปลี่ยน State
    [bool]$HasFired = $false

    Pride([float]$x, [float]$y) 
        # ให้กว้าง 40, สูง 40, ความเร็วแค่ 1 (เดินช้าเย่อหยิ่ง), เลือด 4, สีม่วงแดง (Magenta)
        : base($x, $y, 40, 40, 1, 4, [System.Drawing.Color]::Magenta) {
        
        $this.ScoreValue = 5000 # ค่าหัวแพงสมกับความมั่นหน้า
    }

    # Override การเดิน โดยใช้ตำแหน่งของผู้เล่นเข้ามาคำนวณ!
    [void] UpdateWithPlayer([Object]$player) {
        
        # --- State 0: ตามหาผู้เล่น (เย่อหยิ่ง ค่อยๆ ลอยลงมา และขยับซ้ายขวาตาม) ---
        if ($this.State -eq 0) {
            $this.Y += $this.Speed
            
            # เดินตามแกน X ของผู้เล่น
            $centerX = $this.X + ($this.Width / 2)
            $playerCenterX = $player.X + ($player.Width / 2)
            
            if ($centerX -lt $playerCenterX - 5) { $this.X += $this.Speed + 1 }
            if ($centerX -gt $playerCenterX + 5) { $this.X -= $this.Speed + 1 }

            # ถ้าลงมาถึงระยะนึง (Y=100) จะเริ่มล็อกเป้า
            if ($this.Y -gt 100) {
                $this.State = 1
                $this.StateTimer = 60 # รอ 60 เฟรม (1 วินาที)
            }
        }
        # --- State 1: ล็อกเป้า (หยุดนิ่ง) ---
        elseif ($this.State -eq 1) {
            $this.StateTimer--
            if ($this.StateTimer -le 0) {
                $this.State = 2 # หมด 1 วินาที ไปสถานะยิง
            }
        }
        # --- State 2: ยิงเลเซอร์ (หยุดนิ่งแป๊ปนึงเพื่อให้เลเซอร์แสดงผล) ---
        elseif ($this.State -eq 2) {
            $this.StateTimer++
            if ($this.StateTimer -gt 15) { # ยิงค้างไว้เสี้ยววิ
                $this.State = 3 # ไปสถานะพุ่ง
            }
        }
        # --- State 3: พุ่งทะลวง ---
        elseif ($this.State -eq 3) {
            $this.Y += ($this.Speed * 4) # พุ่งลงล่างเร็วสุดๆ
        }
    }

    # ท่ายิง (ปล่อยเลเซอร์ยักษ์)
    [Object] TryShoot([int]$currentLevel) {
        # ถ้าอยู่ใน State 2 และยังไม่เคยยิง
        if ($this.State -eq 2 -and -not $this.HasFired) {
            $this.HasFired = $true
            
            # ปล่อยกระสุนเลเซอร์ออกมาตรงกลางลำตัว (ยิงลงไป 600 px)
            $laserX = $this.X + ($this.Width / 2) - 13
            $laserY = $this.Y + $this.Height
            
            return [PrideLaser]::new($laserX, $laserY)
        }
        return $null
    }

    # วาดเส้นเล็งตอนล็อกเป้า (Telegraph)
    [void] Draw([System.Drawing.Graphics]$g) {
        # วาดตัวมันเองแบบปกติก่อน
        ([GameObject]$this).Draw($g)
        
        # กิมมิคหลอดเลือดบนหัว
        if ($this.HP -lt $this.MaxHP -and $this.HP -gt 0) {
            $healthPercent = $this.HP / $this.MaxHP
            $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::DarkRed)
            $hpBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Lime)
            $g.FillRectangle($bgBrush, $this.X, ($this.Y - 6), $this.Width, 3)
            $g.FillRectangle($hpBrush, $this.X, ($this.Y - 6), ($this.Width * $healthPercent), 3)
        }

        # *** กิมมิคพิเศษ: วาดเส้นเล็งสีแดงบางๆ ตอน State 1 (กำลังล็อกเป้า) ***
        if ($this.State -eq 1) {
            $centerX = $this.X + ($this.Width / 2)
            $startY = $this.Y + $this.Height
            $aimPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 255, 0, 0), 2)
            $aimPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash # เส้นประ
            
            $g.DrawLine($aimPen, $centerX, $startY, $centerX, 600)
        }
    }
}