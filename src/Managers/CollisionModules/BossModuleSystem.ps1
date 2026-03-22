# \src\CollisionModules\BossModuleSystem.ps1

function Process-BossDamage ($e, $b, $context) {
    if ($null -eq $e -or $null -eq $b) { return @{ Hit = $false; Killed = $false } }
    
    $eName = $e.GetType().Name
    $bName = $b.GetType().Name
    $hitBox = $b.GetBounds()
    
    # ==========================================
    # 1. กำหนดดาเมจแยกตามประเภทอาวุธและบอส
    # ==========================================
    # ดึงตัวคูณดาเมจจากกระสุน (ถ้าไม่มีให้เป็น 1)
    $mult = if ($b.PsObject.Properties.Match("DamageMultiplier").Count -gt 0) { $b.DamageMultiplier } else { 1.0 }

    $bossDmg = 1
    
    if ($eName -eq "Lucifer") {
        if ($bName -eq "HolyBomb") { $bossDmg = 800 }
        elseif ($bName -eq "Nuke") { $bossDmg = 400 }
        elseif ($bName -eq "Missile") { $bossDmg = 50 }
        elseif ($bName -eq "HomingMissile") { $bossDmg = 75 }
        elseif ($bName -match "Laser") { $bossDmg = 2 * $mult } # <--- คูณ Multiplier ตรงนี้
    }
    elseif ($eName -eq "Nephilim" -or $eName -eq "Azazel") {
        if ($bName -eq "HolyBomb") { $bossDmg = 400 }
        elseif ($bName -eq "Nuke") { $bossDmg = 200 }
        elseif ($bName -eq "Missile") { $bossDmg = 25 }
        elseif ($bName -eq "HomingMissile") { $bossDmg = 38 }
        elseif ($bName -match "Laser") { $bossDmg = 2 * $mult } # <--- คูณ Multiplier เช่นกัน
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
                # [แก้ไข] ลบวงเล็บซ้ำซ้อนออก
                if ($bName -notmatch "Laser|Nuke|Missile|Homing") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                # [แก้ไข] เปลี่ยนจาก -ne เป็น -notmatch
                if ($bName -notmatch "Laser") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
        }

        if ($e.Phase -eq 1) {
            $lB = [System.Drawing.RectangleF]::new($e.X + 5, $e.Y - 45, 50, 50)
            $rB = [System.Drawing.RectangleF]::new($e.X + 105, $e.Y - 45, 50, 50)
            if ($lB.IntersectsWith($hitBox) -or $rB.IntersectsWith($hitBox)) {
                # [แก้ไข] เช็ค Laser ทุกสี
                if ($bName -match "Laser" -or $bName -eq "Nuke") {
                    if ($e.LeftBladeHP -gt 0 -and $lB.IntersectsWith($hitBox)) { $e.LeftBladeHP -= $bossDmg }
                    elseif ($e.RightBladeHP -gt 0 -and $rB.IntersectsWith($hitBox)) { $e.RightBladeHP -= $bossDmg }
                    $e.FlashTimer = 3
                } else {
                    if ($bName -match "Missile|HomingMissile") { $b.Explode() } else { $b.Y = -2000 }
                }
                return @{ Hit = $true; Killed = $false }
            }
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -notmatch "Laser") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
        }

        if ($e.Phase -eq 2 -and $e.GetBounds().IntersectsWith($hitBox)) {
            if ($bName -match "Missile|HomingMissile") { $b.Explode() }
            $isDeadNow = $e.TakeDamage($bossDmg)
            if ($bName -notmatch "Laser|Nuke|Missile|Homing")  { $b.Y = -2000 }
            return @{ Hit = $true; Killed = $isDeadNow }
        }
    }

    # --- CASE: AZAZEL ---
    if ($eName -eq "Azazel") {
        $isHeavyWeapon = ($bName -in @("Nuke", "Missile", "HomingMissile", "HolyBomb"))
        $hitBox = $b.GetBounds()

        $activeBigGuns = $e.Parts | Where-Object { $_.Type -eq "BigGun" -and -not $_.IsDestroyed }
        if ($null -ne $activeBigGuns -and ($activeBigGuns | Measure-Object).Count -gt 0) {
            foreach ($part in $activeBigGuns) {
                if ($part.GetBounds($e.X, $e.Y).IntersectsWith($hitBox)) {
                    if ($isHeavyWeapon) {
                        if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                        else { if ($bName -ne "Nuke") { $b.Y = -2000 } } 
                        return @{ Hit = $true; Killed = $false }
                    }
                    if ($part.TakeDamage($bossDmg, $bName)) { $e.HP -= 1500 }
                    # [แก้ไขจุดที่บั๊ก]
                    if ($bName -notmatch "Laser") { $b.Y = -2000 } 
                    return @{ Hit = $true; Killed = $false }
                }
            }
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                # [แก้ไขจุดที่บั๊ก]
                if ($bName -notmatch "Laser|Nuke") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            return @{ Hit = $false; Killed = $false }
        }

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
                    # [แก้ไขจุดที่บั๊ก]
                    if ($bName -notmatch "Laser") { $b.Y = -2000 } 
                    return @{ Hit = $true; Killed = $false }
                }
            }
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                # [แก้ไขจุดที่บั๊ก]
                if ($bName -notmatch "Laser|Nuke") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
            return @{ Hit = $false; Killed = $false }
        }

        if ($e.GetBounds().IntersectsWith($hitBox)) {
            if ($e.Phase -ge 2) {
                if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                $isDeadNow = $e.TakeDamage($bossDmg)
                if ($bName -notmatch "Laser|Nuke|Missile|Homing")  { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $isDeadNow }
            } else {
                # [แก้ไขจุดที่บั๊ก]
                if ($bName -notmatch "Laser") { $b.Y = -2000 }
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
                    if ($bName -notmatch "Laser|Nuke|Missile|Homing") { $b.Y = -2000 }
                    return @{ Hit = $true; Killed = $false }
                }
                $pDmg = if ($bName -eq "HolyBomb") { 50 } else { 1 }
                if ($part.TakeDamage($pDmg)) { if ($part.Type -eq "Cannon") { $e.HP -= 4000 } else { $e.HP -= 1000 } }
                if ($bName -notmatch "Laser|Nuke|Missile|Homing") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
        }
        if ($e.GetBounds().IntersectsWith($hitBox)) {
            if ($e.Phase -ge 2 -or $bName -eq "HolyBomb") {
                if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                $isDead = $e.TakeDamage($bossDmg)
                if ($isDead) { $context.LuciferKilled = $true }
                if ($bName -notmatch "Laser|Nuke|Missile|Homing")  { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $isDead }
            } else {
                # [แก้ไขจุดที่บั๊ก]
                if ($bName -notmatch "Laser") { $b.Y = -2000 }
                return @{ Hit = $true; Killed = $false }
            }
        }
    }
    return @{ Hit = $false; Killed = $false }
}