# src/Managers/CollisionManager.ps1

function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight) {
    $result = @{
        ScoreAdded = 0
        IsPlayerHit = $false
        ApplySilence = $false 
        WrathKills = 0 # <--- [เพิ่มตรงนี้] ตัวแปรส่งกลับไปบอกให้สุ่มบัฟ
    }

    # --- 1. Enemy Collisions ---
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        $e = $enemies[$i]

        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            $result.IsPlayerHit = $true
            return $result
        }

        $isDead = $false
        for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
            if ($e.GetBounds().IntersectsWith($bullets[$j].GetBounds())) {
                $bullets.RemoveAt($j)
                
                if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) {
                    $isDead = $e.TakeDamage(1) 
                } else {
                    $isDead = $true
                }

                if ($isDead) {
                    if ($null -ne $e.ScoreValue) {
                        $result.ScoreAdded += $e.ScoreValue
                    } else {
                        $result.ScoreAdded += 100
                    }

                    # ==========================================
                    # [NEW] ระบบนับ Kill Wrath และเรียก Envy (บอสลับ)
                    # ==========================================
                    if ($e.GetType().Name -eq "Wrath") {
                        
                        $Script:wrathKills += 1
                        $result.WrathKills += 1 # <--- [เพิ่มตรงนี้] บอกไฟล์หลักว่า Wrath ตายแล้วนะ!

                        # ถ้าฆ่าครบ 5 ตัว ให้เกิด Envy ทันที!
                        if ($Script:wrathKills % 5 -eq 0) {
                            # ให้เกิดตรงกลางจอ (X=225) และลอยลงมาจากขอบจอบน
                            $envy = [Envy]::new(225, -50, $player)
                            [void]$enemies.Add($envy)
                        }
                    }
                }
                break 
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
        
        if ($eb.GetType().Name -eq "SilenceBullet") {
            $bulletHitbox.Inflate(0, 0) 
        } else {
            $bulletHitbox.Inflate(-1, -1)
        }

        if ($bulletHitbox.IntersectsWith($player.GetBounds())) {
            
            # เช็คว่าเป็นกระสุนใบ้ไหม
            if ($eb.GetType().Name -eq "SilenceBullet") {
                $result.ApplySilence = $true 
                $enemyBullets.RemoveAt($i)   
                continue                     
            } else {
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