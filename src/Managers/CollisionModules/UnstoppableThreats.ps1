# AlienStrike\src\CollisionModules\UnstoppableThreats.ps1
function Handle-UnstoppableThreats ($player, $enemyBullets, $context) {
    foreach ($eb in $enemyBullets) {
        if ($null -eq $eb) { continue }
        if ($eb.GetType().Name -eq "CataclysmWave") {
            if ($eb.GetBounds().IntersectsWith($player.GetBounds())) {
                $context.IsPlayerHit = $true
                $Script:lives = 0 # Fatal Error
                Write-Host "!!! CATACLYSM DETECTED: TERMINATING SESSION !!!" -ForegroundColor Red
            }
        }
    }

    $azazel = $Script:enemies | Where-Object { $_.GetType().Name -eq "Azazel" } | Select-Object -First 1
    if ($azazel -and $azazel.IsSweeping) {
        # สร้าง Rect สำหรับเลเซอร์ (ขนาดต้องตรงกับที่วาดใน Draw)
        $sweepRect = [System.Drawing.RectangleF]::new($azazel.SweepX, 0, 40, 600)
        
        if ($sweepRect.IntersectsWith($player.GetBounds())) {
            $context.IsPlayerHit = $true
            $Script:lives = 0 # Fatal Kill
            Write-Host "!!! EXTERMINATED BY JUDGMENT CANNON !!!" -ForegroundColor Red
            
            # แถม: ถ้าอยากให้ตายทันทีและข้ามระบบ I-frame (อมตะหลังโดน) 
            # อาจจะต้องสั่งจบเกมตรงนี้เลย หรือเรียกฟังก์ชัน GameOver
        }
    }
}