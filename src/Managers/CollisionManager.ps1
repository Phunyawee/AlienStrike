function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight, $items) {
    $result = @{
        ScoreAdded   = 0; IsPlayerHit  = $false; IsFatalHit   = $false 
        ApplySilence = $false; ApplySiren = $false; ApplyJammer  = $false 
        WrathKills   = 0; LustKills    = 0; SlothKills   = 0; GreedKills = 0 
        PrideKilled  = $false; GluttonyKills = 0; RealPrideKilled = $false 
        LuciferKilled = $false; ShakeIntensity = 0 ;# <--- [NEW] เพิ่มตัวแปรสั่นจอ
        AceKills = 0 
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
            # [จุดแก้ที่ 1] กันบั๊ก Index Out of Range จาก Nuke
            if ($i -ge $enemies.Count) { continue } 

            $e = $enemies[$i]; $eName = $e.GetType().Name; $nukeDead = $false
            
            if ($eName -eq "Lucifer") {
                foreach ($part in $e.Parts) { if (-not $part.IsDestroyed -and $part.TakeDamage(200)) { if ($part.Type -eq "Cannon") { $e.HP -= 4000 } else { $e.HP -= 1000 } } }
                $nukeDead = $e.TakeDamage(5) 
            }
            elseif ($eName -eq "RealPride") { $nukeDead = $e.TakeDamage(200) }
            elseif ($eName -eq "Gluttony")  { $nukeDead = $e.TakeDamage(50) }
            # ใน Global Nuke Check
            elseif ($eName -eq "RealPride") { $nukeDead = $e.TakeDamage(200) }
            elseif ($eName -eq "Nephilim") { $nukeDead = $e.TakeDamage(200) } # <--- เพิ่มตัวนี้
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
                        $bossDmg = if($bName -eq "HolyBomb"){800} elseif($bName -eq "Nuke"){400} elseif($bName -eq "Missile"){50} elseif($bName -eq "HomingMissile"){50} else {1}
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

           # --- [ส่วนเช็ค Nephilim ใน CollisionManager] ---
                if ($typeName -eq "Nephilim") {
                    $hitBox = $b.GetBounds()
                    
                    # 1. เช็คชนปืนเลเซอร์กลาง (ต้องพังอันนี้ก่อนเพื่อน)
                    if ($e.LaserHP -gt 0) {
                        # --- [แก้ไข] ปรับพิกัดสี่เหลี่ยมเช็คชนให้ต่ำลงตามรูปวาดใหม่ (30 -> 45) ---
                        $laserRect = [System.Drawing.RectangleF]::new($e.X + 55, $e.Y + 40, 50, 50)
                        if ($laserRect.IntersectsWith($hitBox)) {
                            $e.LaserHP -= $currentDmg
                            $e.FlashTimer = 3
                            if ($bName -ne "PlayerLaser") { $bullets.RemoveAt($j) }
                        }
                        continue 
                    }
                    # 2. เช็คชนใบพัด (หลังจากเลเซอร์พังแล้ว - Phase 1)
                    if ($e.Phase -eq 1) {
                        $hitPart = $false
                        # กรงเล็บใบ้พัดซ้ายและขวา
                        $lBladeRect = [System.Drawing.RectangleF]::new($e.X + 5, $e.Y - 45, 50, 50)
                        $rBladeRect = [System.Drawing.RectangleF]::new($e.X + 105, $e.Y - 45, 50, 50)

                        if ($e.LeftBladeHP -gt 0 -and $lBladeRect.IntersectsWith($hitBox)) {
                            $e.LeftBladeHP -= $currentDmg; $hitPart = $true
                        }
                        elseif ($e.RightBladeHP -gt 0 -and $rBladeRect.IntersectsWith($hitBox)) {
                            $e.RightBladeHP -= $currentDmg; $hitPart = $true
                        }

                        if ($hitPart) {
                            $e.FlashTimer = 3
                            if ($bName -ne "PlayerLaser") { $bullets.RemoveAt($j) }
                            continue 
                        }
                        continue # ถ้าไม่โดนใบพัด กระสุนจะผ่านตัวแม่ไป (เพราะยังไม่ Phase 2)
                    }

                    # 3. เข้าตัวแม่ (Phase 2 - หลังจากใบพัดพังหมด)
                    if ($e.Phase -eq 2) {
                        if ($e.GetBounds().IntersectsWith($hitBox)) {
                            $isDead = $e.TakeDamage($currentDmg)
                            if ($bName -ne "PlayerLaser") { $bullets.RemoveAt($j) }
                            break
                        }
                    }
                    continue
                }

                 # --- ในลูปเช็คกระสุนศัตรูชนผู้เล่น ---
         

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
            elseif ($typeName -eq "Watcher") {
                if ($e.Type -eq "Ace") { 
                    $result.AceKills += 1 # นับเฉพาะตัวแดง
                }
            }
            elseif ($typeName -eq "Wrath") {
                $result.WrathKills += 1
                $Script:wrathKills++ 
                
                # --- [แก้ไข] ห้ามเสก Envy ถ้าอยู่ในโหมด Simulation ---
                if ($Script:wrathKills % 5 -eq 0 -and $Script:gameMode -notin @("1v1_LUCIFER", "Simulation")) { 
                    [void]$enemies.Add([Envy]::new(225, -50, $player)) 
                }
            }
            $enemies.RemoveAt($i)
        } elseif ($e.Y -gt $formHeight) { $enemies.RemoveAt($i) }
    }

    # ==========================================
    # 5. BOSS FATAL ATTACKS
    # ==========================================
    # --- 2. Fatal Beam Checks ---
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
         # [เพิ่ม] Nephilim Fatal Laser (Phase 0 เท่านั้น)
        if ($bName -eq "Nephilim" -and $boss.Phase -eq 0 -and $boss.ChargeTimer -ge 2.5) {
            $beam = [System.Drawing.RectangleF]::new(($boss.X + 65.0), [float]($boss.Y + 70), 30.0, 600.0)
            if ($beam.IntersectsWith($player.GetBounds())) { $result.IsPlayerHit = $true; $result.IsFatalHit = $true }
        }
    }

    # ==========================================
    # 6. ENEMY PROJECTILES & DEBUFFS
    # ==========================================
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        if ($i -ge $enemyBullets.Count) { continue }
        $eb = $enemyBullets[$i]; $bulletName = $eb.GetType().Name
        if ($bulletName -eq "SlothBomb" -and $eb.State -eq 3) { # ... Sloth Logic ...
             $wave = $eb.GetShockwave(); if ($wave) { [void]$enemyBullets.Add($wave) }; $enemyBullets.RemoveAt($i); continue
        }

        if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
            
            # [A] กลุ่มพิเศษ: หักโล่ตามจำนวน (Shredders)
            if ($bulletName -match "GluttonyBlast") {
                $lost = if ($Script:defenseHits -ge 10) { [math]::Floor($Script:defenseHits * 0.5) } else { $Script:defenseHits }
                $Script:defenseHits -= $lost

                # --- [เพิ่มส่วนนี้กลับเข้าไป] ตรรกะการฮีลบอส Gluttony ---
                foreach ($boss in $enemies) {
                    if ($boss.GetType().Name -eq "Gluttony") { 
                        $boss.HP += $lost 
                        Write-Host ">>> GLUTTONY CONSUMED $lost SHIELD POINTS! <<<" -ForegroundColor Magenta
                    }
                }
                # --------------------------------------------------

                $enemyBullets.RemoveAt($i)
                if ($lost -eq 0 -and $Script:defenseHits -eq 0) { $result.IsPlayerHit = $true }
                continue
            }
            if ($bulletName -match "NephilimBlade") {
                $Script:defenseHits = [math]::Max(0, $Script:defenseHits - 50)
                $enemyBullets.RemoveAt($i); if ($Script:defenseHits -eq 0) { Write-Host "SHIELD BROKEN!" -ForegroundColor Red }; continue
            }
            if ($eb.SpeedY -eq 15) { # กระสุน Lucifer Turret
                $Script:defenseHits = [math]::Max(0, $Script:defenseHits - 5)
                $enemyBullets.RemoveAt($i); continue
            }

            # [B] เช็คระบบโล่ปกติ (Block ทุกอย่างที่เหลือ)
            # ถ้ามีโล่ จะหัก 1 แต้มและข้ามการเช็ค Effect ด้านล่างทันที!
            if (& $Script:blockHit) { 
                $enemyBullets.RemoveAt($i)
                Write-Host ">>> ATTACK BLOCKED BY SHIELD <<<" -ForegroundColor Cyan
                continue 
            }

            # [C] ผลกระทบเมื่อ "ไม่มีโล่" (Damage & Status)
            if ($bulletName -match "SirenBullet") { $result.ApplySiren = $true }
            elseif ($bulletName -match "SilenceBullet") { $result.ApplySilence = $true }
            elseif ($bulletName -match "GreedArrow") { $result.ApplyGreed = $true }
            elseif ($bulletName -match "SlothShockwave") { $result.ApplyJammer = $true; continue }
            elseif ($bulletName -match "EnemyMissile") { if ($eb.IsExploding) { $result.IsPlayerHit = $true } else { $eb.Explode(); continue } }
            else { $result.IsPlayerHit = $true }

            if ($bulletName -ne "SlothShockwave") { $enemyBullets.RemoveAt($i) }
            if ($result.IsPlayerHit) { return $result }
        }
        if ($eb.Y -gt $formHeight) { $enemyBullets.RemoveAt($i) }
    }
    return $result
}