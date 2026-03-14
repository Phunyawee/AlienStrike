function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight, $items) {
    $result = @{
        ScoreAdded   = 0; IsPlayerHit  = $false; IsFatalHit   = $false 
        ApplySilence = $false; ApplySiren   = $false; ApplyJammer  = $false 
        WrathKills   = 0; LustKills    = 0; SlothKills   = 0; GreedKills = 0 
        PrideKilled  = $false; GluttonyKills = 0; RealPrideKilled = $false 
        LuciferKilled = $false; ShakeIntensity = 0 # <--- [NEW] เพิ่มตัวแปรสั่นจอ
    }

    # ==========================================
    # 1. UNSTOPPABLE THREATS (ข้ามระบบอมตะ)
    # ==========================================
    foreach ($eb in $enemyBullets) {
        if ($eb.GetType().Name -eq "CataclysmWave") {
            if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
                $result.IsPlayerHit = $true
                $Script:lives = 0 # บังคับตายจริง
                Write-Host "!!! CATACLYSM HAS CONSUMED THE UNIVERSE !!!" -ForegroundColor Red
                return $result # จบเกมทันที
            }
        }
    }

    # --- ระบบ Immortal ปกติ (เช็คหลัง Cataclysm) ---
    if ($Script:immortalTimer -gt 0) { return $result }

    $Script:blockHit = { if ($Script:defenseHits -gt 0) { $Script:defenseHits -= 1; return $true }; return $false }

    # ==========================================
    # 1. GLOBAL NUKE CHECK (แก้ไขให้เก็บยอดคิลครบทุกตัว)
    # ==========================================
    $activeNuke = $bullets | Where-Object { $_.GetType().Name -eq "Nuke" -and $_.Exploded } | Select-Object -First 1
    if ($null -ne $activeNuke) {
        for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
            $e = $enemies[$i]; $eName = $e.GetType().Name; $nukeDead = $false
            
            if ($eName -eq "Lucifer") {
                foreach ($part in $e.Parts) { if (-not $part.IsDestroyed -and $part.TakeDamage(200)) { if ($part.Type -eq "Cannon") { $e.HP -= 4000 } else { $e.HP -= 1000 } } }
                $nukeDead = $e.TakeDamage(5) 
            }
            elseif ($eName -eq "RealPride") { $nukeDead = $e.TakeDamage(200) }
            elseif ($eName -eq "Gluttony")  { $nukeDead = $e.TakeDamage(50) }
            else { 
                if ($e -is [BaseEnemy]) { $nukeDead = $e.TakeDamage(99) } else { $nukeDead = $true }
            }

            if ($nukeDead) {
                # --- [จุดที่ต้องเพิ่ม] เก็บสถานะการตายทุกประเภทส่งกลับไป ---
                if ($null -ne $e.ScoreValue) { $result.ScoreAdded += $e.ScoreValue } else { $result.ScoreAdded += 100 }
                
                if ($eName -eq "Gluttony") { $result.GluttonyKills += 1 }
                elseif ($eName -eq "RealPride") { $result.RealPrideKilled = $true }
                elseif ($eName -eq "Lucifer") { $result.LuciferKilled = $true }
                elseif ($eName -eq "Lust") { $result.LustKills += 1 }
                elseif ($eName -eq "Greed") { $result.GreedKills += 1 }
                elseif ($eName -eq "Sloth") { $result.SlothKills += 1 }
                elseif ($eName -eq "Wrath") { $result.WrathKills += 1 }

                Write-Host ">>> NUKE ANNIHILATED: $eName <<<" -ForegroundColor Red
                $enemies.RemoveAt($i)
            }
        }
    }

    # ==========================================
    # 3. ITEM PICKUPS
    # ==========================================
    for ($k = $items.Count - 1; $k -ge 0; $k--) {
        if ($items[$k].GetBounds().IntersectsWith($player.GetBounds())) {
            $Script:defenseHits = [math]::Min(400, $Script:defenseHits + 5)
            $items.RemoveAt($k)
            Write-Host ">>> SHIELD REINFORCED (+5) <<<" -ForegroundColor Cyan
            continue
        }
        if ($items[$k].Y -gt $formHeight) { $items.RemoveAt($k) }
    }

    # ==========================================
    # 4. WEAPON DAMAGE (Player vs Enemy)
    # ==========================================
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        if ($i -ge $enemies.Count) { continue }
        $e = $enemies[$i]; $typeName = $e.GetType().Name; $isDead = $false

        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            if (& $Script:blockHit) { $enemies.RemoveAt($i); continue }
            $result.IsPlayerHit = $true; return $result
        }

        for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
            $b = $bullets[$j]; $bName = $b.GetType().Name; $hitBox = $b.GetBounds()
            $currentDmg = if ($bName -eq "HolyBomb") { 5 } else { 1 }

            if ($typeName -eq "Lucifer") {
                $partHit = $false
                foreach ($part in $e.Parts) {
                    if (-not $part.IsDestroyed -and $part.GetBounds($e.X, $e.Y).IntersectsWith($hitBox)) {
                        if ($bName -eq "Missile") { $b.Explode() }
                        if ($part.Type -eq "Turret" -and $e.Phase -lt 1) { 
                             if ($bName -ne "PlayerLaser") { $bullets.RemoveAt($j) }; $partHit = $true; break 
                        }
                        $pDmg = if ($bName -eq "HolyBomb") { 50 } else { 1 }
                        if ($part.TakeDamage($pDmg)) {
                            if ($part.Type -eq "Cannon") { $e.HP -= 4000 } else { $e.HP -= 1000 }
                            Write-Host ">>> LUCIFER $($part.Type) DESTROYED! <<<" -ForegroundColor Yellow
                        }
                        if ($bName -ne "PlayerLaser" -and $bName -ne "Nuke" -and $bName -ne "Missile") { $bullets.RemoveAt($j) }
                        $partHit = $true; break
                    }
                }
                if ($partHit) { continue }
                if ($e.GetBounds().IntersectsWith($hitBox)) {
                    if ($e.Phase -ge 2 -or $bName -eq "HolyBomb") {
                        if ($bName -eq "Missile") { $b.Explode() }
                        $bossDmg = if($bName -eq "HolyBomb"){800} elseif($bName -eq "Nuke"){400} elseif($bName -eq "Missile"){50} elseif($bName -eq "PlayerLaser"){2} else {1}
                        $isDead = $e.TakeDamage($bossDmg)
                        if ($bName -ne "PlayerLaser" -and $bName -ne "Missile") { $bullets.RemoveAt($j) }
                        break
                    } else {
                        if ($bName -ne "PlayerLaser") { $bullets.RemoveAt($j) }; break
                    }
                }
                continue
            }

            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -eq "Missile") { $b.Explode() }
                if ($bName -ne "PlayerLaser" -and $bName -ne "Nuke" -and $bName -ne "Missile") { $bullets.RemoveAt($j) }
                if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) { 
                    $isDead = $e.TakeDamage($currentDmg) 
                    $e.FlashTimer = 3 
                } else { $isDead = $true }
                if ($bName -ne "Missile" -and $bName -ne "PlayerLaser") { break }
            }
        }

        if ($isDead) {
            if ($null -ne $e.ScoreValue) { $result.ScoreAdded += $e.ScoreValue } else { $result.ScoreAdded += 100 }
            if ($typeName -eq "Gluttony") { $result.GluttonyKills += 1 }
            elseif ($typeName -eq "Lust") { $result.LustKills += 1 }
            elseif ($typeName -eq "Sloth") { $result.SlothKills += 1 }
            elseif ($typeName -eq "Greed") { $result.GreedKills += 1 }
            elseif ($typeName -eq "Pride") { $result.PrideKilled = $true }
            elseif ($typeName -eq "RealPride") { $result.RealPrideKilled = $true }
            elseif ($typeName -eq "Lucifer") 
            { 
                $result.LuciferKilled = $true 
                Write-Host ">>> LUCIFER HAS BEEN DEFEATED! <<<" -ForegroundColor White
            }
            elseif ($typeName -eq "Wrath") {
                $result.WrathKills += 1
                $Script:wrathKills++; if ($Script:wrathKills % 5 -eq 0) { [void]$enemies.Add([Envy]::new(225, -50, $player)) }
            }
            $enemies.RemoveAt($i)
        } elseif ($e.Y -gt $formHeight) { $enemies.RemoveAt($i) }
    }

    # ==========================================
    # 5. BOSS FATAL ATTACKS
    # ==========================================
    foreach ($boss in $enemies) {
        $bName = $boss.GetType().Name
        if ($bName -eq "RealPride" -and $boss.State -eq 2) {
            $beam = [System.Drawing.RectangleF]::new(($boss.X + ($boss.Width/2.0) - 15.0), [float]($boss.Y + 55), 30.0, 600.0)
            if ($beam.IntersectsWith($player.GetBounds())) { $result.IsPlayerHit = $true; $result.IsFatalHit = $true; $result.ShakeIntensity = 10 }
        }
        if ($bName -eq "Lucifer" -and $boss.ChargeTimer -ge 2.5) {
            foreach ($p in ($boss.Parts | Where-Object { $_.Type -eq "Cannon" -and -not $_.IsDestroyed })) {
                $beam = [System.Drawing.RectangleF]::new(($boss.X + $p.RelX + 5.0), [float]($boss.Y + $p.RelY + 80), 30.0, 600.0)
                if ($beam.IntersectsWith($player.GetBounds())) { $result.IsPlayerHit = $true; $result.IsFatalHit = $true; $result.ShakeIntensity = 10 }
            }
            if ($boss.Phase -gt 0) {
                $beam = [System.Drawing.RectangleF]::new(($boss.X + 35.0), [float]($boss.Y + 100), 30.0, 600.0)
                if ($beam.IntersectsWith($player.GetBounds())) { $result.IsPlayerHit = $true; $result.IsFatalHit = $true; $result.ShakeIntensity = 15 }
            }
        }
    }

    # ==========================================
    # 6. ENEMY PROJECTILES & DEBUFFS
    # ==========================================
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        $eb = $enemyBullets[$i]; $bulletName = $eb.GetType().Name
        if ($bulletName -eq "SlothBomb" -and $eb.State -eq 3) {
            $wave = $eb.GetShockwave(); if ($wave) { [void]$enemyBullets.Add($wave) }; $enemyBullets.RemoveAt($i); continue
        }
        if ($bulletName -eq "SovereignPulse" -and $eb.GetBounds().IntersectsWith($player.GetBounds())) {
            if ($Script:defenseHits -gt 50) { $Script:defenseHits = 50 }; continue
        }
        if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
            if ($eb.SpeedY -eq 15) { $Script:defenseHits = [math]::Max(0, $Script:defenseHits - 5); $enemyBullets.RemoveAt($i); continue }
            if ($bulletName -eq "GluttonyBlast") {
                $lost = if ($Script:defenseHits -ge 10) { [math]::Floor($Script:defenseHits * 0.5) } else { $Script:defenseHits }
                $Script:defenseHits -= $lost
                Write-Host ">>> GLUTTONY STOLE SHIELD: -$lost <<<" -ForegroundColor Magenta
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