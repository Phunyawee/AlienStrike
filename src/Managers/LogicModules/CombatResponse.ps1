# src/Managers/LogicModules/CombatResponse.ps1

# ==========================================
# 3. CORE LOGIC: ระบบการชนและประมวลผล
# ==========================================
function Handle-PostCollision ($collisionResult) {
    if ($collisionResult.ScoreAdded -gt 0) { $Script:score += $collisionResult.ScoreAdded }
    $isLuciferActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" }).Count -gt 0

    # จัดการการตายของ Gluttony
    if ($collisionResult.GluttonyKills -gt 0) { 
        Add-To-Inventory "Nuke" 1; $Script:totalGluttonyKills += $collisionResult.GluttonyKills 
        Write-Host ">>> GLUTTONY DEFEATED ($Script:totalGluttonyKills / 3) <<<" -ForegroundColor Magenta
    }

    # จัดการการตายของ RealPride (Gatekeeper)
    if ($collisionResult.RealPrideKilled) { 
        $Script:realPrideDefeatedTotal++; $Script:totalGluttonyKills = 0
        [void]$Script:enemyBullets.Add([SovereignPulse]::new($Script:player.Y + 5))
        Write-Host ">>> GATEKEEPER DEFEATED ($Script:realPrideDefeatedTotal / 2) <<<" -ForegroundColor Yellow
    }

    # ชนะบอส Lucifer
    if ($collisionResult.LuciferKilled) {
        $Script:victoryTimer = 180; $Script:isLuciferDead = $true
        Write-Host ">>> LUCIFER HAS BEEN BANISHED <<<" -ForegroundColor Green
        return $true 
    }

    # ระบบบัฟและรางวัลจากศัตรู (ใช้ระบบ Loop แบบใหม่)
    if ($collisionResult.LustKills -gt 0) { 
        for($i=0;$i-lt $collisionResult.LustKills;$i++) { Add-To-Inventory "Missile" 5 } 
    }
    
    if ($collisionResult.SlothKills -gt 0) { 
        $Script:speedTimer = 420 
        Write-Host ">>> SPEED BOOST ACTIVATED <<<" -ForegroundColor Cyan 
    }
    
    if ($collisionResult.GreedKills -gt 0) { 
        $Script:defenseHits += (10 * $collisionResult.GreedKills) 
        Write-Host ">>> SHIELD REINFORCED <<<" -ForegroundColor Cyan 
    }
    # --- [แก้ไข] รางวัลจากการคิล Watcher แดง (Ace) ---
    if ($collisionResult.AceKills -gt 0) {
        # เช็คว่าบอส Azazel อยู่ในสนามไหม
        $isAzazelActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Azazel" }).Count -gt 0
        
        if ($isAzazelActive) {
            # --- [เงื่อนไขใหม่] โอกาส 50% ได้ Red Laser 2 อัน ---
            if ($Script:rnd.Next(1, 101) -le 50) {
                for($i=0; $i -lt 2; $i++) { Add-To-Inventory "RedLaser" 1 }
                Write-Host ">>> EXPERIMENTAL TECH ACQUIRED: 2 RED LASERS <<<" -ForegroundColor Red
            } else {
                # กรณี 50% ที่เหลือ ได้เลเซอร์ปกติ 10 นัด
                Add-To-Inventory "Laser" (10 * $collisionResult.AceKills)
                Write-Host ">>> BOSS REINFORCEMENTS WIPED: +10 LASER <<<" -ForegroundColor Green
            }
        } else {
            # ถ้าอยู่ในเวฟปกติ (ไม่ใช่ Azazel) แจก Homing 3 นัดตามเดิม
            Add-To-Inventory "Homing" (3 * $collisionResult.AceKills)
            Write-Host ">>> ELITE DOWN: +3 HOMING MISSILES <<<" -ForegroundColor Yellow
        }
    }
    
    if ($collisionResult.PrideKilled) { $Script:prideKills++ }
    
    if ($collisionResult.WrathKills -gt 0 -and $isLuciferActive) { 
        for($i=0;$i-lt $collisionResult.WrathKills;$i++) { 
            Add-To-Inventory "Laser" 5; Add-To-Inventory "Missile" 5 

            # 2. [NEW] โอกาส 5% ดรอป Holy Bomb (อาวุธปราบมาร)
            if ($Script:rnd.Next(1, 101) -le 5) {
                Add-To-Inventory "HolyBomb" 1
                Write-Host ">>> HOLY BOMB ACQUIRED! THE LIGHT IS WITH YOU! <<<" -ForegroundColor White
            }
        } 
        Write-Host ">>> ARSENAL REPLENISHED! <<<" -ForegroundColor Green
    }

    if ($collisionResult.WrathKills -gt 0 -and $Script:wrathBuffLevel -lt 2) {
        for ($k = 0; $k -lt $collisionResult.WrathKills; $k++) {
            $Script:wrathStackCount++
            if ($Script:wrathStackCount -ge 3) { 
                $Script:wrathBuffLevel = 2; $Script:wrathBuffTimer = 840; $Script:wrathStackCount = 0 
            } else { 
                $Script:wrathBuffLevel = 1; $Script:wrathBuffTimer = 420 
            }
        }
    }

    # ตัวนับเวลาและดีบัฟต่างๆ
    if ($Script:immortalTimer -gt 0) { $Script:immortalTimer-- }
    if ($Script:silenceTimer -gt 0) { $Script:silenceTimer-- }
    if ($collisionResult.ApplySilence) { $Script:silenceTimer = 180 }
    if ($collisionResult.ApplySiren) { $Script:sirenTimer = 180 }
    if ($Script:jammerTimer -gt 0) { $Script:jammerTimer-- }
    if ($collisionResult.ApplyJammer) { $Script:jammerTimer = 300 }
    
    if ($collisionResult.ApplyGreed) { 
        $Script:inventory.Clear() 
        Write-Host ">>> INVENTORY WIPED! <<<" -ForegroundColor Red 
    }
    
    # อัปเดตสถานะเกราะ บัฟ และความเร็ว
    if ($Script:defenseHits -gt 400) { $Script:defenseHits = 400 }
    if ($Script:defenseHits -lt 100) { $Script:gluttonyStage = 0 }
    if ($Script:wrathBuffTimer -gt 0) { 
        $Script:wrathBuffTimer--
        if($Script:wrathBuffTimer -le 0) { $Script:wrathBuffLevel = 0 } 
    }
    if ($Script:speedTimer -gt 0) { $Script:speedTimer-- }

    # ==========================================
    # 6. ตรวจสอบสถานะการตาย (Resurrection Logic)
    # ==========================================
    if ($collisionResult.IsPlayerHit) {
        $Script:lives--
        if ($Script:lives -le 0) { Do-GameOver; return $true }
        
        $Script:player.X = 225; $Script:player.Y = 500
        
        # --- [แก้ไขจุดนี้] เพิ่มเงื่อนไข Simulation ---
        $isChapter2 = $Script:gameMode -eq "Chapter2"
        $isSimMode = $Script:gameMode -eq "Simulation" # <--- เช็คโหมดแล็บ
        $isLuciferActive = ($Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" }).Count -gt 0
        $isRP = ($Script:enemies | Where-Object { $_.GetType().Name -eq "RealPride" }).Count -gt 0
        
        # ถ้าอยู่ในโหมดแล็บ, Chapter 2 หรือสู้บอสใหญ่ ให้ใช้กฎ "สู้ต่อ" ไม่ล้างสนาม
        if ($isSimMode -or $isChapter2 -or $isRP -or $isLuciferActive -or $collisionResult.IsFatalHit) {
            $Script:defenseHits = 50
            $Script:immortalTimer = 180 # อมตะ 3 วินาที
            Write-Host ">>> RESURRECTION: CONTINUING SIMULATION <<<" -ForegroundColor Cyan
        } else {
            # ตายปกติใน Chapter 1 หรือ Endless (ล้างสนามรบใหม่)
            $Script:enemies.Clear(); $Script:enemyBullets.Clear(); $Script:bullets.Clear(); $Script:items.Clear()
        }
    }
    return $false 
}