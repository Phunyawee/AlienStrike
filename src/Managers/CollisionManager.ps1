# src/Managers/CollisionManager.ps1

function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight) {
    $result = @{
        ScoreAdded   = 0
        IsPlayerHit  = $false
        ApplySilence = $false 
        ApplySiren   = $false # <--- [NEW] เพิ่มตัวแปรเช็คกระสุนสลับทิศ
        WrathKills   = 0 
        LustKills = 0
    }

    # --- 1. Enemy Collisions ---
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        $e = $enemies[$i]

        # 1.1 เช็คศัตรูชนผู้เล่น
        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            $result.IsPlayerHit = $true
            return $result
        }

        $isDead = $false
        # 1.2 ลูปเช็คกระสุนผู้เล่นมาโดนศัตรู
        for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
            $b = $bullets[$j] # ดึงกระสุนออกมาเช็ค

            if ($e.GetBounds().IntersectsWith($b.GetBounds())) {
                
                # --- [จุดแก้ที่ 1: การจัดการกระสุน] ---
                if ($b -is [Missile]) {
                    $b.Explode() # ถ้าเป็นมิสไซล์ ให้ "สั่งระเบิด" (ห้ามลบทิ้ง เพราะวงระเบิดต้องค้างอยู่)
                } else {
                    $bullets.RemoveAt($j) # ถ้าเป็นกระสุนปกติ ลบทิ้งทันที
                }
                
                # --- [จุดแก้ที่ 2: การคิดดาเมจ] ---
                if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) {
                    $isDead = $e.TakeDamage(1) 
                } else {
                    $isDead = $true
                }

                # --- [จุดแก้ที่ 3: จัดการตอนศัตรูตาย] ---
                if ($isDead) {
            
                    # --- แก้ตรงนี้ครับ! แยก if ออกมาบวกคะแนนแบบปกติ ---
                    if ($null -ne $e.ScoreValue) {
                        $result.ScoreAdded += $e.ScoreValue
                    } else {
                        $result.ScoreAdded += 100
                    }

                    # --- เช็คถ้าเป็น Lust ---
                    if ($e.GetType().Name -eq "Lust") {
                        $result.LustKills += 1
                    }

                    # --- เช็คถ้าเป็น Wrath ---
                    if ($e.GetType().Name -eq "Wrath") {
                        $Script:wrathKills += 1
                        $result.WrathKills += 1 
                        #ฆ่า Wrath 5
                        if ($Script:wrathKills % 1 -eq 0) {
                            $envy = [Envy]::new(225, -50, $player)
                            [void]$enemies.Add($envy)
                        }
                    }
                }

                # --- [จุดแก้ที่ 4: ระบบทะลวง] ---
                # ถ้าเป็นมิสไซล์ ไม่ต้องสั่ง break; เพราะระเบิดวงกว้างควรโดนศัตรูหลายตัวได้ในนัดเดียว
                # แต่ถ้าเป็นกระสุนปกติ ต้อง break; เพื่อจบการเช็คกระสุนนัดนี้
                if (-not ($b -is [Missile])) { break }
            }
        }

        if ($isDead) {
            $enemies.RemoveAt($i)
        } elseif ($e.Y -gt $formHeight) {
            $enemies.RemoveAt($i)
        }
    }

    # --- 2. Enemy Bullet Collisions ---
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        $eb = $enemyBullets[$i]
        
        $bulletHitbox = $eb.GetBounds()
        
        # ปรับ Hitbox ไม่ลดขนาดถ้าเป็นกระสุนสถานะ (ใบ้ หรือ สลับทิศ)
        if ($eb.GetType().Name -in @("SilenceBullet", "SirenBullet")) {
            $bulletHitbox.Inflate(0, 0) 
        } else {
            $bulletHitbox.Inflate(-1, -1)
        }

        if ($bulletHitbox.IntersectsWith($player.GetBounds())) {
            
            # --- เช็คว่าเป็นกระสุนใบ้ไหม ---
            if ($eb.GetType().Name -eq "SilenceBullet") {
                $result.ApplySilence = $true 
                $enemyBullets.RemoveAt($i)   
                continue                     
            } 
            # --- [NEW] เช็คว่าเป็นกระสุนสลับทิศ (Siren) ไหม ---
            elseif ($eb.GetType().Name -eq "SirenBullet") {
                $result.ApplySiren = $true 
                $enemyBullets.RemoveAt($i)   
                continue                     
            } 
            # --- ถ้าไม่ใช่ปืนสถานะ = โดนดาเมจ/ตาย ---
            else {
                $result.IsPlayerHit = $true
                return $result
            }
        }

        if ($eb.Y -gt $formHeight) {
            $enemyBullets.RemoveAt($i)
        }
    }

    return $result
}