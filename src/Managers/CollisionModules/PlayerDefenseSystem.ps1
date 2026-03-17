function Invoke-PlayerDefense ($player, $enemies, $enemyBullets, $formHeight, $context) {
    # 1. Fatal Boss Beams (ตายทันที ทะลุโล่)
    foreach ($boss in $enemies) {
        if ($null -eq $boss) { continue }
        $bName = $boss.GetType().Name
        $isBeamActive = $false
        $beamRect = [System.Drawing.RectangleF]::Empty

        if ($bName -eq "RealPride" -and $boss.State -eq 2) {
            $beamRect = [System.Drawing.RectangleF]::new(($boss.X + ($boss.Width/2.0) - 15.0), [float]($boss.Y + 55), 30.0, 600.0)
            $isBeamActive = $true
        }
        elseif ($bName -eq "Lucifer" -and $boss.ChargeTimer -ge 2.5) {
            # (ลอจิกเลเซอร์ Lucifer...)
            $isBeamActive = $true # สมมติสร้าง $beamRect แล้ว
        }
        elseif ($bName -eq "Nephilim" -and $boss.Phase -eq 0 -and $boss.ChargeTimer -ge 2.5) {
            $beamRect = [System.Drawing.RectangleF]::new(($boss.X + 65.0), [float]($boss.Y + 85.0), 30.0, 600.0)
            $isBeamActive = $true
        }

        if ($isBeamActive -and $beamRect.IntersectsWith($player.GetBounds())) {
            $context.IsPlayerHit = $true
            $context.IsFatalHit = $true # สั่งไม่ล้างกระดาน (กฎ Chapter 2)
            $context.ShakeIntensity = 10
            return
        }
    }

    # 2. Enemy Bullets & Shield logic
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        if ($i -ge $enemyBullets.Count) { continue }
        $eb = $enemyBullets[$i]; $ebName = $eb.GetType().Name
        
        # [A] พิเศษ: บอล Sloth และ คลื่นพลังงาน
        if ($ebName -eq "SlothBomb" -and $eb.State -eq 3) {
            $wave = $eb.GetShockwave(); if ($wave) { [void]$enemyBullets.Add($wave) }; $enemyBullets.RemoveAt($i); continue
        }
        if ($ebName -eq "SovereignPulse" -and $eb.GetBounds().IntersectsWith($player.GetBounds())) {
            if ($Script:defenseHits -gt 50) { $Script:defenseHits = 50 }; continue
        }

        # --- เช็คการปะทะตัวผู้เล่น ---
        if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
            
            # 1. กลุ่มหักโล่หนัก (Shredders)
            if ($ebName -match "GluttonyBlast") {
                $lost = if ($Script:defenseHits -ge 10) { [math]::Floor($Script:defenseHits * 0.5) } else { $Script:defenseHits }
                $Script:defenseHits -= $lost
                foreach ($boss in $enemies) { if ($boss.GetType().Name -eq "Gluttony") { $boss.HP += $lost } }
                $enemyBullets.RemoveAt($i); if ($lost -eq 0 -and $Script:defenseHits -eq 0) { $context.IsPlayerHit = $true }
                continue
            }

            # --- [จุดแก้สำคัญ] ใบพัด Nephilim: หักโล่ 50 ถ้าไม่มีโล่ให้ตายทันที ---
            if ($ebName -match "NephilimBlade") {
                if ($Script:defenseHits -gt 0) {
                    $Script:defenseHits = [math]::Max(0, $Script:defenseHits - 50)
                    Write-Host ">>> SHIELD CRITICAL: -50 POINTS! <<<" -ForegroundColor Red
                    $enemyBullets.RemoveAt($i)
                } else {
                    # ไม่มีโล่แล้ว -> ตายแบบ Fatal (อมตะ 3 วิ)
                    $context.IsPlayerHit = $true
                    $context.IsFatalHit = $true
                    $enemyBullets.RemoveAt($i)
                }
                continue
            }

            if ($eb.SpeedY -eq 15 -and $ebName -ne "SirenBullet") {
                $Script:defenseHits = [math]::Max(0, $Script:defenseHits - 5)
                $enemyBullets.RemoveAt($i); continue
            }

            # 2. ระบบโล่ปกติ (Block 1 แต้ม)
            if ($Script:defenseHits -gt 0) {
                $Script:defenseHits -= 1
                $enemyBullets.RemoveAt($i); continue 
            }

            # 3. ถ้าไม่มีโล่แล้ว (ติดดีบัฟหรือดาเมจเข้าเนื้อ)
            if ($ebName -match "SirenBullet") { $context.ApplySiren = $true }
            elseif ($ebName -match "SilenceBullet") { $context.ApplySilence = $true }
            elseif ($ebName -match "GreedArrow") { $context.ApplyGreed = $true }
            elseif ($ebName -match "SlothShockwave") { $context.ApplyJammer = $true; continue }
            elseif ($ebName -match "EnemyMissile") {
                if ($eb.IsExploding) { $context.IsPlayerHit = $true } else { $eb.Explode(); continue }
            }
            else { $context.IsPlayerHit = $true }

            if ($ebName -ne "SlothShockwave") { $enemyBullets.RemoveAt($i) }
        }
        if ($eb.Y -gt $formHeight) { $enemyBullets.RemoveAt($i) }
    }
}