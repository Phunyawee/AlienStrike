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


    # --- 1. Enemy Collisions (เช็คศัตรู) ---
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        $e = $enemies[$i]
        
        # [เช็คชนตัวผู้เล่น]
        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            # เช็คโล่ก่อนตาย
            if (& $Script:blockHit) { $enemies.RemoveAt($i); continue }
            $result.IsPlayerHit = $true; return $result
        }

        # [เช็คโดนกระสุนผู้เล่นยิง]
        $isDead = $false
        for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
            $b = $bullets[$j]
            if ($e.GetBounds().IntersectsWith($b.GetBounds())) {
                
                 # --- [แก้ไข] จัดการกระสุนพิเศษ ---
                if ($b -is [Missile]) {
                    $b.Explode()
                } 
                elseif ($b -is [PlayerLaser]) {
                    # เลเซอร์ไม่หายเมื่อชน (ทะลวง)
                }
                else {
                    $bullets.RemoveAt($j) # กระสุนปกติโดนแล้วหาย
                }

                # คิดดาเมจ (1 หน่วย)
                if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) {
                    $isDead = $e.TakeDamage(1) 
                } else { $isDead = $true }


                if ($isDead) {
                    if ($null -ne $e.ScoreValue) { $result.ScoreAdded += $e.ScoreValue } else { $result.ScoreAdded += 100 }

                    # --- เช็คประเภทบอสที่ตาย ---
                    $typeName = $e.GetType().Name
                    if ($typeName -eq "Lust")  { $result.LustKills += 1 }
                    if ($typeName -eq "Sloth") {
                            $result.SlothKills += 1 # เช็คให้ชัวร์ว่าสะกด Sloth ถูกต้อง
                        }
                    if ($typeName -eq "Greed") { $result.GreedKills += 1 }
                    if ($typeName -eq "Pride") { $result.PrideKilled = $true } # บอก Manager ว่า Pride ตายแล้ว
                    
                    if ($typeName -eq "Wrath") {
                        $Script:wrathKills += 1
                        $result.WrathKills += 1 
                        if ($Script:wrathKills % 5 -eq 0) {
                            [void]$enemies.Add([Envy]::new(225, -50, $player))
                        }
                    }
                }
                if ($b -isnot [Missile] -and $b -isnot [PlayerLaser]) { break }
            }
        }

        if ($isDead) { $enemies.RemoveAt($i) } 
        elseif ($e.Y -gt $formHeight) { $enemies.RemoveAt($i) }
    }

  
    # --- 2. Enemy Bullet Collisions (เช็คกระสุนศัตรู) ---
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        $eb = $enemyBullets[$i]
        $bulletName = $eb.GetType().Name  # ดึงชื่อ Class ออกมาเป็น String
        
        # --- [แก้ไขจุดนี้] เช็คระเบิด Sloth ด้วยชื่อ String แทน ---
        if ($bulletName -eq "SlothBomb") {
            $currentState = $eb.State # หรือใช้ $eb.PSObject.Properties['State'].Value
            
            # Write-Host "Manager sees SlothBomb | Current State: $currentState" -ForegroundColor Cyan
            
            if ($currentState -eq 3) {
                Write-Host "MANAGER TRIGGERING SHOCKWAVE!" -ForegroundColor Magenta
                $wave = $eb.GetShockwave()
                if ($null -ne $wave) { 
                    [void]$enemyBullets.Add($wave) 
                }
                $enemyBullets.RemoveAt($i)
                continue
            }
        }

        # --- ส่วนการเช็คชนผู้เล่น (ใช้ $bulletName เช็คให้หมดเพื่อความชัวร์) ---
        if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {

            # ถ้ามีโล่ กันได้ทุกอย่าง (Damage & Debuffs)
            if (& $Script:blockHit) { $enemyBullets.RemoveAt($i); continue }

            if ($bulletName -eq "SilenceBullet") {
                $result.ApplySilence = $true 
                $enemyBullets.RemoveAt($i)
            } 
            elseif ($bulletName -eq "SirenBullet") {
                $result.ApplySiren = $true 
                $enemyBullets.RemoveAt($i)
            }
            elseif ($bulletName -eq "GreedArrow") {
                $result.ApplyGreed = $true 
                $enemyBullets.RemoveAt($i)
                continue
            }
            elseif ($bulletName -eq "SlothShockwave") {
                $result.ApplyJammer = $true 
                # ไม่ต้อง Remove เพื่อให้คลื่นวาดจนจบอายุ
                continue 
            }
            elseif ($bulletName -eq "SlothBomb") {
                $enemyBullets.RemoveAt($i)
            }
            else {
                # กระสุนปกติ
                $result.IsPlayerHit = $true
                return $result
            }
        }

        if ($eb.Y -gt $formHeight) { $enemyBullets.RemoveAt($i) }
    }

    return $result
}