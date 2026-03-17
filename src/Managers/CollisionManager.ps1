function Invoke-GameCollisions ($player, $bullets, $enemies, $enemyBullets, $formHeight, $items) {
    # 1. เตรียมผลลัพธ์ (Shared Context)
    $context = @{
        ScoreAdded     = 0; IsPlayerHit    = $false; IsFatalHit     = $false 
        ApplySilence   = $false; ApplySiren     = $false; ApplyJammer    = $false 
        WrathKills     = 0; LustKills      = 0; SlothKills     = 0; GreedKills     = 0 
        PrideKilled    = $false; GluttonyKills  = 0; RealPrideKilled = $false 
        LuciferKilled  = $false; AceKills       = 0; ShakeIntensity = 0 
    }

    # A. เช็คภัยพิบัติ (ข้ามทุกอย่าง ตายทันที)
    Handle-UnstoppableThreats $player $enemyBullets $context

    # B. ถ้ายังอมตะอยู่ ให้ข้ามลอจิกดาเมจที่เหลือทั้งหมด
    if ($Script:immortalTimer -gt 0) { return $context }

    # C. เก็บไอเทม (Defense Drop)
    Invoke-ItemCollection $player $items

    # D. ระเบิดนิวเคลียร์ (Global Wipe)
    Invoke-GlobalNuke $bullets $enemies $context

    # E. ผู้เล่นยิงศัตรู (คำนวณดาเมจอาวุธและบอสรายชิ้น)
    Invoke-WeaponDamage $player $bullets $enemies $context

    # F. ศัตรูยิงผู้เล่น (ระบบโล่ และ ดีบัฟ)
    Invoke-PlayerDefense $player $enemies $enemyBullets $formHeight $context

    return $context
}