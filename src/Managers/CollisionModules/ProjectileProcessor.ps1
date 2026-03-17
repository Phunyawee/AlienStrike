function Invoke-WeaponDamage ($player, $bullets, $enemies, $context) {
    $enemySnapshot = $enemies.ToArray()
    $bulletSnapshot = $bullets.ToArray()

    foreach ($e in $enemySnapshot) {
        if ($null -eq $e -or $e.Y -gt 1000) { continue }
        $typeName = $e.GetType().Name
        $isDead = $false

        foreach ($b in $bulletSnapshot) {
            if ($null -eq $b -or $b.Y -lt -1000) { continue }
            $bName = $b.GetType().Name
            
            # --- [จุดแก้สำคัญ] เช็คดาเมจบอส และป้องกันการไหลลงข้างล่าง ---
            if ($typeName -eq "Lucifer" -or $typeName -eq "Nephilim") {
                $bossStatus = Process-BossDamage $e $b $context
                if ($bossStatus.Hit) {
                    $isDead = $bossStatus.Killed
                    if ($isDead) { break } # ถ้าบอสตาย จบลูปกระสุนสำหรับบอสตัวนี้
                    continue # ถ้าชนบอสแล้ว (แต่ไม่ตาย) ให้ข้ามไปเช็คกระสุนนัดถัดไปทันที ห้ามลงไปเช็ค Minion Logic!
                }
            }

            # --- 2. ลอจิกสำหรับศัตรูทั่วไป (จะทำงานเฉพาะเมื่อไม่ใช่บอส หรือไม่ชนบอสเท่านั้น) ---
            $hitBox = $b.GetBounds()
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                if ($bName -notin @("PlayerLaser", "Nuke", "Missile", "HomingMissile")) { $b.Y = -2000 }
                
                $dmg = if ($bName -eq "HomingMissile") { 5 } elseif ($bName -eq "HolyBomb") { 5 } else { 1 }
                try {
                    if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) { 
                        $isDead = $e.TakeDamage($dmg); $e.FlashTimer = 3 
                    } else { $isDead = $true } # ศัตรูปกติไม่มี TakeDamage เลยตายทันที
                } catch { $isDead = $true }

                if ($bName -notin @("PlayerLaser", "Nuke", "Missile", "HomingMissile")) { break }
            }
        }
        # การจัดการหลังศัตรูตาย
        if ($isDead) {
            if ($null -ne $e.ScoreValue) { $context.ScoreAdded += $e.ScoreValue } else { $context.ScoreAdded += 100 }
            
            if ($typeName -eq "Gluttony") { $context.GluttonyKills += 1 }
            elseif ($typeName -eq "RealPride") { $context.RealPrideKilled = $true }
            elseif ($typeName -eq "Lucifer") { $context.LuciferKilled = $true }
            elseif ($typeName -eq "Lust") { $context.LustKills += 1 }
            elseif ($typeName -eq "Greed") { $context.GreedKills += 1 }
            elseif ($typeName -eq "Sloth") { $context.SlothKills += 1 }
            elseif ($typeName -eq "Pride") { $context.PrideKilled = $true }
            elseif ($typeName -eq "Watcher" -and $e.Type -eq "Ace") { $context.AceKills += 1 }
            elseif ($typeName -eq "Wrath") {
                $context.WrathKills += 1
                $isDuel = $Script:gameMode -match "1v1_"
                if ($Script:wrathKills++ % 5 -eq 0 -and -not $isDuel -and $Script:gameMode -ne "Simulation") { 
                    [void]$enemies.Add([Envy]::new(225, -50, $player)) 
                }
            }
            # ใช้ Remove แทน RemoveAt เพราะปลอดภัยกว่าในลูป foreach
            [void]$enemies.Remove($e)
        } elseif ($e.Y -gt 650) { [void]$enemies.Remove($e) }
    }
}