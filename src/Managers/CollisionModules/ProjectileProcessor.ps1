function Invoke-WeaponDamage ($player, $bullets, $enemies, $context) {
    # สร้าง Snapshot ของศัตรูและกระสุน เพื่อป้องกันลิสต์เปลี่ยนขนาดระหว่างวนลูป
    $enemySnapshot = $enemies.ToArray()
    $bulletSnapshot = $bullets.ToArray()

    foreach ($e in $enemySnapshot) {
        if ($null -eq $e -or $e.Y -gt 1000) { continue }
        $typeName = $e.GetType().Name
        $isDead = $false

        foreach ($b in $bulletSnapshot) {
            # เช็คว่ากระสุนยังอยู่จริงไหม (Y > -1000 คือยังไม่โดนดีดทิ้ง)
            if ($null -eq $b -or $b.Y -lt -1000) { continue }
            $bName = $b.GetType().Name
            
            # 1. เช็คบอส (เรียกมอดูลแยก)
            if ($typeName -eq "Lucifer" -or $typeName -eq "Nephilim") {
                if (Process-BossDamage $e $b $context) { continue }
            }

            # 2. เช็คศัตรูทั่วไป
            $hitBox = $b.GetBounds()
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -match "Missile|HomingMissile") { $b.Explode() }
                
                # ดีดกระสุนทิ้ง (เพื่อให้นัดถอยหลังข้ามตัวนี้ไป)
                if ($bName -notin @("PlayerLaser", "Nuke", "Missile", "HomingMissile")) { $b.Y = -2000 }
                
                $dmg = if ($bName -eq "HomingMissile") { 5 } elseif ($bName -eq "HolyBomb") { 5 } else { 1 }
                
                # เช็ค Method ก่อนเรียกเสมอ (ป้องกัน Null)
                try {
                    if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) { 
                        $isDead = $e.TakeDamage($dmg); $e.FlashTimer = 3 
                    } else { $isDead = $true }
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