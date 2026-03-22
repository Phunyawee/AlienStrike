# src/Entities/Enemies/Sins/Nephilim.ps1

class Nephilim : BaseEnemy {
    [int]$Phase = 0 
    [int]$LaserHP = 400 # ลดเหลือ 400
    [int]$LeftBladeHP = 200; [int]$RightBladeHP = 200 # ลดเหลือ 200
    [int]$NextBladeSide = 0 # 0=ซ้าย, 1=ขวา
    [int]$RegenTimer = 0
    [int]$SummonTimer = 0
    [float]$SpinAngle = 0
    [float]$ChargeTimer = 0
    hidden [Object]$PlayerRef

    Nephilim([float]$x, [float]$y, [Object]$player) 
        : base($x, $y, 160, 60, 2, 500, [System.Drawing.Color]::DarkBlue) { # ตัวแม่ HP 500
        $this.PlayerRef = $player
        $this.ScoreValue = 150000
    }

    [void] UpdateWithPlayer([Object]$player) {
        if ($this.FlashTimer -gt 0) { $this.FlashTimer-- }
        $this.SpinAngle += 15.0
        
        # การเคลื่อนที่: ติดตามผู้เล่นช้าๆ
        $targetX = [float]($player.X - 60.0)
        $this.X += ($targetX - $this.X) * 0.02
        if ($this.Y -lt 120.0) { $this.Y += 1.0 }

        # --- ลอจิก Phase ---
        if ($this.LaserHP -le 0 -and $this.Phase -eq 0) { 
            $this.Phase = 1 
            Write-Host ">>> NEPHILIM: PHASE 1 ACTIVATED <<<" -ForegroundColor Yellow
        }
        if ($this.LeftBladeHP -le 0 -and $this.RightBladeHP -le 0 -and $this.Phase -eq 1) {
            $this.Phase = 2
            Write-Host ">>> NEPHILIM: PHASE 2 - FRAGILE <<<" -ForegroundColor Red
        }

        # --- การเรียก Watcher แดง (Ace) ---
        $this.SummonTimer++
        if ($this.SummonTimer -ge 240) {
            $this.SummonTimer = 0
            $sideX = if ($this.Rnd.Next(0,2) -eq 0) { -50.0 } else { 550.0 }
            [void]$Script:enemies.Add([Watcher]::new($sideX, 200.0, 100.0, 200.0, "Ace")) 
        }

        # --- การยิง Laser (Phase 0) ---
        if ($this.Phase -eq 0) {
            $this.ChargeTimer += 0.016
            if ($this.ChargeTimer -gt 3.5) { $this.ChargeTimer = 0 }
        } else {
            $this.RegenTimer++ # นับเวลาโยนใบพัด
        }
    }

    [Object] TryShoot([int]$level) {
        $shots = [System.Collections.ArrayList]::new()
        # --- [แก้ไข] โยนทีละอันสลับกันทุก 1.5 วิ (90 เฟรม) ---
        if ($this.Phase -eq 1 -and $this.RegenTimer -ge 90) {
            $this.RegenTimer = 0
            if ($this.NextBladeSide -eq 0) {
                if ($this.LeftBladeHP -gt 0) { [void]$shots.Add([NephilimBlade]::new($this.X + 30, $this.Y, $this.PlayerRef)) }
                $this.NextBladeSide = 1
            } else {
                if ($this.RightBladeHP -gt 0) { [void]$shots.Add([NephilimBlade]::new($this.X + 130, $this.Y, $this.PlayerRef)) }
                $this.NextBladeSide = 0
            }
        }
        if ($shots.Count -gt 0) { return $shots }
        return $null
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $bx = [float]$this.X; $by = [float]$this.Y
        
        # --- 1. เตรียมสี (ห้ามใช้ IF ในวงเล็บ) ---
        $mainColor = [System.Drawing.Color]::DarkBlue
        if ($this.FlashTimer -gt 0) { $mainColor = [System.Drawing.Color]::White }
        
        $blueB = New-Object System.Drawing.SolidBrush($mainColor)
        $redB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Crimson)
        $cyanB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::DeepSkyBlue)
        $shieldP = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 0, 255, 255), 2)

        # 2. วาดก้านปืน
        $g.FillRectangle([System.Drawing.Brushes]::Maroon, ($bx + 25.0), ($by - 20.0), 10.0, 40.0)
        $g.FillRectangle([System.Drawing.Brushes]::Maroon, ($bx + 125.0), ($by - 20.0), 10.0, 40.0)

        # 3. วาดใบพัด (ScriptBlock แก้ไขให้ไม่มี IF ในบรรทัดวาด)
        $drawBlade = { 
            param($x, $y, $hp, $flash, $phase)
            if ($hp -gt 0) {
                $state = $g.Save()
                $g.TranslateTransform($x, $y)
                $g.RotateTransform($this.SpinAngle)
                
                # เลือก Brush สำหรับใบพัด
                $currentBladeBrush = $cyanB
                if ($flash -gt 0) { $currentBladeBrush = [System.Drawing.Brushes]::White }
                
                $g.FillRectangle($currentBladeBrush, -20.0, -6.0, 40.0, 12.0)
                $g.FillRectangle($currentBladeBrush, -6.0, -20.0, 12.0, 40.0)
                $g.Restore($state)
                
                # วาดโล่ถ้า Phase ยังไม่ถึง 1
                if ($phase -eq 0) { 
                    $g.DrawEllipse($shieldP, ($x - 25.0), ($y - 25.0), 50.0, 50.0) 
                }
            }
        }
        & $drawBlade ($bx + 30.0) ($by - 20.0) $this.LeftBladeHP $this.FlashTimer $this.Phase
        & $drawBlade ($bx + 130.0) ($by - 20.0) $this.RightBladeHP $this.FlashTimer $this.Phase

        # 4. ตัวยานและหลอดเลือด
        $g.FillRectangle($blueB, $bx, $by, 160.0, 50.0)
        
        # วาดโล่ครอบตัวแม่
        if ($this.Phase -lt 2) { 
            $g.DrawRectangle($shieldP, ($bx - 5.0), ($by - 5.0), 170.0, 60.0) 
        }
        
        # 5. หลอดเลือดตัวแม่ (ใช้ MaxHP เพื่อความแม่นยำ)
        $g.FillRectangle([System.Drawing.Brushes]::DimGray, $bx, ($by - 40.0), 160.0, 10.0)
        
        # คำนวณสัดส่วนเลือดจริง (HP 500)
        $hpRatio = [float]($this.HP / $this.MaxHP)
        $g.FillRectangle([System.Drawing.Brushes]::Lime, $bx, ($by - 40.0), [float](160.0 * $hpRatio), 10.0)
        $g.DrawRectangle([System.Drawing.Pens]::White, $bx, ($by - 40.0), 160.0, 10.0)

        # --- [NEW] เพิ่มเลขเลือดใบพัดให้เห็นชัดๆ ---
        $fontB = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        if ($this.LeftBladeHP -gt 0) { $g.DrawString("L:$($this.LeftBladeHP)", $fontB, [System.Drawing.Brushes]::Cyan, [float]($this.X + 5), [float]($this.Y - 35)) }
        if ($this.RightBladeHP -gt 0) { $g.DrawString("R:$($this.RightBladeHP)", $fontB, [System.Drawing.Brushes]::Cyan, [float]($this.X + 115), [float]($this.Y - 35)) }

        # 4. ปืนเลเซอร์กลาง (ปรับให้ต่ำลงมาเพื่อให้ยิงโดนง่ายขึ้น)
        if ($this.LaserHP -gt 0) {
            $pts = [System.Drawing.PointF[]]::new(3)
            # เลื่อนลงมาจากเดิม (30 -> 45) และหัวแหลม (70 -> 85)
            $pts[0] = New-Object System.Drawing.PointF(($bx + 60.0), ($by + 45.0))
            $pts[1] = New-Object System.Drawing.PointF(($bx + 100.0), ($by + 45.0))
            $pts[2] = New-Object System.Drawing.PointF(($bx + 80.0), ($by + 85.0))
            $g.FillPolygon($redB, $pts)
            
            # --- [NEW] วาดเลขเลือดปืนเลเซอร์ ---
            $font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
            $g.DrawString("GUN:$($this.LaserHP)", $font, [System.Drawing.Brushes]::Red, [float]($bx + 62.0), [float]($by + 30.0))

            # เส้นเล็ง (ปรับพิกัดตามปลายกระบอกใหม่)
            if ($this.ChargeTimer -gt 1.5 -and $this.ChargeTimer -lt 2.5) {
                $aimP = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 2)
                $aimP.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
                $g.DrawLine($aimP, ($bx + 80.0), ($by + 85.0), ($bx + 80.0), 600.0)
            }
            # ลำแสงเลเซอร์ (ปรับพิกัดตามปลายกระบอกใหม่)
            if ($this.ChargeTimer -ge 2.5) {
                $beamB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 255, 255))
                $beamP = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 4)
                $g.FillRectangle($beamB, ($bx + 65.0), ($by + 85.0), 30.0, 600.0)
                $g.DrawRectangle($beamP, ($bx + 65.0), ($by + 85.0), 30.0, 600.0)
            }
        }
    }

    [bool] TakeDamage([int]$dmg) {
        $this.HP -= $dmg
        if ($this.HP -lt 0) { $this.HP = 0 }
        $this.FlashTimer = 3
        return ($this.HP -le 0)
    }
}