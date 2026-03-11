function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight) {
    $result = @{
        ScoreAdded   = 0; IsPlayerHit  = $false; IsFatalHit   = $false 
        ApplySilence = $false; ApplySiren   = $false; ApplyJammer  = $false 
        WrathKills   = 0; LustKills    = 0; SlothKills   = 0; GreedKills = 0 
        PrideKilled  = $false; GluttonyKills = 0; RealPrideKilled = $false 
    }

    if ($Script:immortalTimer -gt 0) { return $result }

    $Script:blockHit = { if ($Script:defenseHits -gt 0) { $Script:defenseHits -= 1; return $true }; return $false }

    # 1. Global Nuke Check
    $activeNuke = $bullets | Where-Object { $_.GetType().Name -eq "Nuke" -and $_.Exploded } | Select-Object -First 1
    if ($null -ne $activeNuke) {
        for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
            $e = $enemies[$i]; $eName = $e.GetType().Name; $nukeDead = $false
            if ($e -is [BaseEnemy]) {
                if ($eName -eq "RealPride") { $nukeDead = $e.TakeDamage(200) }
                elseif ($eName -eq "Gluttony") { $nukeDead = $e.TakeDamage(50) }
                elseif ($eName -eq "Lucifer") { 
                    $nukeDead = $e.TakeDamage(5) 
                    # --- [เพิ่มส่วนนี้] เช็คชิ้นส่วนที่พังจาก Nuke ---
                    foreach ($part in $e.Parts) { 
                        if (-not $part.IsDestroyed -and $part.TakeDamage(100)) {
                            if ($part.Type -eq "Cannon") { $e.HP -= 4000 }
                            elseif ($part.Type -eq "Turret") { $e.HP -= 1000 }
                        }
                    }
                } else { $nukeDead = $e.TakeDamage(99) }
            } else { $nukeDead = $true }

            if ($nukeDead) {
                if ($null -ne $e.ScoreValue) { $result.ScoreAdded += $e.ScoreValue } else { $result.ScoreAdded += 100 }
                if ($eName -eq "Gluttony") { $result.GluttonyKills += 1 }
                elseif ($eName -eq "RealPride") { $result.RealPrideKilled = $true }
                $enemies.RemoveAt($i)
            }
        }
    }

    # 2. Enemy Collisions
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        if ($i -ge $enemies.Count) { continue }
        $e = $enemies[$i]; $typeName = $e.GetType().Name; $isDead = $false

        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            if (& $Script:blockHit) { $enemies.RemoveAt($i); continue }
            $result.IsPlayerHit = $true; return $result
        }

        for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
            $b = $bullets[$j]; $hitBox = $b.GetBounds()
            
            # --- [ส่วนเช็คชิ้นส่วน LUCIFER ใน CollisionManager] ---
                if ($typeName -eq "Lucifer") {
                    $partHit = $false
                    foreach ($part in $e.Parts) {
                        if (-not $part.IsDestroyed -and $part.GetBounds($e.X, $e.Y).IntersectsWith($hitBox)) {
                            
                            if ($b.GetType().Name -eq "Missile") { $b.Explode() }

                            # เช็คเงื่อนไข Phase
                            if ($part.Type -eq "Turret" -and $e.Phase -lt 1) { 
                                 if ($b.GetType().Name -ne "PlayerLaser") { $bullets.RemoveAt($j) }
                                 $partHit = $true; break 
                            }

                            # --- [จุดที่เพิ่มใหม่: หักเลือดตัวแม่เมื่อชิ้นส่วนพัง] ---
                            # สั่งทำดาเมจชิ้นส่วน และเช็คว่ามัน "พังในนัดนี้พอดี" หรือไม่
                            if ($part.TakeDamage(1)) { 
                                # ถ้าพังพอดี ให้หักเลือด Lucifer ตามประเภทปืน
                                if ($part.Type -eq "Cannon") { $e.HP -= 4000 }
                                elseif ($part.Type -eq "Turret") { $e.HP -= 1000 }
                                
                                Write-Host ">>> LUCIFER PART DESTROYED! Boss HP -$(if($part.Type -eq 'Cannon'){4000}else{1000}) <<<" -ForegroundColor Red
                            }

                            if ($b.GetType().Name -ne "PlayerLaser" -and $b.GetType().Name -ne "Nuke") { $bullets.RemoveAt($j) }
                            $partHit = $true; break
                        }
                    }
                    if ($partHit) { continue }
                    if ($b.GetType().Name -eq "Missile" -and $e.GetBounds().IntersectsWith($hitBox)) { $b.Explode() }
                    if ($e.Phase -lt 2) { continue }
                }

            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($b.GetType().Name -eq "Missile") { $b.Explode() } 
                elseif ($b.GetType().Name -ne "PlayerLaser" -and $b.GetType().Name -ne "Nuke") { $bullets.RemoveAt($j) }
                if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) { $isDead = $e.TakeDamage(1) } else { $isDead = $true }
                if ($b.GetType().Name -ne "Missile" -and $b.GetType().Name -ne "PlayerLaser") { break }
            }
        }

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
                $Script:wrathKills++; if ($Script:wrathKills % 5 -eq 0) { [void]$enemies.Add([Envy]::new(225, -50, $player)) }
            }
            $enemies.RemoveAt($i)
        } elseif ($e.Y -gt $formHeight) { $enemies.RemoveAt($i) }
    }
    # --- 3. Fatal Beam Checks (RealPride & Lucifer) ---
    foreach ($boss in $enemies) {
        $bName = $boss.GetType().Name
        if ($bName -eq "RealPride" -and $boss.State -eq 2) {
            $beam = [System.Drawing.RectangleF]::new(($boss.X + ($boss.Width/2.0) - 15.0), [float]($boss.Y + 55), 30.0, 600.0)
            if ($beam.IntersectsWith($player.GetBounds())) { $result.IsPlayerHit = $true; $result.IsFatalHit = $true }
        }
        if ($bName -eq "Lucifer" -and $boss.ChargeTimer -ge 2.5) {
            foreach ($p in ($boss.Parts | Where-Object { $_.Type -eq "Cannon" -and -not $_.IsDestroyed })) {
                $beam = [System.Drawing.RectangleF]::new(($boss.X + $p.RelX + 5.0), [float]($boss.Y + $p.RelY + 80), 30.0, 600.0)
                if ($beam.IntersectsWith($player.GetBounds())) { $result.IsPlayerHit = $true; $result.IsFatalHit = $true }
            }
            if ($boss.Phase -gt 0) {
                $beam = [System.Drawing.RectangleF]::new(($boss.X + 35.0), [float]($boss.Y + 100), 30.0, 600.0)
                if ($beam.IntersectsWith($player.GetBounds())) { $result.IsPlayerHit = $true; $result.IsFatalHit = $true }
            }
        }
    }

    # --- 4. Enemy Bullet Collisions ---
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        $eb = $enemyBullets[$i]; $bulletName = $eb.GetType().Name
        if ($bulletName -eq "SlothBomb" -and $eb.State -eq 3) {
            $wave = $eb.GetShockwave(); if ($wave) { [void]$enemyBullets.Add($wave) }; $enemyBullets.RemoveAt($i); continue
        }
        if ($bulletName -eq "CataclysmWave" -and $eb.GetBounds().IntersectsWith($player.GetBounds())) {
            $result.IsPlayerHit = $true; $Script:lives = 0; return $result
        }
        if ($bulletName -eq "SovereignPulse" -and $eb.GetBounds().IntersectsWith($player.GetBounds())) {
            if ($Script:defenseHits -gt 50) { $Script:defenseHits = 50 }; continue
        }
        if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
            if ($eb.SpeedY -eq 15) { $Script:defenseHits = [math]::Max(0, $Script:defenseHits - 5); $enemyBullets.RemoveAt($i); continue }
            if ($bulletName -eq "GluttonyBlast") {
                $lost = if ($Script:defenseHits -ge 10) { [math]::Floor($Script:defenseHits * 0.5) } else { $Script:defenseHits }
                $Script:defenseHits -= $lost
                foreach ($b in $enemies) { if ($b.GetType().Name -eq "Gluttony") { $b.HP += $lost } }
                $enemyBullets.RemoveAt($i); if ($lost -eq 0 -and $Script:defenseHits -eq 0) { $result.IsPlayerHit = $true }; continue
            }
            if (& $Script:blockHit) { $enemyBullets.RemoveAt($i); continue }
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