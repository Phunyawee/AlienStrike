# src/Entities/Enemies/Sins/Sloth.ps1

class Sloth : BaseEnemy {
    [int]$SlothState = 0 
    [int]$StateTimer = 0
    [float]$TargetX
    [float]$TargetY
    [int]$DropDelay 

    Sloth([float]$x, [float]$y, [float]$tx, [float]$ty, [int]$delay) 
        : base($x, $y, 50, 50, 3, 6, [System.Drawing.Color]::DarkGreen) {
        $this.TargetX = $tx; $this.TargetY = $ty
        $this.DropDelay = $delay
        $this.ScoreValue = 3000
    }

    [void] Update() {
        $this.StateTimer++
        
        switch ($this.SlothState) {
            0 { # Entering: บินเข้าหาจุดเป้าหมาย
                $this.X += ($this.TargetX - $this.X) * 0.05
                $this.Y += ($this.TargetY - $this.Y) * 0.05
                if ([math]::Abs($this.X - $this.TargetX) -lt 2) { 
                    $this.SlothState = 1
                    $this.StateTimer = 0 
                }
            }
            1 { # Idle 1: หยุดรอ (1 วินาที + Delay)
                if ($this.StateTimer -gt (60 + $this.DropDelay)) { 
                    $this.SlothState = 2 # พร้อมทิ้งระเบิด
                }
            }
            2 { # Dropping: (จะถูกเปลี่ยนเป็น State 3 โดย TryShoot)
                # รอให้ TryShoot ทำงาน
            }
            3 { # Idle 2: หยุดรอ 1.5 วินาที หลังทิ้งระเบิด
                if ($this.StateTimer -gt 90) { 
                    $this.SlothState = 4 # พร้อมยิงปกติ
                }
            }
            4 { # Firing: (จะถูกเปลี่ยนเป็น State 5 โดย TryShoot)
                # รอให้ TryShoot ทำงาน
            }
            5 { # Escaping: บินหนีขึ้นด้านบน
                $this.Y -= 5
            }
        }
    }

    [Object] TryShoot([int]$level) {
        # --- จังหวะทิ้งระเบิด SlothBomb ---
        if ($this.SlothState -eq 2) {
            $this.SlothState = 3 # เปลี่ยน State ทันทีที่ทิ้ง
            # เปลี่ยน 450 เป็น 350 (ระเบิดกลางจอพอดี)
            return [SlothBomb]::new($this.X + 10, $this.Y + 40, 350)
        }

        # --- จังหวะยิงกระสุนปกติ 1 นัดก่อนหนี ---
        if ($this.SlothState -eq 4) {
            $this.SlothState = 5 # เปลี่ยน State เป็นหนี
            $this.StateTimer = 0
            return [EnemyBullet]::new($this.X + 22, $this.Y + 40)
        }
        return $null
    }
}