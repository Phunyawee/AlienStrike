# AlienStrike\src\CollisionModules\BossModuleSystem.ps1
function Process-BossDamage ($e, $b, $context) {
    if ($null -eq $e -or $null -eq $b) { return @{ Hit = $false; Killed = $false } }
    
    $eName = $e.GetType().Name
    $bName = $b.GetType().Name
    $hitBox = $b.GetBounds()
    
    # ==========================================
    # 1. กำหนดดาเมจแยกตามประเภทอาวุธและบอส
    # ==========================================
    $bossDmg = 1
    
    if ($eName -eq "Lucifer") {
        if ($bName -eq "HolyBomb") { $bossDmg = 800 }
        elseif ($bName -eq "Nuke") { $bossDmg = 400 }
        elseif ($bName -eq "Missile") { $bossDmg = 50 }
        elseif ($bName -eq "HomingMissile") { $bossDmg = 75 }
        elseif ($bName -eq "PlayerLaser") { $bossDmg = 2 }
    }
    elseif ($eName -eq "Nephilim" -or $eName -eq "Azazel") {
        # ดาเมจมินิบอส หรือ บอสที่ต้องตีทีละส่วน (เนิฟอาวุธหนัก)
        if ($bName -eq "HolyBomb") { $bossDmg = 400 }
        elseif ($bName -eq "Nuke") { $bossDmg = 200 }
        elseif ($bName -eq "Missile") { $bossDmg = 25 }
        elseif ($bName -eq "HomingMissile") { $bossDmg = 38 }
        elseif ($bName -eq "PlayerLaser") { $bossDmg = 2 }
    }

    # ==========================================
    # 2. ลำดับการทำลายชิ้นส่วนบอส
    # ==========================================

    # --- CASE 1: NEPHILIM ---
    if ($eName -eq "Nephilim") {
        if ($e.LaserHP -gt 0) {
            $laserRect = [System.Drawing.RectangleF]::new($e.X + 55, $e.Y + 40, 50, 50)
            if ($laserRect.IntersectsWith($hitBox)) {
                $e.LaserHP -= $bossDmg; $e.FlashTimer = 3
                if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -ne "PlayerLaser") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            return @{ Hit = $false; Killed = $false }
        }

        if ($e.Phase -eq 1) {
            $lB = [System.Drawing.RectangleF]::new($e.X + 5, $e.Y - 45, 50, 50)
            $rB = [System.Drawing.RectangleF]::new($e.X + 105, $e.Y - 45, 50, 50)
            
            if ($lB.IntersectsWith($hitBox) -or $rB.IntersectsWith($hitBox)) {
                if ($bName -eq "PlayerLaser" -or $bName -eq "Nuke") {
                    if ($e.LeftBladeHP -gt 0 -and $lB.IntersectsWith($hitBox)) { $e.LeftBladeHP -= $bossDmg }
                    elseif ($e.RightBladeHP -gt 0 -and $rB.IntersectsWith($hitBox)) { $e.RightBladeHP -= $bossDmg }
                    $e.FlashTimer = 3
                } else {
                    if ($bName -match "Missile|HomingMissile") { $b.Explode() } else { $b.Y = -2000 }
                }
                return @{ Hit = $true; Killed = $false }
            }
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -ne "PlayerLaser") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            return @{ Hit = $false; Killed = $false }
        }

        if ($e.Phase -eq 2 -and $e.GetBounds().IntersectsWith($hitBox)) {
            if ($bName -match "Missile|HomingMissile") { $b.Explode() }
            $isDeadNow = $e.TakeDamage($bossDmg)
            if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
            return @{ Hit = $true; Killed = $isDeadNow }
        }
        return @{ Hit = $false; Killed = $false }
    }

   # ==========================================
    # 3. CASE: AZAZEL (Strict Order: Big -> Small -> Core)
    # ==========================================
    if ($eName -eq "Azazel") {
        $isHeavyWeapon = ($bName -in @("Nuke", "Missile", "HomingMissile", "HolyBomb"))
        $hitBox = $b.GetBounds()

        # --- ลำดับที่ 1: ตรวจสอบปืนใหญ่ (BigGun) ---
        $activeBigGuns = $e.Parts | Where-Object { $_.Type -eq "BigGun" -and -not $_.IsDestroyed }
        if ($null -ne $activeBigGuns -and ($activeBigGuns | Measure-Object).Count -gt 0) {
            foreach ($part in $activeBigGuns) {
                if ($part.GetBounds($e.X, $e.Y).IntersectsWith($hitBox)) {
                    if ($isHeavyWeapon) {
                        if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                        else { if ($bName -ne "Nuke") { $b.Y = -2000 } } 
                        return @{ Hit = $true; Killed = $false }
                    }
                    # ดาเมจปืนใหญ่ (ใช้ $bossDmg จากด้านบนที่คำนวณไว้แล้วได้เลย)
                    if ($part.TakeDamage($bossDmg, $bName)) { $e.HP -= 1500 }
                    if ($bName -ne "PlayerLaser") { $b.Y = -2000 }
                    return @{ Hit = $true; Killed = $false }
                }
            }
            # โล่ป้องกัน: ถ้าปืนใหญ่ยังไม่พัง ห้ามยิงจุดอื่น
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -ne "PlayerLaser" -and $bName -ne "Nuke") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            return @{ Hit = $false; Killed = $false }
        }

        # --- ลำดับที่ 2: ตรวจสอบปืนเล็ก (SmallGun) ---
        $activeSmallGuns = $e.Parts | Where-Object { $_.Type -eq "SmallGun" -and -not $_.IsDestroyed }
        if ($null -ne $activeSmallGuns -and ($activeSmallGuns | Measure-Object).Count -gt 0) {
            foreach ($part in $activeSmallGuns) {
                if ($part.GetBounds($e.X, $e.Y).IntersectsWith($hitBox)) {
                    if ($isHeavyWeapon) {
                        if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                        else { if ($bName -ne "Nuke") { $b.Y = -2000 } }
                        return @{ Hit = $true; Killed = $false }
                    }
                    if ($part.TakeDamage($bossDmg, $bName)) { $e.HP -= 1000 }
                    if ($bName -ne "PlayerLaser") { $b.Y = -2000 }
                    return @{ Hit = $true; Killed = $false }
                }
            }
            # โล่ป้องกัน: ถ้าปืนเล็กยังไม่พัง ห้ามยิง Core
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -ne "PlayerLaser" -and $bName -ne "Nuke") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            return @{ Hit = $false; Killed = $false }
        }

        # --- ลำดับที่ 3: แกนกลาง (Core) ---
        if ($e.GetBounds().IntersectsWith($hitBox)) {
            # แก้จุดนี้: ต้องเป็น Phase 2 ถึงจะยิงเข้า
            if ($e.Phase -ge 2) {
                if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                
                # ใช้ดาเมจที่คำนวณไว้แล้วจากต้นฟังก์ชัน (ซึ่งรองรับทุกอาวุธแล้ว)
                $isDeadNow = $e.TakeDamage($bossDmg)
                
                if ($bName -notin @("PlayerLaser","Nuke","Missile","HomingMissile")) { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $isDeadNow }
            } else {
                # ถ้ายังไม่ถึง Phase 2 กระสุนจะเด้งออก
                if ($bName -ne "PlayerLaser") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
        }
    }
    # --- CASE 3: LUCIFER ---
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