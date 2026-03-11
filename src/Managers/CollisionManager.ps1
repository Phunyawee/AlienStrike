function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight) {
    $result = @{
        ScoreAdded   = 0; IsPlayerHit  = $false; IsFatalHit   = $false 
        ApplySilence = $false; ApplySiren   = $false; ApplyJammer  = $false 
        WrathKills   = 0; LustKills    = 0; SlothKills   = 0; GreedKills = 0 
        PrideKilled  = $false; GluttonyKills = 0; RealPrideKilled = $false 
    }

    # --- [Immortal Check] ---
    if ($Script:immortalTimer -gt 0) { return $result }

    $Script:blockHit = { if ($Script:defenseHits -gt 0) { $Script:defenseHits -= 1; return $true }; return $false }

    # --- 1. Enemy Collisions ---
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        $e = $enemies[$i]
        $isDead = $false
        $typeName = $e.GetType().Name 

        # [1.1 เช็ค Nuke]
        foreach ($b in $bullets) {
            if ($b.GetType().Name -eq "Nuke" -and $b.Exploded) {
                if ($e -is [BaseEnemy]) {
                    if ($typeName -eq "Gluttony") { $isDead = $e.TakeDamage(50) }
                    elseif ($typeName -eq "Lucifer") { $isDead = $e.TakeDamage(5) } # Nuke โดนลูซิเฟอร์เบาหน่อย
                    elseif ($typeName -eq "RealPride") { $isDead = $e.TakeDamage(200) }
                    else { $isDead = $e.TakeDamage(99) }
                } else { $isDead = $true }
            }
        }

        # [1.2 เช็คศัตรูชนผู้เล่น]
        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            if (& $Script:blockHit) { $enemies.RemoveAt($i); continue }
            $result.IsPlayerHit = $true; return $result
        }

        # [1.3 เช็คโดนกระสุนผู้เล่น]
        if (-not $isDead) {
            for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
                $b = $bullets[$j]
                $hitBox = $b.GetBounds()
                
                # --- [พิเศษ] เช็คชิ้นส่วน LUCIFER ---
                if ($typeName -eq "Lucifer") {
                    $partHit = $false
                    foreach ($part in $e.Parts) {
                        if (-not $part.IsDestroyed -and $part.GetBounds($e.X, $e.Y).IntersectsWith($hitBox)) {
                            $part.TakeDamage(1)
                            if ($b.GetType().Name -ne "PlayerLaser") { $bullets.RemoveAt($j) }
                            $partHit = $true; break
                        }
                    }
                    if ($partHit) { continue } # ถ้าโดนชิ้นส่วน ให้ข้ามไปเช็คกระสุนนัดถัดไป
                    
                    # ถ้า Phase ยังไม่ถึง Core (0 หรือ 1) จะยิงเข้าตัวแม่ไม่ได้
                    if ($e.Phase -lt 2) { continue }
                }

                # --- เช็คการชนปกติ ---
                if ($e.GetBounds().IntersectsWith($hitBox)) {
                    if ($b -is [Missile]) { $b.Explode() } 
                    elseif ($b.GetType().Name -ne "PlayerLaser" -and $b.GetType().Name -ne "Nuke") { $bullets.RemoveAt($j) }
                    
                    if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) { $isDead = $e.TakeDamage(1) } else { $isDead = $true }
                    if ($b.GetType().Name -ne "Missile" -and $b.GetType().Name -ne "PlayerLaser") { break }
                }
            }
        }

        # [1.4 จัดการเมื่อศัตรูตาย]
        if ($isDead) {
            if ($null -ne $e.ScoreValue) { $result.ScoreAdded += $e.ScoreValue } else { $result.ScoreAdded += 100 }
            
            if ($typeName -eq "Gluttony") { $result.GluttonyKills += 1 }
            elseif ($typeName -eq "Lust")     { $result.LustKills += 1 }
            elseif ($typeName -eq "Sloth")    { $result.SlothKills += 1 }
            elseif ($typeName -eq "Greed")    { $result.GreedKills += 1 }
            elseif ($typeName -eq "Pride")    { $result.PrideKilled = $true }
            elseif ($typeName -eq "RealPride"){ $result.RealPrideKilled = $true }
            elseif ($typeName -eq "Wrath") {
                $result.WrathKills += 1
                $Script:wrathKills++
                if ($Script:wrathKills % 5 -eq 0) { [void]$enemies.Add([Envy]::new(225, -50, $player)) }
            }
            $enemies.RemoveAt($i)
        } elseif ($e.Y -gt $formHeight) { $enemies.RemoveAt($i) }
    }

    # --- 2. Fatal Beam Checks (RealPride & Lucifer) ---
    foreach ($boss in $enemies) {
        $bName = $boss.GetType().Name
        # RealPride Laser
        if ($bName -eq "RealPride" -and $boss.State -eq 2) {
            $beam = [System.Drawing.RectangleF]::new($boss.X + ($boss.Width/2) - 15, $boss.Y + 55, 30, 600)
            if ($beam.IntersectsWith($player.GetBounds())) { $result.IsPlayerHit = $true; $result.IsFatalHit = $true }
        }
        # Lucifer Fatal Beams (Phase 1: 2 ปีก / Phase 2+: 1 กลาง)
        if ($bName -eq "Lucifer" -and $boss.ChargeTimer -gt 2.5) {
            foreach ($p in ($boss.Parts | Where-Object { $_.Type -eq "Cannon" -and -not $_.IsDestroyed })) {
                $beam = [System.Drawing.RectangleF]::new($boss.X + $p.RelX + 5, $boss.Y + $p.RelY + 80, 30, 600)
                if ($beam.IntersectsWith($player.GetBounds())) { $result.IsPlayerHit = $true; $result.IsFatalHit = $true }
            }
            if ($boss.Phase -gt 0) {
                $beam = [System.Drawing.RectangleF]::new($boss.X + 35, $boss.Y + 100, 30, 600)
                if ($beam.IntersectsWith($player.GetBounds())) { $result.IsPlayerHit = $true; $result.IsFatalHit = $true }
            }
        }
    }

    # --- 3. Enemy Bullet Collisions ---
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        $eb = $enemyBullets[$i]
        $bulletName = $eb.GetType().Name
        
        # [3.1 Special Bullets]
        if ($bulletName -eq "SlothBomb" -and $eb.State -eq 3) {
            $wave = $eb.GetShockwave(); if ($wave) { [void]$enemyBullets.Add($wave) }; $enemyBullets.RemoveAt($i); continue
        }
        if ($bulletName -eq "CataclysmWave" -and $eb.GetBounds().IntersectsWith($player.GetBounds())) {
            $result.IsPlayerHit = $true; $Script:lives = 0; return $result
        }
        if ($bulletName -eq "SovereignPulse" -and $eb.GetBounds().IntersectsWith($player.GetBounds())) {
            if ($Script:defenseHits -gt 50) { $Script:defenseHits = 50 }; continue
        }

        # [3.2 Player Hit Check]
        if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
            # Lucifer Shield Shredder (Speed 15)
            if ($eb.SpeedY -eq 15) {
                $Script:defenseHits = [math]::Max(0, $Script:defenseHits - 5)
                $enemyBullets.RemoveAt($i); continue
            }
            # Gluttony Shield Devour
            if ($bulletName -eq "GluttonyBlast") {
                $lost = if ($Script:defenseHits -ge 10) { [math]::Floor($Script:defenseHits * 0.5) } else { $Script:defenseHits }
                $Script:defenseHits -= $lost
                foreach ($b in $enemies) { if ($b.GetType().Name -eq "Gluttony") { $b.HP += $lost } }
                $enemyBullets.RemoveAt($i)
                if ($lost -eq 0 -and $Script:defenseHits -eq 0) { $result.IsPlayerHit = $true }
                continue
            }

            if (& $Script:blockHit) { $enemyBullets.RemoveAt($i); continue }

            # Debuffs
            if ($bulletName -eq "SilenceBullet") { $result.ApplySilence = $true; $enemyBullets.RemoveAt($i); continue } 
            if ($bulletName -eq "SirenBullet")   { $result.ApplySiren = $true;   $enemyBullets.RemoveAt($i); continue }
            if ($bulletName -eq "GreedArrow")   { $result.ApplyGreed = $true;   $enemyBullets.RemoveAt($i); continue }
            if ($bulletName -eq "SlothShockwave") { $result.ApplyJammer = $true; continue }
            
            $result.IsPlayerHit = $true; return $result
        }
        if ($eb.Y -gt $formHeight) { $enemyBullets.RemoveAt($i) }
    }
    return $result
}