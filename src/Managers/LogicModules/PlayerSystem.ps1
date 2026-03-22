# src/Managers/LogicModules/PlayerSystem.ps1

# ==========================================
# 4. UTILS: เครื่องมือเสริม
# ==========================================

function Add-To-Inventory ($itemType, [int]$amount = 1) {
    for ($k = 0; $k -lt $amount; $k++) {
        $lastIdx = -1
        for ($i = 0; $i -lt $Script:inventory.Count; $i++) {
            if ($Script:inventory[$i] -eq $itemType) { $lastIdx = $i }
        }
        if ($lastIdx -ne -1) { $Script:inventory.Insert($lastIdx + 1, $itemType) }
        else { [void]$Script:inventory.Add($itemType) }
    }
}

function Handle-PlayerInput {
    if ($Script:sirenTimer -gt 0) { $Script:sirenTimer-- }
    if ($Script:speedTimer -gt 0) { $Script:speedTimer-- }
    $moveL = ($Script:keysPressed["A"] -or $Script:keysPressed["Left"])
    $moveR = ($Script:keysPressed["D"] -or $Script:keysPressed["Right"])
    $speed = if ($Script:speedTimer -gt 0) { 16 } else { 8 }
    $dir = 0
    if ($moveL) { $dir = -1 } elseif ($moveR) { $dir = 1 }
    if ($Script:sirenTimer -gt 0) { $dir *= -1 }
    if ($dir -ne 0) { $Script:player.Move($dir * $speed) }
    if ($Script:keysPressed["W"] -or $Script:keysPressed["Space"] -or $Script:keysPressed["Up"]) {
        if ($Script:silenceTimer -le 0 -and $Script:player.CanShoot()) {
            $px = $Script:player.X; $py = $Script:player.Y
            if ($Script:wrathBuffLevel -eq 2) {
                [void]$Script:bullets.Add([Bullet]::new($px+4,$py,0)); [void]$Script:bullets.Add([Bullet]::new($px+20,$py,0))   
                [void]$Script:bullets.Add([Bullet]::new($px-4,$py,-4)); [void]$Script:bullets.Add([Bullet]::new($px+28,$py,4))   
            } elseif ($Script:wrathBuffLevel -eq 1) {
                [void]$Script:bullets.Add([Bullet]::new($px+4,$py,0)); [void]$Script:bullets.Add([Bullet]::new($px+20,$py,0))
            } else { [void]$Script:bullets.Add([Bullet]::new($px+7,$py)) }
            $Script:player.ResetCooldown()
        }
    }
    $Script:player.Update()
}

function Get-UIStatus {
    $buffs = @(); $debuffs = @()
    
    # 1. Wrath Buff (W)
    if ($Script:wrathBuffLevel -eq 2) { 
        $buffs += [PSCustomObject]@{ Icon="W"; Value="{0:N1}s" -f ($Script:wrathBuffTimer/60.0); Color=[System.Drawing.Brushes]::Red } 
    } elseif ($Script:wrathStackCount -gt 0) { 
        $buffs += [PSCustomObject]@{ Icon="W"; Value="$($Script:wrathStackCount)/3"; Color=[System.Drawing.Brushes]::DeepSkyBlue } 
    }
    


    # 2. Debuffs (Z, S, J, I)
    if ($Script:silenceTimer -gt 0) { $debuffs += [PSCustomObject]@{ Icon="Z"; Value="{0:N1}s" -f ($Script:silenceTimer/60.0); Color=[System.Drawing.Brushes]::Magenta } }
    if ($Script:sirenTimer -gt 0) { $debuffs += [PSCustomObject]@{ Icon="S"; Value="{0:N1}s" -f ($Script:sirenTimer/60.0); Color=[System.Drawing.Brushes]::DeepPink } }
    if ($Script:jammerTimer -gt 0) { $debuffs += [PSCustomObject]@{ Icon="J"; Value="{0:N1}s" -f ($Script:jammerTimer/60.0); Color=[System.Drawing.Brushes]::Yellow } }
    if ($Script:speedTimer -gt 0) { $buffs += [PSCustomObject]@{ Icon="S"; Value="{0:N1}s" -f ($Script:speedTimer/60.0); Color=[System.Drawing.Brushes]::SkyBlue } }
    if ($Script:defenseHits -gt 0) { $buffs += [PSCustomObject]@{ Icon="D"; Value="x$Script:defenseHits"; Color=[System.Drawing.Brushes]::Gold } }
    if ($Script:immortalTimer -gt 0) { $debuffs += [PSCustomObject]@{ Icon="I"; Value="{0:N1}s" -f ($Script:immortalTimer/60.0); Color=[System.Drawing.Brushes]::White } }

    return @{ Buffs = $buffs; Debuffs = $debuffs }
}