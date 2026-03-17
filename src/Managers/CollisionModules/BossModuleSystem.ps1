function Process-BossDamage ($e, $b, $context) {
    if ($null -eq $e -or $null -eq $b) { return @{ Hit = $false; Killed = $false } }
    
    $eName = $e.GetType().Name
    $bName = $b.GetType().Name
    $hitBox = $b.GetBounds()
    
    # ==========================================
    # 1. กำหนดดาเมจแยกตามประเภทบอส (Nephilim โดนเบาลงครึ่งนึง)
    # ==========================================
    $bossDmg = 1
    
    if ($eName -eq "Lucifer") {
        # ดาเมจมาตรฐานสำหรับบอสใหญ่
        if ($bName -eq "HolyBomb") { $bossDmg = 800 }
        elseif ($bName -eq "Nuke") { $bossDmg = 400 }
        elseif ($bName -eq "Missile") { $bossDmg = 50 }
        elseif ($bName -eq "HomingMissile") { $bossDmg = 75 }
        elseif ($bName -eq "PlayerLaser") { $bossDmg = 2 }
    }
    elseif ($eName -eq "Nephilim") {
        # --- [จุดแก้] ลดความแรงลงครึ่งหนึ่งสำหรับ Nephilim ---
        if ($bName -eq "HolyBomb") { $bossDmg = 400 }
        elseif ($bName -eq "Nuke") { $bossDmg = 200 }
        elseif ($bName -eq "Missile") { $bossDmg = 25 }
        elseif ($bName -eq "HomingMissile") { $bossDmg = 38 } # (75 / 2)
        elseif ($bName -eq "PlayerLaser") { $bossDmg = 1 }
        else { $bossDmg = 1 }
    }

    # ==========================================
    # 2. ลำดับการทำลาย (Strict Phase Gating)
    # ==========================================
    if ($eName -eq "Nephilim") {
        # --- PHASE 0: ปืนเลเซอร์กลาง ---
        if ($e.LaserHP -gt 0) {
            $laserRect = [System.Drawing.RectangleF]::new($e.X + 55, $e.Y + 40, 50, 50)
            if ($laserRect.IntersectsWith($hitBox)) {
                $e.LaserHP -= $bossDmg; $e.FlashTimer = 3
                if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            # ติดโล่ตัวแม่ (ห้ามยิงข้ามเฟส)
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -ne "PlayerLaser") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            return @{ Hit = $false; Killed = $false }
        }

        # --- PHASE 1: ใบพัด (ต้องใช้ LASER หรือ NUKE เท่านั้น) ---
        if ($e.Phase -eq 1) {
            $lBlade = [System.Drawing.RectangleF]::new($e.X + 5, $e.Y - 45, 50, 50)
            $rBlade = [System.Drawing.RectangleF]::new($e.X + 105, $e.Y - 45, 50, 50)
            
            if ($lBlade.IntersectsWith($hitBox) -or $rBlade.IntersectsWith($hitBox)) {
                if ($bName -eq "PlayerLaser" -or $bName -eq "Nuke") {
                    if ($e.LeftBladeHP -gt 0 -and $lBlade.IntersectsWith($hitBox)) { $e.LeftBladeHP -= $bossDmg }
                    elseif ($e.RightBladeHP -gt 0 -and $rBlade.IntersectsWith($hitBox)) { $e.RightBladeHP -= $bossDmg }
                    $e.FlashTimer = 3
                } else {
                    # อาวุธอื่นยิงไม่เข้า (หักกระสุนทิ้ง)
                    if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                    else { $b.Y = -2000 }
                }
                return @{ Hit = $true; Killed = $false }
            }
            # ติดโล่ตัวแม่
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -ne "PlayerLaser") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            return @{ Hit = $false; Killed = $false }
        }

        # --- PHASE 2: แกนกลาง (Fragile) ---
        if ($e.Phase -eq 2 -and $e.GetBounds().IntersectsWith($hitBox)) {
            if ($bName -match "Missile|HomingMissile") { $b.Explode() }
            $isDeadNow = $e.TakeDamage($bossDmg)
            if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
            return @{ Hit = $true; Killed = $isDeadNow }
        }
        return @{ Hit = $false; Killed = $false }
    }

    # --- CASE: LUCIFER (เหมือนเดิม) ---
    if ($eName -eq "Lucifer") {
        foreach ($part in $e.Parts) {
            if (-not $part.IsDestroyed -and $part.GetBounds($e.X, $e.Y).IntersectsWith($hitBox)) {
                if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                if ($part.Type -eq "Turret" -and $e.Phase -lt 1) { 
                    if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
                    return @{ Hit = $true; Killed = $false }
                }
                $pDmg = if ($bName -eq "HolyBomb") { 50 } else { 1 }
                if ($part.TakeDamage($pDmg)) { if ($part.Type -eq "Cannon") { $e.HP -= 4000 } else { $e.HP -= 1000 } }
                if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
        }
        if ($e.GetBounds().IntersectsWith($hitBox)) {
            if ($e.Phase -ge 2 -or $bName -eq "HolyBomb") {
                if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                $isDead = $e.TakeDamage($bossDmg)
                if ($isDead) { $context.LuciferKilled = $true }
                if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $isDead }
            } else {
                if ($bName -ne "PlayerLaser") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
        }
    }
    return @{ Hit = $false; Killed = $false }
}