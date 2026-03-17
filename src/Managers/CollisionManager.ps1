function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight, $items) {
    $result = @{
        ScoreAdded   = 0; IsPlayerHit  = $false; IsFatalHit   = $false 
        ApplySilence = $false; ApplySiren   = $false; ApplyJammer  = $false 
        WrathKills   = 0; LustKills    = 0; SlothKills   = 0; GreedKills = 0 
        PrideKilled  = $false; GluttonyKills = 0; RealPrideKilled = $false 
        LuciferKilled = $false; ShakeIntensity = 0 # <--- [NEW] เพิ่มตัวแปรสั่นจอ
    }

    # A. เช็คภัยพิบัติ (ข้ามทุกอย่าง ตายทันที)
    Handle-UnstoppableThreats $player $enemyBullets $context

    # B. ถ้ายังอมตะอยู่ ให้ข้ามลอจิกดาเมจที่เหลือทั้งหมด
    if ($Script:immortalTimer -gt 0) { return $context }

    # C. เก็บไอเทม (Defense Drop)
    Invoke-ItemCollection $player $items

    # D. ระเบิดนิวเคลียร์ (Global Wipe)
    Invoke-GlobalNuke $bullets $enemies $context

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

    # F. ศัตรูยิงผู้เล่น (ระบบโล่ และ ดีบัฟ)
    Invoke-PlayerDefense $player $enemies $enemyBullets $formHeight $context

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

        # --- ภายในลูปกระสุนผู้เล่น (ลูป $j) ---
        for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
            # [Safety 1] เช็คดัชนี $j ว่ายังอยู่ในอาเรย์ไหม (กันแครชจาก Nuke หรือการลบซ้อน)
            if ($j -ge $bullets.Count -or $j -lt 0) { continue }

            $b = $bullets[$j]
            if ($null -eq $b) { continue } # กันค่าว่าง
            
            $bName = $b.GetType().Name
            $hitBox = $b.GetBounds()
            
            # กำหนดดาเมจ
            $currentDmg = if ($bName -eq "HolyBomb") { 5 } else { 1 }

            if ($typeName -eq "Lucifer") {
                $foundHit = $false
                foreach ($part in $e.Parts) {
                    if (-not $part.IsDestroyed -and $part.GetBounds($e.X, $e.Y).IntersectsWith($hitBox)) {
                        
                        if ($bName -eq "Missile" -or $bName -eq "HomingMissile") { $b.Explode() }

                        if ($part.Type -eq "Turret" -and $e.Phase -lt 1) { 
                             # [Safety 2] ก่อน Remove ต้องเช็ค Count อีกรอบ
                             if ($bName -notin @("PlayerLaser", "Nuke", "Missile", "HomingMissile") -and $j -lt $bullets.Count) { 
                                $bullets.RemoveAt($j) 
                             }
                             $foundHit = $true; break 
                        }

                        $pDmg = if ($bName -eq "HolyBomb") { 50 } else { 1 }
                        if ($part.TakeDamage($pDmg)) {
                            if ($part.Type -eq "Cannon") { $e.HP -= 4000 } else { $e.HP -= 1000 }
                        }
                        
                        # [Safety 3] ลบกระสุนเฉพาะตัวที่ต้องลบ และเช็คความมีอยู่ของ index
                        if ($bName -notin @("PlayerLaser", "Nuke", "Missile", "HomingMissile") -and $j -lt $bullets.Count) { 
                            $bullets.RemoveAt($j) 
                        }
                        $foundHit = $true; break # ชนส่วนนี้แล้ว หยุดเช็คส่วนอื่นสำหรับกระสุนนัดนี้
                    }
                }
                if ($foundHit) { continue } # ข้ามไปเช็คกระสุนนัดถัดไป

                if ($e.GetBounds().IntersectsWith($hitBox)) {
                    if ($e.Phase -ge 2 -or $bName -eq "HolyBomb") {
                        if ($bName -eq "Missile" -or $bName -eq "HomingMissile") { $b.Explode() }
                        $bossDmg = if($bName -eq "HolyBomb"){800} elseif($bName -eq "Nuke"){400} elseif($bName -eq "Missile"){50} elseif($bName -eq "HomingMissile"){75} else {1}
                        $isDead = $e.TakeDamage($bossDmg)
                        if ($bName -notin @("PlayerLaser", "Nuke", "Missile", "HomingMissile") -and $j -lt $bullets.Count) { 
                            $bullets.RemoveAt($j) 
                        }
                        break 
                    } else {
                        if ($bName -ne "PlayerLaser" -and $j -lt $bullets.Count) { $bullets.RemoveAt($j) }; break
                    }
                }
                continue
            }

            # --- เช็คศัตรูทั่วไป (Watcher ฯลฯ) ---
            if ($e.GetBounds().IntersectsWith($hitBox)) {
                if ($bName -eq "Missile" -or $bName -eq "HomingMissile") { $b.Explode() }
                
                if ($bName -notin @("PlayerLaser", "Nuke", "Missile", "HomingMissile") -and $j -lt $bullets.Count) { 
                    $bullets.RemoveAt($j) 
                }
                
                if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) { 
                    $isDead = $e.TakeDamage($currentDmg); $e.FlashTimer = 3 
                } else { $isDead = $true }
                
                if ($bName -notin @("PlayerLaser", "Nuke", "Missile", "HomingMissile")) { break }
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
                $Script:wrathKills++ 

                # --- [แก้ไขจุดนี้] เพิ่มเงื่อนไขเช็คโหมดก่อนเสก Envy ---
                # เช็คว่ายอดคิลครบ 5 และ "ต้องไม่ใช่โหมด 1v1"
                $isDuelMode = $Script:gameMode -match "1v1_"

                if ($Script:wrathKills % 5 -eq 0 -and -not $isDuelMode) { 
                    [void]$enemies.Add([Envy]::new(225, -50, $player)) 
                    Write-Host ">>> ENVY HAS ENTERED THE STAGE! <<<" -ForegroundColor Magenta
                }
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

        if ($i -ge $enemyBullets.Count) { continue }

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
            # --- [เพิ่ม] เช็คมิสไซล์ศัตรู ---
            if ($bulletName -eq "EnemyMissile") {
                if ($eb.IsExploding) {
                    # ถ้าโดนวงระเบิด -> หักเลือด (Fatal Hit)
                    $result.IsPlayerHit = $true; return $result
                } else {
                    # ถ้าโดนแค่ตัวลูกมิสไซล์ตอนยังไม่ระเบิด -> ให้มันระเบิดทันที
                    $eb.Explode(); continue
                }
            }
            $result.IsPlayerHit = $true; return $result
        }
        if ($eb.Y -gt $formHeight) { $enemyBullets.RemoveAt($i) }
    }
    return $result
}