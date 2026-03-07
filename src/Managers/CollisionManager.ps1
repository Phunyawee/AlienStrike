# src/Managers/CollisionManager.ps1

function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight) {
    $result = @{
        ScoreAdded = 0
        IsPlayerHit = $false
    }

    # --- 1. Enemy Collisions ---
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        $e = $enemies[$i]

        # A. ชนผู้เล่น 
        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            $result.IsPlayerHit = $true
            return $result
        }

        # B. โดนกระสุนผู้เล่น
        $isDead = $false
        for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
            if ($e.GetBounds().IntersectsWith($bullets[$j].GetBounds())) {
                
                $bullets.RemoveAt($j) # ลบกระสุนทิ้ง 1 นัด
                
                # เช็คว่ามีฟังก์ชัน TakeDamage ไหม (เผื่อเป็นศัตรูระบบเก่า)
                if ($e.PsObject.Methods.Match("TakeDamage").Count -gt 0) {
                    # เรียกใช้ TakeDamage(1) ถ้าเลือดหมดมันจะคืนค่า $true
                    $isDead = $e.TakeDamage(1) 
                } else {
                    $isDead = $true # ถ้าเป็นศัตรูแบบเก่าที่ไม่มี HP ให้ตายเลย
                }

                if ($isDead) {
                    # เช็คว่าศัตรูตัวนี้มีระบบค่าหัว ($ScoreValue) ไหม
                    if ($null -ne $e.ScoreValue) {
                        $result.ScoreAdded += $e.ScoreValue # บวกตามค่าหัว (Wrath จะได้ 1000)
                    } else {
                        $result.ScoreAdded += 100 # ศัตรูธรรมดาระบบเก่า ได้ 100
                    }
                }
                
                break # กระสุน 1 นัดทำดาเมจได้ทีเดียว แล้วโดดออก
            }
        }

        if ($isDead) {
            $enemies.RemoveAt($i) # เลือดหมด ลบศัตรูทิ้ง
        } elseif ($e.Y -gt $formHeight) {
            # C. หลุดขอบจอ
            $enemies.RemoveAt($i)
        }
    }

    # --- 2. Enemy Bullet Collisions (กระสุนศัตรูชนเรา) ---
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        $eb = $enemyBullets[$i]
        
        $bulletHitbox = $eb.GetBounds()
        $bulletHitbox.Inflate(-5, -5)

        if ($bulletHitbox.IntersectsWith($player.GetBounds())) {
            $result.IsPlayerHit = $true
            return $result
        }

        if ($eb.Y -gt $formHeight) {
            $enemyBullets.RemoveAt($i)
        }
    }

    return $result
}