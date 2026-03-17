function Process-BossDamage ($e, $b, $context) {
    if ($null -eq $e -or $null -eq $b) { return $false }
    
    $eName = $e.GetType().Name
    $bName = $b.GetType().Name
    $hitBox = $b.GetBounds()
    
    # 1. กำหนดดาเมจตามประเภทอาวุธ (ห้ามใช้ IF ในวงเล็บ)
    $bossDmg = 1
    if ($bName -eq "HolyBomb") { $bossDmg = 800 }
    elseif ($bName -eq "Nuke") { $bossDmg = 400 }
    elseif ($bName -eq "Missile") { $bossDmg = 50 }
    elseif ($bName -eq "HomingMissile") { $bossDmg = 75 }
    elseif ($bName -eq "PlayerLaser") { $bossDmg = 2 }

    # --- CASE: NEPHILIM (Laser -> Blades -> Core) ---
    if ($eName -eq "Nephilim") {
        # ลำดับ 1: ปืนเลเซอร์กลาง
        if ($e.LaserHP -gt 0) {
            $laserRect = [System.Drawing.RectangleF]::new($e.X + 55, $e.Y + 40, 50, 50)
            if ($laserRect.IntersectsWith($hitBox)) {
                $e.LaserHP -= $bossDmg; $e.FlashTimer = 3
                if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
            }
            return $true
        }
        # ลำดับ 2: ใบพัด 2 ข้าง
        if ($e.Phase -eq 1) {
            $lBlade = [System.Drawing.RectangleF]::new($e.X + 5, $e.Y - 45, 50, 50)
            $rBlade = [System.Drawing.RectangleF]::new($e.X + 105, $e.Y - 45, 50, 50)
            $hitP = $false
            if ($e.LeftBladeHP -gt 0 -and $lBlade.IntersectsWith($hitBox)) { $e.LeftBladeHP -= $bossDmg; $hitP = $true }
            elseif ($e.RightBladeHP -gt 0 -and $rBlade.IntersectsWith($hitBox)) { $e.RightBladeHP -= $bossDmg; $hitP = $true }
            if ($hitP) { $e.FlashTimer = 3; if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 } }
            return $true
        }
        # ลำดับ 3: แกนกลาง
        if ($e.Phase -eq 2 -and $e.GetBounds().IntersectsWith($hitBox)) {
            if ($e.TakeDamage($bossDmg)) { $context.ScoreAdded += $e.ScoreValue }
            if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
            return $true
        }
        return $true
    }

    # --- CASE: LUCIFER (Cannon -> Turret -> Core) ---
    if ($eName -eq "Lucifer") {
        foreach ($part in $e.Parts) {
            if (-not $part.IsDestroyed -and $part.GetBounds($e.X, $e.Y).IntersectsWith($hitBox)) {
                if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                if ($part.Type -eq "Turret" -and $e.Phase -lt 1) { 
                    if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
                    return $true 
                }
                $pDmg = 1
                if ($bName -eq "HolyBomb") { $pDmg = 50 }
                if ($part.TakeDamage($pDmg)) {
                    if ($part.Type -eq "Cannon") { $e.HP -= 4000 } else { $e.HP -= 1000 }
                    Write-Host ">>> LUCIFER $($part.Type) DESTROYED! <<<" -ForegroundColor Yellow
                }
                if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
                return $true
            }
        }
        if ($e.GetBounds().IntersectsWith($hitBox)) {
            if ($e.Phase -ge 2 -or $bName -eq "HolyBomb") {
                if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                if ($e.TakeDamage($bossDmg)) { $context.LuciferKilled = $true }
                if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
            } else { if ($bName -ne "PlayerLaser") { $b.Y = -2000 } }
            return $true
        }
    }
    return $false
}