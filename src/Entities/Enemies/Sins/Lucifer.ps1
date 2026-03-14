class Lucifer : BaseEnemy {
    [float]$VisualHP; [float]$SmoothHP
    [int]$ArmorHP = 0
    [float]$ChargeTimer = 0
    [int]$SummonTimer = 0
    [int]$GluttonyTimer = 0
    [System.Collections.ArrayList]$Parts
    [int]$Phase = 0 
    [bool]$PlayerLocked = $false
    [bool]$ArmorActivated = $false # <--- [เพิ่มตัวแปรล็อค]
    hidden [Object]$PlayerRef

    Lucifer([float]$x, [float]$y, [Object]$player) 
        : base($x, $y, 100, 100, 1, 20000, [System.Drawing.Color]::BlueViolet) {
        $this.PlayerRef = $player
        $this.VisualHP = 20000; $this.SmoothHP = 20000
        $this.Parts = [System.Collections.ArrayList]::new()
        $this.ScoreValue = 1000000

        [void]$this.Parts.Add([LuciferPart]::new(-80, 30, 2000, 40, 80, "Cannon")) 
        [void]$this.Parts.Add([LuciferPart]::new(140, 30, 2000, 40, 80, "Cannon")) 
        [void]$this.Parts.Add([LuciferPart]::new(10, -50, 400, 35, 35, "Turret")) 
        [void]$this.Parts.Add([LuciferPart]::new(55, -50, 400, 35, 35, "Turret")) 
    }

    [void] UpdateWithPlayer([Object]$player) {
        if ($this.VisualHP -gt $this.HP) { $this.VisualHP = $this.HP }
        if ($this.SmoothHP -gt $this.VisualHP) { $this.SmoothHP -= 40 }

        $this.X += ($player.X - 40 - $this.X) * 0.02
        if ($this.Y -lt 100) { $this.Y += 0.5 }

        $activeCannons = ($this.Parts | Where-Object { $_.Type -eq "Cannon" -and -not $_.IsDestroyed }).Count
        $activeTurrets = ($this.Parts | Where-Object { $_.Type -eq "Turret" -and -not $_.IsDestroyed }).Count
        if ($activeCannons -eq 0 -and $this.Phase -eq 0) { $this.Phase = 1 }
        if ($activeTurrets -eq 0 -and $this.Phase -eq 1) { $this.Phase = 2 }

         # -----------------------------------------------------------------------
        # [แก้บัค Nuke]: ล็อกเลือดปืนเล็กไว้ที่ 400 เสมอ ถ้ายังอยู่ Phase 0
        # -----------------------------------------------------------------------
        if ($this.Phase -eq 0) {
            foreach ($p in $this.Parts) {
                if ($p.Type -eq "Turret") {
                    $p.HP = 400
                    $p.IsDestroyed = $false
                }
            }
        }
        # -----------------------------------------------------------------------

        $this.PlayerLocked = $false
        $px = [float]($player.X + 10.0)
        foreach ($p in ($this.Parts | Where-Object { $_.Type -eq "Cannon" -and -not $_.IsDestroyed })) {
            if ([math]::Abs(($this.X + $p.RelX + 20.0) - $px) -lt 25) { $this.PlayerLocked = $true }
        }
        if ($this.Phase -ge 1 -and [math]::Abs(($this.X + 50.0) - $px) -lt 25) { $this.PlayerLocked = $true }

        if ($this.HP -lt 1000 -and -not $this.ArmorActivated) { 
            $this.ArmorHP = 1000 
            $this.ArmorActivated = $true # ล็อคทันที บรรทัดนี้จะไม่ทำงานอีกเลย
            Write-Host ">>> LUCIFER: FINAL ARMOR DEPLOYED! <<<" -ForegroundColor Cyan
        }
        if ($this.HP -lt 7000) { $this.SummonTimer++ }
        if ($this.Phase -ge 1) { $this.GluttonyTimer++ }

        $this.ChargeTimer += 0.016
        if ($this.ChargeTimer -gt 4.0) { $this.ChargeTimer = 0 }
    }

    [Object] TryShoot([int]$level) {
        $results = [System.Collections.ArrayList]::new()
        if ($this.SummonTimer -ge 180) {
            $this.SummonTimer = 0
            [void]$results.Add([Wrath]::new([float]($this.X + 40), [float]($this.Y + 100), 5))
        }
        if ($this.Phase -eq 1 -and ([math]::Floor($this.ChargeTimer * 60) % 90 -eq 0)) {
            foreach ($p in ($this.Parts | Where-Object { $_.Type -eq "Turret" -and -not $_.IsDestroyed })) {
                [void]$results.Add([EnemyBullet]::new([float]($this.X + $p.RelX + 15), [float]($this.Y + $p.RelY + 20), 0, 15))
            }
        }
        if ($this.Phase -ge 1 -and $this.GluttonyTimer -ge 180) {
            $this.GluttonyTimer = 0
            [void]$results.Add([GluttonyBlast]::new([float]($this.X + 20), [float]($this.Y + 80), $this.PlayerRef))
        }
        if ($results.Count -gt 0) { return $results }
        return $null
    }

    [void] Draw([System.Drawing.Graphics]$g) {
        $bx = [float]$this.X; $by = [float]$this.Y

        # --- 1. จัดการระบบกะพริบ (Flash Logic) ---
        $isMainFlashing = ($this.FlashTimer -gt 0)
        if ($isMainFlashing) { $this.FlashTimer-- }

        # กำหนดสีตามสถานะกะพริบ
        $coreColor = if ($isMainFlashing) { [System.Drawing.Color]::White } else { $this.Color }
        $wingColor = if ($isMainFlashing) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Red }
        
        $coreB = New-Object System.Drawing.SolidBrush($coreColor)
        $wingB = New-Object System.Drawing.SolidBrush($wingColor)
        $blueB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Blue)
        $darkB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::DarkBlue)
        $shieldP = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 0, 255, 255), 2)

        # --- 2. วาดโครงสร้างกากบาท X ---
        $g.FillRectangle($wingB, ($bx - 50.0), ($by + 40.0), 200.0, 20.0)
        
        $p1 = [System.Drawing.PointF[]]::new(4)
        $p1[0]=New-Object System.Drawing.PointF(($bx-40.0),($by-40.0)); $p1[1]=New-Object System.Drawing.PointF(($bx+140.0),($by+140.0))
        $p1[2]=New-Object System.Drawing.PointF(($bx+120.0),($by+140.0)); $p1[3]=New-Object System.Drawing.PointF(($bx-60.0),($by-40.0))
        $g.FillPolygon($wingB, $p1)

        $p2 = [System.Drawing.PointF[]]::new(4)
        $p2[0]=New-Object System.Drawing.PointF(($bx+140.0),($by-40.0)); $p2[1]=New-Object System.Drawing.PointF(($bx-40.0),($by+140.0))
        $p2[2]=New-Object System.Drawing.PointF(($bx-20.0),($by+140.0)); $p2[3]=New-Object System.Drawing.PointF(($bx+160.0),($by-40.0))
        $g.FillPolygon($wingB, $p2)

        # --- 3. วาดชิ้นส่วน (Parts) ---
        $fontHP = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        foreach ($p in $this.Parts) {
            if (-not $p.IsDestroyed) {
                $isPartFlashing = ($p.FlashTimer -gt 0)
                if ($isPartFlashing) { $p.FlashTimer-- }

                $pColor = if ($isPartFlashing) { [System.Drawing.Color]::White } 
                          else { if ($p.Type -eq "Cannon") { [System.Drawing.Color]::Blue } else { [System.Drawing.Color]::DarkBlue } }
                
                $pBrush = New-Object System.Drawing.SolidBrush($pColor)
                $px = [float]($bx + $p.RelX); $py = [float]($by + $p.RelY)

                if ($p.Type -eq "Cannon") {
                    $rectH = [float]($p.Height * 0.7)
                    $g.FillRectangle($pBrush, $px, $py, [float]$p.Width, $rectH)
                    $tri = [System.Drawing.PointF[]]::new(3)
                    $tri[0]=New-Object System.Drawing.PointF($px, ($py+$rectH)); $tri[1]=New-Object System.Drawing.PointF(($px+$p.Width), ($py+$rectH)); $tri[2]=New-Object System.Drawing.PointF(($px+20.0), ($py+$p.Height))
                    $g.FillPolygon($pBrush, $tri)
                } else {
                    $dx = ($this.PlayerRef.X + 10.0) - ($px + 17.0); $dy = ($this.PlayerRef.Y + 10.0) - ($py + 17.0)
                    $ang = [float][math]::Atan2($dy, $dx)
                    $triT = [System.Drawing.PointF[]]::new(3)
                    $triT[0]=New-Object System.Drawing.PointF(($px+17.0+20.0*[math]::Cos($ang)),($py+17.0+20.0*[math]::Sin($ang)))
                    $triT[1]=New-Object System.Drawing.PointF(($px+17.0+15.0*[math]::Cos($ang+2.5)),($py+17.0+15.0*[math]::Sin($ang+2.5)))
                    $triT[2]=New-Object System.Drawing.PointF(($px+17.0+15.0*[math]::Cos($ang-2.5)),($py+17.0+15.0*[math]::Sin($ang-2.5)))
                    $g.FillPolygon($pBrush, $triT)
                    if ($this.Phase -lt 1) { $g.DrawEllipse($shieldP, ($px-5.0), ($py-5.0), ([float]$p.Width+10.0), ([float]$p.Height+10.0)) }
                }
                $g.DrawString($p.HP.ToString(), $fontHP, [System.Drawing.Brushes]::White, $px, ($py - 12.0))
            }
        }

        # --- 4. วาดเส้นเล็ง (Telegraph) ---
        $centerX = [float]($bx + 50.0)
        if ($this.ChargeTimer -gt 1.5 -and $this.ChargeTimer -lt 2.5) {
            $pDash = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 2)
            $pDash.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
            foreach ($p in ($this.Parts | Where-Object { $_.Type -eq "Cannon" -and -not $_.IsDestroyed })) {
                $lx = [float]($bx + $p.RelX + 20.0)
                $g.DrawLine($pDash, $lx, [float]($by + 80.0), $lx, 600.0)
            }
            if ($this.Phase -gt 0) { $g.DrawLine($pDash, $centerX, [float]($by + 100), $centerX, 600.0) }
        }

        # --- 5. วาดลำแสงเลเซอร์ (Fatal Beam) ---
        if ($this.ChargeTimer -ge 2.5) {
            $beamB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 255, 255, 255))
            $beamP = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 4)
            foreach ($p in ($this.Parts | Where-Object { $_.Type -eq "Cannon" -and -not $_.IsDestroyed })) {
                $lx = [float]($bx + $p.RelX + 5.0)
                $g.FillRectangle($beamB, $lx, [float]($by + 80.0), 30.0, 600.0)
                $g.DrawRectangle($beamP, $lx, [float]($by + 80.0), 30.0, 600.0)
            }
            if ($this.Phase -gt 0) { 
                $lx = [float]($bx + 35.0)
                $g.FillRectangle($beamB, $lx, [float]($by + 100.0), 30.0, 600.0)
                $g.DrawRectangle($beamP, $lx, [float]($by + 100.0), 30.0, 600.0)
            }
        }

        # --- 6. วาด Core และสถานะบอส ---
        $g.FillRectangle($coreB, $bx, $by, 100.0, 100.0)

        if ($this.Phase -eq 2) {
            $fragileFont = New-Object System.Drawing.Font("Impact", 12, [System.Drawing.FontStyle]::Italic)
            if (([DateTime]::Now.Millisecond % 400) -lt 200) {
                $g.DrawString(">>> FRAGILE <<<", $fragileFont, [System.Drawing.Brushes]::Yellow, ($bx + 15.0), ($by + 110.0))
            }
        }

        $hpT = "$([math]::Floor($this.HP / 1000.0))K"; $fHP = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
        $g.DrawString($hpT, $fHP, [System.Drawing.Brushes]::White, ($bx + 25.0), ($by + 40.0))
        if ($this.Phase -lt 2) { $g.DrawRectangle($shieldP, ($bx-10.0), ($by-10.0), 120.0, 120.0) }

        # --- 7. วาดเป้าเล็งที่ตัวผู้เล่น (Lock-on) ---
        if ($this.PlayerLocked -and $this.ChargeTimer -lt 2.5) {
            $pL = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 3)
            $pX = [float]$this.PlayerRef.X; $pY = [float]$this.PlayerRef.Y
            $g.DrawEllipse($pL, ($pX - 5.0), ($pY - 5.0), 31.0, 31.0)
            $g.DrawLine($pL, ($pX + 10.0), ($pY - 15.0), ($pX + 10.0), ($pY + 35.0))
            $g.DrawLine($pL, ($pX - 15.0), ($pY + 10.0), ($pX + 35.0), ($pY + 10.0))
        }

        # --- 8. Charging Gauge ---
        if ($this.ChargeTimer -gt 1.0 -and $this.ChargeTimer -lt 2.5) {
            $gw = [float](100.0 * ($this.ChargeTimer - 1.0) / 1.5)
            $g.FillRectangle([System.Drawing.Brushes]::Yellow, $bx, ($by - 20.0), $gw, 6.0)
        }

        # --- 9. Summon Portal (HP < 7000) ---
        if ($this.HP -lt 7000) {
            if (([DateTime]::Now.Millisecond % 500) -lt 250) {
                $portalP = New-Object System.Drawing.Pen([System.Drawing.Color]::Magenta, 5)
                $g.DrawEllipse($portalP, ($bx - 10.0), ($by - 10.0), 120.0, 120.0)
                $g.DrawEllipse($portalP, ($bx - 30.0), ($by - 30.0), 160.0, 160.0)
            }
        }
    }

    # แก้ไขฟังก์ชัน TakeDamage ใน Lucifer.ps1
    [bool] TakeDamage([int]$damageAmount) {
        # 1. ถ้ายังมีโล่ (ArmorHP) ให้หักที่โล่ก่อน
        if ($this.ArmorHP -gt 0) {
            $this.ArmorHP -= $damageAmount
            if ($this.ArmorHP -lt 0) { 
                # ถ้าดาเมจแรงจนโล่ทะลุ ให้ดาเมจที่เหลือไปหักเลือดหลัก (Optional)
                # หรือจะให้โล่กันดาเมจเกินนัดนั้นไปเลยก็ได้ ในที่นี้ผมให้โล่กันหมดนัดนั้นครับ
                $this.ArmorHP = 0 
            }
            return $false # ยังไม่ตายเพราะติดโล่อยู่
        }
        
        # 2. ถ้าโล่หมดแล้ว หักเลือดหลัก และกันไม่ให้ติดลบ
        $this.HP -= $damageAmount
        if ($this.HP -lt 0) { $this.HP = 0 } # <--- กันเลือดติดลบ 2K
        
        return ($this.HP -le 0)
    }
}