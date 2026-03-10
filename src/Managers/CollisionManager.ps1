function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight) {
    $result = @{
        ScoreAdded   = 0; IsPlayerHit  = $false; IsFatalHit   = $false 
        ApplySilence = $false; ApplySiren   = $false; ApplyJammer  = $false 
        WrathKills   = 0; LustKills    = 0; SlothKills   = 0; GreedKills = 0 
        PrideKilled  = $false; GluttonyKills = 0; RealPrideKilled = $false 
    }

    # --- [NEW] ระบบ Immortal Check ---
    # ถ้ายังเป็นอมตะอยู่ ให้ข้ามการเช็คดาเมจและดีบัฟทั้งหมดไปเลย (โกงความตาย)
    if ($Script:immortalTimer -gt 0) {
        return $result
    }

    $Script:blockHit = { if ($Script:defenseHits -gt 0) { $Script:defenseHits -= 1; return $true }; return $false }

    # --- 1. Enemy Collisions ---
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        $e = $enemies[$i]
        $isDead = $false
        $typeName = $e.GetType().Name 

        # [เช็ค Nuke]
        foreach ($b in $bullets) {
            if ($b.GetType().Name -eq "Nuke" -and $b.Exploded) {
                if ($e -is [BaseEnemy]) {
                    if ($typeName -eq "Gluttony") { $isDead = $e.TakeDamage(50) }
                    elseif ($typeName -eq "Lucifer") { $isDead = $e.TakeDamage(3) }
                    elseif ($typeName -eq "RealPride") { $isDead = $e.TakeDamage(200) }
                    else { $isDead = $e.TakeDamage(99) }
                } else { $isDead = $true }
            }
        }

        # [เช็คชนผู้เล่น]
        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            if (& $Script:blockHit) { $enemies.RemoveAt($i); continue }
            $result.IsPlayerHit = $true; return $result
        }

        # [เช็คโดนยิง]
        if (-not $isDead) {
            for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
                $b = $bullets[$j]
                if ($e.GetBounds().IntersectsWith($b.GetBounds())) {
                    if ($b -is [Missile]) { $b.Explode() } 
                    elseif ($b.GetType().Name -ne "PlayerLaser") { $bullets.RemoveAt($j) }
                    
                    if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) { $isDead = $e.TakeDamage(1) } else { $isDead = $true }
                    if ($b.GetType().Name -ne "Missile" -and $b.GetType().Name -ne "PlayerLaser") { break }
                }
            }
        }

        if ($isDead) {
            # --- แก้ไขตรงนี้: แยก IF ออกมาบวกคะแนนแบบปกติ ---
            if ($null -ne $e.ScoreValue) { $result.ScoreAdded += $e.ScoreValue } else { $result.ScoreAdded += 100 }
            
            if ($typeName -eq "Gluttony") { $result.GluttonyKills += 1 }
            elseif ($typeName -eq "Lust")     { $result.LustKills += 1 }
            elseif ($typeName -eq "Sloth")    { $result.SlothKills += 1 }
            elseif ($typeName -eq "Greed")    { $result.GreedKills += 1 }
            elseif ($typeName -eq "Pride")    { $result.PrideKilled = $true }
            elseif ($typeName -eq "RealPride"){ $result.RealPrideKilled = $true }
            
            if ($typeName -eq "Wrath") {
                $result.WrathKills += 1      # <--- [เพิ่มบรรทัดนี้เข้าไปครับ!]
                
                $Script:wrathKills++         # อันนี้ของเดิมที่ใช้นับเรียก Envy (ปล่อยไว้เหมือนเดิม)
                if ($Script:wrathKills % 5 -eq 0) { [void]$enemies.Add([Envy]::new(225, -50, $player)) }
            }
            $enemies.RemoveAt($i)
        } elseif ($e.Y -gt $formHeight) { $enemies.RemoveAt($i) }
    }

    # --- 2. RealPride Fatal Laser ---
    foreach ($boss in $enemies) {
        if ($boss.GetType().Name -eq "RealPride" -and $boss.State -eq 2) {
            $bx = $boss.X + ($boss.Width / 2.0) - 15.0
            $beamRect = [System.Drawing.RectangleF]::new($bx, [float]($boss.Y + 55), 30.0, 600.0)
            if ($beamRect.IntersectsWith($player.GetBounds())) {
                $result.IsPlayerHit = $true
                $result.IsFatalHit = $true 
            }
        }
    }

    # --- 3. Enemy Bullet Collisions ---
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        $eb = $enemyBullets[$i]
        $bulletName = $eb.GetType().Name

         # --- [NEW] เช็คคลื่นล้างโลก (Hard GameOver) ---
        if ($bulletName -eq "CataclysmWave") {
            if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
                $result.IsPlayerHit = $true
                $Script:lives = 0 # บังคับชีวิตเป็น 0 ทันที
                return $result # จบเกมแน่นอน
            }
        }

        # --- [NEW] เช็ค Sovereign Grace (Blue Laser) ---
        if ($bulletName -eq "SovereignPulse") {
            if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
                if ($Script:defenseHits -gt 50) { $Script:defenseHits = 50 }
                # ไม่ Remove คลื่นออกเพื่อให้มันกวาดจนจบอายุ
                continue
            }
        }



        if ($bulletName -eq "SlothBomb" -and $eb.State -eq 3) {
            $wave = $eb.GetShockwave(); if ($null -ne $wave) { [void]$enemyBullets.Add($wave) }; $enemyBullets.RemoveAt($i); continue
        }

        if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
            # --- แก้ไขตรงนี้: แยก IF คำนวณโล่ Gluttony ---
            if ($bulletName -eq "GluttonyBlast") {
                $lost = 0
                if ($Script:defenseHits -ge 10) { $lost = [math]::Floor($Script:defenseHits * 0.5) } 
                else { $lost = $Script:defenseHits }
                
                $Script:defenseHits -= $lost
                foreach ($b in $enemies) { if ($b.GetType().Name -eq "Gluttony") { $b.HP += $lost } }
                $enemyBullets.RemoveAt($i)
                if ($lost -eq 0 -and $Script:defenseHits -eq 0) { $result.IsPlayerHit = $true }
                continue
            }

            if (& $Script:blockHit) { $enemyBullets.RemoveAt($i); continue }

            if ($bulletName -eq "SilenceBullet") { $result.ApplySilence = $true; $enemyBullets.RemoveAt($i); continue } 
            elseif ($bulletName -eq "SirenBullet")   { $result.ApplySiren = $true;   $enemyBullets.RemoveAt($i); continue }
            elseif ($bulletName -eq "GreedArrow")   { $result.ApplyGreed = $true;   $enemyBullets.RemoveAt($i); continue }
            elseif ($bulletName -eq "SlothShockwave") { $result.ApplyJammer = $true; continue }
            else {
                $result.IsPlayerHit = $true
                return $result
            }
        }
        if ($eb.Y -gt $formHeight) { $enemyBullets.RemoveAt($i) }
    }
    return $result
}