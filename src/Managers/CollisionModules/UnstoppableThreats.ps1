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
}