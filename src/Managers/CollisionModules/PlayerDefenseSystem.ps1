function Invoke-PlayerDefense ($player, $enemies, $enemyBullets, $formHeight, $context) {
    # 1. Fatal Boss Beams
    foreach ($boss in $enemies) {
        $bName = $boss.GetType().Name
        $isFatal = $false
        if ($bName -eq "RealPride" -and $boss.State -eq 2) { $isFatal = $true }
        elseif ($bName -eq "Lucifer" -and $boss.ChargeTimer -ge 2.5) { $isFatal = $true }
        elseif ($bName -eq "Nephilim" -and $boss.Phase -eq 0 -and $boss.ChargeTimer -ge 2.5) { $isFatal = $true }

        if ($isFatal) {
            $bx = $boss.X + ($boss.Width / 2.0) - 15.0
            $beamRect = [System.Drawing.RectangleF]::new($bx, [float]($boss.Y + 55), 30.0, 600.0)
            if ($beamRect.IntersectsWith($player.GetBounds())) {
                $context.IsPlayerHit = $true; $context.IsFatalHit = $true; $context.ShakeIntensity = 10
                return
            }
        }
    }

    # 2. Enemy Bullets & Shield logic
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        if ($i -ge $enemyBullets.Count) { continue }
        $eb = $enemyBullets[$i]; $ebName = $eb.GetType().Name
        
        if ($ebName -eq "SlothBomb" -and $eb.State -eq 3) {
            $wave = $eb.GetShockwave(); if ($wave) { [void]$enemyBullets.Add($wave) }; $enemyBullets.RemoveAt($i); continue
        }
        if ($ebName -eq "SovereignPulse" -and $eb.GetBounds().IntersectsWith($player.GetBounds())) {
            if ($Script:defenseHits -gt 50) { $Script:defenseHits = 50 }; continue
        }

        if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
            # [A] Shredders (เช็คก่อนโล่ปกติ)
            if ($ebName -match "GluttonyBlast") {
                $lost = 0
                if ($Script:defenseHits -ge 10) { $lost = [math]::Floor($Script:defenseHits * 0.5) } else { $lost = $Script:defenseHits }
                $Script:defenseHits -= $lost
                foreach ($boss in $enemies) { if ($boss.GetType().Name -eq "Gluttony") { $boss.HP += $lost } }
                $enemyBullets.RemoveAt($i); if ($lost -eq 0 -and $Script:defenseHits -eq 0) { $context.IsPlayerHit = $true }
                continue
            }
            if ($ebName -match "NephilimBlade") {
                $Script:defenseHits = [math]::Max(0, $Script:defenseHits - 50)
                $enemyBullets.RemoveAt($i); if ($Script:defenseHits -eq 0) { $context.IsPlayerHit = $true }
                continue
            }
            if ($eb.SpeedY -eq 15) {
                $Script:defenseHits = [math]::Max(0, $Script:defenseHits - 5)
                $enemyBullets.RemoveAt($i); continue
            }

            # [B] Standard Block
            if ($Script:defenseHits -gt 0) {
                $Script:defenseHits -= 1; $enemyBullets.RemoveAt($i)
                Write-Host ">>> ATTACK BLOCKED <<<" -ForegroundColor Cyan
                continue
            }

            # [C] No Shield (Fatal/Status)
            if ($ebName -match "SirenBullet") { $context.ApplySiren = $true }
            elseif ($ebName -match "SilenceBullet") { $context.ApplySilence = $true }
            elseif ($ebName -match "GreedArrow") { $context.ApplyGreed = $true }
            elseif ($ebName -match "SlothShockwave") { $context.ApplyJammer = $true; continue }
            elseif ($ebName -match "EnemyMissile") {
                if ($eb.IsExploding) { $context.IsPlayerHit = $true } else { $eb.Explode(); continue }
            }
            else { $context.IsPlayerHit = $true }

            if ($ebName -ne "SlothShockwave") { $enemyBullets.RemoveAt($i) }
        }
        if ($eb.Y -gt $formHeight) { $enemyBullets.RemoveAt($i) }
    }
}