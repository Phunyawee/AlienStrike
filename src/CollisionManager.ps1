function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight) {
    # 1. เปลี่ยนตัวแปรส่งกลับ ให้มี IsPlayerHit แทน IsGameOver
    $result = @{
        ScoreAdded = 0
        IsPlayerHit = $false
    }

    # --- 1. Enemy Collisions (ชนผู้เล่น / โดนยิง / หลุดจอ) ---
    for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
        $e = $enemies[$i]

        # A. ชนผู้เล่น 
        if ($e.GetBounds().IntersectsWith($player.GetBounds())) {
            $result.IsPlayerHit = $true  # <--- แจ้งว่าโดนชน
            return $result # คืนค่ากลับไปให้ Main Logic จัดการต่อ
        }

        # B. โดนกระสุนผู้เล่น (ได้คะแนน)
        $isHit = $false
        for ($j = $bullets.Count - 1; $j -ge 0; $j--) {
            if ($e.GetBounds().IntersectsWith($bullets[$j].GetBounds())) {
                $bullets.RemoveAt($j)
                $isHit = $true
                $result.ScoreAdded += 100 # บวกคะแนน
                break
            }
        }

        if ($isHit) {
            $enemies.RemoveAt($i)
        } elseif ($e.Y -gt $formHeight) {
            # C. หลุดขอบจอ (ลบทิ้งเฉยๆ)
            $enemies.RemoveAt($i)
        }
    }

    # --- 2. Enemy Bullet Collisions (กระสุนศัตรูชนเรา) ---
    for ($i = $enemyBullets.Count - 1; $i -ge 0; $i--) {
        $eb = $enemyBullets[$i]
        
        # A. ชนผู้เล่น
        $bulletHitbox = $eb.GetBounds()
        $bulletHitbox.Inflate(-5, -5) # Hitbox เล็กลงหน่อย (หลบง่ายขึ้นนิดนึง)

        if ($bulletHitbox.IntersectsWith($player.GetBounds())) {
            $result.IsPlayerHit = $true # <--- แจ้งว่าโดนกระสุน
            return $result
        }

        # B. หลุดขอบจอ
        if ($eb.Y -gt $formHeight) {
            $enemyBullets.RemoveAt($i)
        }
    }

    return $result
}