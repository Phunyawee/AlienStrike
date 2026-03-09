function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight) {
    $result = @{
        ScoreAdded   = 0
        IsPlayerHit  = $false
        ApplySilence = $false 
        ApplySiren   = $false
        ApplyJammer  = $false # <--- [NEW] เพิ่มสถานะ Jammer
        WrathKills   = 0 
        LustKills    = 0
        SlothKills   = 0
        GreedKills = 0 
        PrideKilled  = $false # <--- [NEW] เพิ่มตัวเช็ค Pride ตาย
    }

     # ฟังก์ชันช่วยเช็ค: ถ้ามีโล่ ให้หักโล่แล้วคืนค่า True (คือกันสำเร็จ)
    $Script:blockHit = {
        if ($Script:defenseHits -gt 0) {
            $Script:defenseHits -= 1
            return $true
        }
        return $false
    }


    # --- 1. Enemy Collisions ---
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        $e = $enemies[$i]
        $isDead = $false

        # ==========================================
        # [NEW] เช็คการระเบิดของ Nuke (Field Wipe)
        # ==========================================
        # เราเช็คว่ามี Nuke ลูกไหนในลิสต์กระสุนที่ "ระเบิดแล้ว" หรือไม่
        foreach ($b in $bullets) {
            if ($b.GetType().Name -eq "Nuke" -and $b.Exploded) {
                $eName = $e.GetType().Name
                
                # เช็คว่าศัตรูเป็นพวกบอส (BaseEnemy) หรือไม่
                if ($e -is [BaseEnemy]) {
                    if ($eName -eq "Gluttony") { $isDead = $e.TakeDamage(5) }
                    elseif ($eName -eq "Lucifer") { $isDead = $e.TakeDamage(3) }
                    else { $isDead = $e.TakeDamage(99) }
                } else {
                    # ถ้าเป็นศัตรูธรรมดา (Enemy) ไม่มี TakeDamage ให้ตายทันที
                    $isDead = $true
                }
            }
        }

        # [เช็คชนตัวผู้เล่น]
        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            # ระบบ Defense Shield (โค้ดเดิมที่เคยทำไว้)
            if (& $Script:blockHit) { $enemies.RemoveAt($i); continue }
            $result.IsPlayerHit = $true
            return $result
        }

        # [เช็คโดนกระสุนผู้เล่นยิงแบบปกติ]
        # ทำงานเฉพาะเมื่อศัตรูยังไม่ตายจาก Nuke ด้านบน
        if (-not $isDead) {
            for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
                $b = $bullets[$j]
                if ($e.GetBounds().IntersectsWith($b.GetBounds())) {
                    
                    # --- จัดการกระสุนพิเศษ ---
                    if ($b -is [Missile]) {
                        $b.Explode()
                    } 
                    elseif ($b -is [PlayerLaser]) {
                        # เลเซอร์ไม่หายเมื่อชน (ทะลวง)
                    }
                    elseif ($b.GetType().Name -eq "Nuke") {
                        # Nuke จะไม่ชนกับศัตรู (วิ่งทะลุไปจนกว่าจะถึงจุดระเบิด)
                        continue 
                    }
                    else {
                        $bullets.RemoveAt($j) # กระสุนปกติโดนแล้วหาย
                    }

                    # คิดดาเมจปกติ (1 หน่วย)
                    if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) {
                        $isDead = $e.TakeDamage(1) 
                    } else { $isDead = $true }

                    # ออกจากลูปกระสุนถ้าไม่ใช่กระสุนทะลวง
                    if ($b -isnot [Missile] -and $b -isnot [PlayerLaser]) { break }
                }
            }
        }

        # --- ประมวลผลเมื่อศัตรูตาย ---
        if ($isDead) {
            if ($null -ne $e.ScoreValue) { $result.ScoreAdded += $e.ScoreValue } else { $result.ScoreAdded += 100 }

            $typeName = $e.GetType().Name
            
            # [NEW] ถ้าคิล Gluttony ได้
            if ($typeName -eq "Gluttony") { $result.GluttonyKills += 1 }
            
            # บอสอื่นๆ (เหมือนเดิม)
            if ($typeName -eq "Lust")  { $result.LustKills += 1 }
            if ($typeName -eq "Sloth") { $result.SlothKills += 1 }
            if ($typeName -eq "Greed") { $result.GreedKills += 1 }
            if ($typeName -eq "Pride") { $result.PrideKilled = $true }
            if ($typeName -eq "Wrath") {
                $Script:wrathKills += 1
                $result.WrathKills += 1 
                if ($Script:wrathKills % 5 -eq 0) {
                    [void]$enemies.Add([Envy]::new(225, -50, $player))
                }
            }
            
            $enemies.RemoveAt($i)
        } elseif ($e.Y -gt $formHeight) {
            $enemies.RemoveAt($i)
        }
    }

  
    # --- 2. Enemy Bullet Collisions ---
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        $eb = $enemyBullets[$i]
        $bulletName = $eb.GetType().Name
        
        # [NEW] พิเศษ: จัดการ SlothBomb (ตัวระเบิด)
        if ($bulletName -eq "SlothBomb" -and $eb.State -eq 3) {
            $wave = $eb.GetShockwave(); if ($null -ne $wave) { [void]$enemyBullets.Add($wave) }
            $enemyBullets.RemoveAt($i); continue
        }

        # --- ส่วนการเช็คชนผู้เล่น ---
        if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {

            # [จุดที่ต้องย้าย!] เช็คกระสุนม่วง "ก่อน" โล่ปกติ
            if ($bulletName -eq "GluttonyBlast") {
                $lost = 0
                if ($Script:defenseHits -ge 10) {
                    $lost = [math]::Floor($Script:defenseHits * 0.5)
                    $Script:defenseHits -= $lost
                } else {
                    $lost = $Script:defenseHits
                    $Script:defenseHits = 0
                }
                
                # ฮีลบอส Gluttony
                foreach ($boss in $enemies) {
                    if ($boss.GetType().Name -eq "Gluttony") { $boss.HP += $lost }
                }

                $enemyBullets.RemoveAt($i)
                # ถ้าไม่มีโล่เหลือแล้ว และโดนยิง จะเสีย Life
                if ($lost -eq 0 -and $Script:defenseHits -eq 0) { $result.IsPlayerHit = $true }
                continue # จบการทำงานของนัดนี้ทันที ไม่ไปเข้า blockHit ด้านล่าง
            }

            # --- [ระบบโล่ปกติ] กันกระสุนทั่วไป (ยกเว้นกระสุนม่วงที่หลุดลงมาถึงนี่) ---
            if (& $Script:blockHit) { 
                $enemyBullets.RemoveAt($i)
                continue 
            }

            # --- [เช็ค Debuff อื่นๆ] ---
            if ($bulletName -eq "SilenceBullet") {
                $result.ApplySilence = $true; $enemyBullets.RemoveAt($i); continue
            } 
            elseif ($bulletName -eq "SirenBullet") {
                $result.ApplySiren = $true; $enemyBullets.RemoveAt($i); continue
            }
            elseif ($bulletName -eq "GreedArrow") {
                $result.ApplyGreed = $true; $enemyBullets.RemoveAt($i); continue
            }
            elseif ($bulletName -eq "SlothShockwave") {
                $result.ApplyJammer = $true; continue 
            }
            else {
                # กระสุนปกติโดนแล้วตาย (ถ้าไม่มีโล่เหลือ)
                $result.IsPlayerHit = $true
                return $result
            }
        }
        if ($eb.Y -gt $formHeight) { $enemyBullets.RemoveAt($i) }
    }

    return $result
}