# src/Entities/Enemies/Sins/Azazel.ps1
class Azazel : BaseEnemy {
    [float]$VisualHP
    [float]$SmoothHP
    [System.Collections.ArrayList]$Parts
    [int]$Phase = 0
    [int]$ShotCounter = 0
    [int]$SummonTimer = 0
    [int]$RegenTimer = 0
    [float]$SweepX = -100
    [bool]$IsSweeping = $false
    [float]$SwayAngle = 0 
    [int]$IntroTimer = 180  # 60 FPS * 3 วินาที = 180 เฟรม
    hidden [Object]$PlayerRef

    Azazel([float]$x, [float]$y, [Object]$player) 
        : base($x, $y, 200, 100, 1, 10000, [System.Drawing.Color]::MediumPurple) {
        $this.PlayerRef = $player
        $this.VisualHP = 10000.0
        $this.SmoothHP = 10000.0
        $this.Parts = [System.Collections.ArrayList]::new()
        
        # ปืนใหญ่ 4 กระบอก
        [void]$this.Parts.Add([AzazelPart]::new(-100, 10, 500, 60, 40, "BigGun"))
        [void]$this.Parts.Add([AzazelPart]::new(-40, 10, 500, 60, 40, "BigGun"))
        [void]$this.Parts.Add([AzazelPart]::new(180, 10, 500, 60, 40, "BigGun"))
        [void]$this.Parts.Add([AzazelPart]::new(240, 10, 500, 60, 40, "BigGun"))
        
        # ปืนเล็ก 2 กระบอก
        [void]$this.Parts.Add([AzazelPart]::new(20, 60, 200, 40, 40, "SmallGun"))
        [void]$this.Parts.Add([AzazelPart]::new(140, 60, 200, 40, 40, "SmallGun"))
    }

    [void] UpdateWithPlayer([Object]$player) {
        if ($this.IntroTimer -gt 0) { $this.IntroTimer-- }
        if ($null -eq $player -or $player.PSObject -eq $null) { return }
        $this.PlayerRef = $player

        if ($this.FlashTimer -gt 0) { $this.FlashTimer-- }
        if ($this.VisualHP -gt $this.HP) { $this.VisualHP = $this.HP }
        
        if ($this.SmoothHP -gt $this.VisualHP) { 
            $this.SmoothHP -= 40.0 
            if ($this.SmoothHP -lt $this.VisualHP) { $this.SmoothHP = $this.VisualHP }
        }

        $this.X += ($player.X - 100.0 - $this.X) * 0.02
        if ($this.Y -lt 80) { $this.Y += 0.5 }
        
        $this.SwayAngle = [math]::Sin([DateTime]::Now.Ticks / 2000000.0) * 45.0

        # --- Phase Check ---
        $activeBigGuns = ($this.Parts | Where-Object { $_.Type -eq "BigGun" -and -not $_.IsDestroyed }).Count
        $activeSmallGuns = ($this.Parts | Where-Object { $_.Type -eq "SmallGun" -and -not $_.IsDestroyed }).Count
        
        if ($activeBigGuns -eq 0 -and $this.Phase -eq 0) { 
            $this.Phase = 1 
            Write-Host ">>> BIG GUNS DESTROYED! SHIELDS OFF! <<<" -ForegroundColor Yellow
        }
        if ($activeSmallGuns -eq 0 -and $this.Phase -eq 1) { 
            $this.Phase = 2 
            Write-Host ">>> AZAZEL CORE EXPOSED! <<<" -ForegroundColor Red
        }

        # --- ล็อคเลือดปืนเล็ก Phase 0 ---
        if ($this.Phase -eq 0) {
            foreach ($p in $this.Parts) {
                if ($p.Type -eq "SmallGun") {
                    $p.HP = 200
                    $p.IsDestroyed = $false
                }
            }
        }

        $this.SummonTimer++
        if ($this.SummonTimer -ge 300) { 
            $this.SummonTimer = 0
            $sideX = if ($this.Rnd.Next(0,2) -eq 0) { -50.0 } else { 550.0 }
            [void]$Script:enemies.Add([Watcher]::new($sideX, 100.0, 100.0, 100.0, "Ace"))
        }
        
        if ($this.IsSweeping) {
            $this.SweepX += 15.0 
            if ($this.SweepX -gt 700) { 
                $this.IsSweeping = $false
                $this.SweepX = -100
                $this.ShotCounter = 0 
            }
        } else {
            $this.RegenTimer++ 
        }
    }

    [Object] TryShoot([int]$level) {
        [System.Collections.ArrayList]$finalShots = [System.Collections.ArrayList]::new()
        
        # 1. ปืนใหญ่ยิงทุก 3 วิ (ชุดละ 3 นัด: ห่างกันนัดละ 10 เฟรม)
        $burstTimer = $this.RegenTimer % 180
        if ($this.Phase -eq 0 -and ($burstTimer -eq 0 -or $burstTimer -eq 10 -or $burstTimer -eq 20)) {
            foreach ($p in $this.Parts) {
                if ($p.Type -eq "BigGun" -and -not $p.IsDestroyed) {
                    $rad = ($this.SwayAngle + 90.0) * ([math]::PI / 180.0)
                    $vx = [math]::Cos($rad) * 10.0
                    $vy = [math]::Sin($rad) * 10.0
                    [void]$finalShots.Add([AzazelTriangle]::new([float]($this.X+$p.RelX+30), [float]($this.Y+$p.RelY+20), $vx, $vy))
                }
            }
        }

        # 2. ปืนเล็กเล็งเป้าทุก 2 วิ (มีผลทั้ง Phase 0 และ 1)
        if ($this.Phase -le 1 -and ($this.RegenTimer % 120 -eq 0) -and $null -ne $this.PlayerRef) {
            foreach ($p in $this.Parts) {
                if ($p.Type -eq "SmallGun" -and -not $p.IsDestroyed) {
                    $dx = ($this.PlayerRef.X + 10.0) - ($this.X + $p.RelX + 20.0)
                    $dy = ($this.PlayerRef.Y + 10.0) - ($this.Y + $p.RelY + 20.0)
                    $dist = [math]::Max([math]::Sqrt($dx*$dx + $dy*$dy), 1.0)
                    $vx = ($dx / $dist) * 8.0
                    $vy = ($dy / $dist) * 8.0
                    [void]$finalShots.Add([EnemyBullet]::new([float]($this.X + $p.RelX + 20.0), [float]($this.Y + $p.RelY + 20.0), $vx, $vy))
                }
            }
        }

        # 3. แกนกลาง (Phase 2 - Core Exposed)
        if ($this.Phase -eq 2 -and -not $this.IsSweeping) {
            $activeGr = ($Script:enemyBullets | Where-Object { $_.GetType().Name -eq "AzazelGrenade" }).Count
            if ($activeGr -eq 0 -and ($this.RegenTimer % 60 -eq 0)) {
                if ($this.ShotCounter -lt 10) {
                    $this.ShotCounter++
                    $dx = ($this.PlayerRef.X + 10.0) - ($this.X + 100.0)
                    $dy = ($this.PlayerRef.Y + 10.0) - ($this.Y + 120.0)
                    $dist =[math]::Max([math]::Sqrt($dx*$dx + $dy*$dy), 1.0)
                    [void]$finalShots.Add([AzazelGrenade]::new([float]($this.X+90), [float]($this.Y+110), ($dx/$dist)*6.0, ($dy/$dist)*6.0))
                } else { 
                    $this.IsSweeping = $true 
                }
            }
        }
        
        if ($finalShots.Count -gt 0) { return $finalShots }
        return $null
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $bx = [float]$this.X
        $by = [float]$this.Y
        
        $mainColor = [System.Drawing.Color]::FromArgb(200, 200, 255)
        if ($this.FlashTimer -gt 0) { $mainColor = [System.Drawing.Color]::White }
        $baseB = New-Object System.Drawing.SolidBrush($mainColor)
        
        $redB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
        $darkRedB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::DarkRed)
        $blueB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Blue)
        $blackB =[System.Drawing.Brushes]::Black
        $fontHP = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)

        # 1. หลอดเลือดใหญ่ (กึ่งกลางสนาม 500px)
        $barX = 100.0
        $barW = 300.0
        $barY = 15.0
        $g.FillRectangle([System.Drawing.Brushes]::DimGray, $barX, $barY, $barW, 12.0)
        $g.FillRectangle([System.Drawing.Brushes]::White, $barX, $barY, [float]($barW * ($this.SmoothHP / 10000.0)), 12.0)
        $g.FillRectangle([System.Drawing.Brushes]::Red, $barX, $barY, [float]($barW * ($this.VisualHP / 10000.0)), 12.0)
        $g.DrawString("AZAZEL - THE WAR BRINGER", $fontHP,[System.Drawing.Brushes]::White, $barX, ($barY+15))

        # [คำเตือน] กระพริบใต้หลอดเลือด
        if ($this.Phase -eq 2 -and $this.ShotCounter -ge 7 -and -not $this.IsSweeping) {
            $warnF = New-Object System.Drawing.Font("Impact", 14)
            if (([DateTime]::Now.Millisecond % 400) -lt 200) {
                $g.DrawString("!!! JUDGMENT CANNON READY: $(10-$this.ShotCounter) !!!", $warnF,[System.Drawing.Brushes]::Yellow, ($barX + 35.0), ($barY + 30.0))
            }
        }

        # 2. ตัวยาน
        $g.FillRectangle($baseB, $bx, $by, 200.0, 60.0) # ตัวยานหลัก
        
        # ปรับสีปืนใหญ่กลางเป็นสีเทา (Gray)
        $grayB = [System.Drawing.Brushes]::DimGray 
        $g.FillRectangle($grayB, ($bx+90.0), ($by+60.0), 20.0, 60.0) 
        
        # แกนกลาง (Core) ยังคงเป็นสีแดง
        $g.FillEllipse($redB, ($bx+85.0), ($by+110.0), 30.0, 30.0)

        # 3. ชิ้นส่วน (Parts)
        foreach ($p in $this.Parts) {
            if (-not $p.IsDestroyed) {
                $px = [float]($bx + $p.RelX)
                $py = [float]($by + $p.RelY)
                
                $isPartFlashing = ($p.FlashTimer -gt 0)
                if ($isPartFlashing) { $p.FlashTimer-- }

                $pColor = if ($isPartFlashing) { [System.Drawing.Color]::White } else {[System.Drawing.Color]::Red }
                $pB = New-Object System.Drawing.SolidBrush($pColor)

                if ($p.Type -eq "BigGun") {
                    $g.FillPie($pB, $px, $py, 60.0, 80.0, 180, 180)
                    
                    $state = $g.Save()
                    $g.TranslateTransform(($px + 30.0), ($py + 20.0)) 
                    $g.RotateTransform($this.SwayAngle)
                    $g.FillRectangle($darkRedB, -8.0, 0.0, 16.0, 40.0)
                    $ptsA = [System.Drawing.PointF[]]::new(3)
                    $ptsA[0] = New-Object System.Drawing.PointF(-15.0, 40.0)
                    $ptsA[1] = New-Object System.Drawing.PointF(15.0, 40.0)
                    $ptsA[2] = New-Object System.Drawing.PointF(0.0, 60.0)
                    $g.FillPolygon($blueB, $ptsA)
                    $g.Restore($state)
                } else {
                    if ($null -ne $this.PlayerRef) {
                        $dx = ($this.PlayerRef.X + 10) - ($px + 20)
                        $dy = ($this.PlayerRef.Y + 10) - ($py + 20)
                        $ang = [float]([math]::Atan2($dy, $dx) * (180 / [math]::PI) - 90)
                        
                        $st = $g.Save()
                        $g.TranslateTransform(($px + 20.0), ($py + 20.0))
                        $g.RotateTransform($ang)
                        
                        $ptsT =[System.Drawing.PointF[]]::new(3)
                        $ptsT[0] = New-Object System.Drawing.PointF(-20.0, 20.0)
                        $ptsT[1] = New-Object System.Drawing.PointF(20.0, 20.0)
                        $ptsT[2] = New-Object System.Drawing.PointF(0.0, -20.0)
                        $g.FillPolygon($pB, $ptsT)
                        $g.Restore($st)
                        
                        # --- [ระบบโล่ปืนเล็ก] --- 
                        if ($this.Phase -eq 0) {
                            $shieldP = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 2)
                            $g.DrawEllipse($shieldP,[float]($px - 12.0), [float]($py - 12.0), 64.0, 64.0)
                        }
                    }
                }
                $g.DrawString($p.HP.ToString(), $fontHP, [System.Drawing.Brushes]::White, ($px + 10.0), ($py - 15.0))
            }
        }

         if ($this.IntroTimer -gt 0) {
            $infoX = 100.0
            $infoY = 70.0  # อยู่ใต้หลอดเลือดบอสเล็กน้อย
            $infoW = 300.0
            $infoH = 50.0
            
            # 1. วาดพื้นหลังกล่อง (ดำใส)
            $boxBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
            $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 2)
            
            $g.FillRectangle($boxBrush, $infoX, $infoY, $infoW, $infoH)
            $g.DrawRectangle($borderPen, $infoX, $infoY, $infoW, $infoH)

            # 2. วาดข้อความ
            $fTitle = New-Object System.Drawing.Font("Impact", 10)
            $fDesc = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
            
            $g.DrawString("! TACTICAL ANALYSIS !", $fTitle, [System.Drawing.Brushes]::Yellow, ($infoX + 5), ($infoY + 5))
            $g.DrawString("PARTS: Bullets & Laser ONLY", $fDesc, [System.Drawing.Brushes]::White, ($infoX + 5), ($infoY + 22))
            $g.DrawString("CORE : ALL WEAPONS EFFECTIVE", $fDesc, [System.Drawing.Brushes]::Lime, ($infoX + 5), ($infoY + 34))

            # ทำเอฟเฟกต์กะพริบที่ขอบ
            if (([DateTime]::Now.Millisecond % 400) -lt 200) {
                 $g.DrawRectangle([System.Drawing.Pens]::Red, $infoX, $infoY, $infoW, $infoH)
            }
        }

        # 4. Sweeping Laser
        if ($this.IsSweeping) {
            $g.FillRectangle([System.Drawing.Brushes]::Cyan, [float]$this.SweepX, 0.0, 40.0, 600.0)
            $g.DrawRectangle([System.Drawing.Pens]::White, [float]$this.SweepX, 0.0, 40.0, 600.0)
        }
    }
}