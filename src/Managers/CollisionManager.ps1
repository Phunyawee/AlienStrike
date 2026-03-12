function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight) {
    $result = @{
        ScoreAdded   = 0; IsPlayerHit  = $false; IsFatalHit   = $false 
        ApplySilence = $false; ApplySiren   = $false; ApplyJammer  = $false 
        WrathKills   = 0; LustKills    = 0; SlothKills   = 0; GreedKills = 0 
        PrideKilled  = $false; GluttonyKills = 0; RealPrideKilled = $false ;
        LuciferKilled = $false
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
                # ในลูป Enemy Collisions ส่วนเช็คกระสุนผู้เล่นชน Lucifer
                if ($eName -eq "Lucifer") {
                # Nuke ทำดาเมจชิ้นส่วนละ 200
                        foreach ($part in $e.Parts) {
                            if (-not $part.IsDestroyed -and $part.TakeDamage(200)) {
                                # ถ้าพัง หักเลือดตัวแม่ตามประเภท
                                if ($part.Type -eq "Cannon") { $e.HP -= 4000 } else { $e.HP -= 1000 }
                        }
                    }
                     # --- [แก้ไข] ดาเมจเข้า Core บอส ---
                        if ($e.Phase -ge 2) { 
                            $nukeDead = $e.TakeDamage(400) # Phase สุดท้ายโดน 400!
                        } else { 
                            $nukeDead = $e.TakeDamage(5) # เฟสแรกๆ โดนแค่ 5 (ต้องพังปีกก่อน)
                        }
                }
                else { $nukeDead = $e.TakeDamage(99) }
            } else { $nukeDead = $true }

            if ($nukeDead) {
                if ($null -ne $e.ScoreValue) { $result.ScoreAdded += $e.ScoreValue } else { $result.ScoreAdded += 100 }
                if ($eName -eq "Gluttony") { $result.GluttonyKills += 1 }
                elseif ($eName -eq "RealPride") { $result.RealPrideKilled = $true }
                $enemies.RemoveAt($i)
            }
        }
    }

    for ($k = $items.Count - 1; $k -ge 0; $k--) {
        $it = $items[$k]
        if ($it.GetBounds().IntersectsWith($player.GetBounds())) {
            # บวกลอจิกที่นี่ตรงๆ
            $Script:defenseHits += 5
            if ($Script:defenseHits -gt 400) { $Script:defenseHits = 400 }
            
            # ลบไอเทมออกทันที
            $items.RemoveAt($k)
            Write-Host ">>> ITEM COLLECTED: SHIELD +5 <<<" -ForegroundColor Green
            continue # ตรวจสอบชิ้นถัดไป
        }
        # ลบถ้าตกจอ
        if ($it.Y -gt $formHeight) { $items.RemoveAt($k) }
    }

    # 2. Enemy Collisions
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        if ($i -ge $enemies.Count) { continue }
        $e = $enemies[$i]; $typeName = $e.GetType().Name; $isDead = $false

        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            if (& $Script:blockHit) { $enemies.RemoveAt($i); continue }
            $result.IsPlayerHit = $true; return $result
        }

        # --- ภายในลูปกระสุนผู้เล่น (ลูป $j) ---
        for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
            $b = $bullets[$j]; $bName = $b.GetType().Name; $hitBox = $b.GetBounds()
            
            # 1. กำหนดดาเมจพื้นฐานสำหรับศัตรูทั่วไป (Normal Damage)
            $currentDmg = 1
            if ($bName -eq "Nuke") { $currentDmg = 99 } # Nuke ต้องคิลมอนปกติได้ทันที
            elseif ($bName -eq "HolyBomb") { $currentDmg = 5 } # HolyBomb ลงมอนปกติแรงกว่านิดหน่อย

            # 2. ถ้าเป้าหมายคือ Lucifer
            if ($typeName -eq "Lucifer") {
                # --- เช็คดาเมจใส่ชิ้นส่วน (Parts) ---
                $partHit = $false
                foreach ($part in $e.Parts) {
                    if (-not $part.IsDestroyed -and $part.GetBounds($e.X, $e.Y).IntersectsWith($hitBox)) {
                        if ($bName -eq "Missile") { $b.Explode() }
                        # ดาเมจใส่ปีก (ให้แรงกว่าปกตินิดหน่อยเพื่อให้พังง่ายขึ้น)
                        $partDmg = if ($bName -eq "HolyBomb") { 50 } else { 1 }
                        
                        if ($part.TakeDamage($partDmg)) {
                            if ($part.Type -eq "Cannon") { $e.HP -= 4000 } else { $e.HP -= 1000 }
                        }
                        if ($bName -ne "PlayerLaser" -and $bName -ne "Nuke" -and $bName -ne "Missile") { $bullets.RemoveAt($j) }
                        $partHit = $true; break
                    }
                }
                if ($partHit) { continue }

                # --- เช็คดาเมจใส่แกนกลาง (Core) ---
                if ($e.GetBounds().IntersectsWith($hitBox)) {
                    if ($e.Phase -ge 2 -or $bName -eq "HolyBomb") {
                        if ($bName -eq "Missile") { $b.Explode() }
                        
                        # [จุดสำคัญ] คำนวณดาเมจพิเศษสำหรับ Lucifer Core เท่านั้น!
                        $bossDmg = 1
                        if ($bName -eq "HolyBomb") { $bossDmg = 800 }
                        elseif ($bName -eq "Nuke") { $bossDmg = 400 }
                        elseif ($bName -eq "Missile") { $bossDmg = 50 }
                        elseif ($bName -eq "PlayerLaser") { $bossDmg = 2 }

                        $isDead = $e.TakeDamage($bossDmg)
                        if ($bName -ne "PlayerLaser" -and $bName -ne "Missile") { $bullets.RemoveAt($j) }
                        break
                    } else {
                        if ($bName -ne "PlayerLaser") { $bullets.RemoveAt($j) }
                        break
                    }
                }
                continue
            }

            # 3. เช็คการชนศัตรูทั่วไป (ใช้ $currentDmg ที่เป็น 1 หรือ 5)
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -eq "Missile") { $b.Explode() }
                if ($bName -ne "PlayerLaser" -and $bName -ne "Nuke" -and $bName -ne "Missile") { $bullets.RemoveAt($j) }
                
                if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) { 
                    $isDead = $e.TakeDamage($currentDmg) 
                } else { $isDead = $true }
                
                if ($bName -ne "Missile" -and $bName -ne "PlayerLaser") { break }
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
            elseif ($typeName -eq "Lucifer"){ $result.LuciferKilled  = $true }
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