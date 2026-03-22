# src/Managers/LogicModules/WorldEvents.ps1

function Check-ItemDrops {
    $lucifer = $Script:enemies | Where-Object { $_.GetType().Name -eq "Lucifer" } | Select-Object -First 1
    
    # เงื่อนไข: ต้องมี Lucifer และเลือดต้องต่ำกว่า 9000
    if ($lucifer -and $lucifer.HP -lt 9000) {
        $Script:itemDropTimer++
        if ($Script:itemDropTimer -ge 900) {
            $Script:itemDropTimer = 0
            $rx = $Script:rnd.Next(50, 450)
            if ($null -ne $Script:items) {
                [void]$Script:items.Add([DefenseDrop]::new($rx, -50))
                Write-Host ">>> EMERGENCY DEFENSE DROPPED! <<<" -ForegroundColor Cyan
            }
        }
    } else { $Script:itemDropTimer = 0 }
}
