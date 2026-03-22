# \src\CollisionModules\ExplosionProcessor.ps1

function Invoke-GlobalNuke ($bullets, $enemies, $context) {
    $activeNuke = $bullets | Where-Object { $_.GetType().Name -eq "Nuke" -and $_.Exploded } | Select-Object -First 1
    if ($null -ne $activeNuke) {
        $context.ShakeIntensity = 15
        Write-Host ">>> NUKE RADIUS DETECTED: ANNIHILATING FIELD <<<" -ForegroundColor Red
        
        for ($i = $enemies.Count - 1; $i -ge 0; $i--) {
            if ($i -ge $enemies.Count) { continue }
            $e = $enemies[$i]; $eName = $e.GetType().Name; $nukeDead = $false
            
            if ($eName -eq "Lucifer") {
                foreach ($part in $e.Parts) {
                    if (-not $part.IsDestroyed -and $part.TakeDamage(200)) {
                        if ($part.Type -eq "Cannon") { $e.HP -= 4000 } else { $e.HP -= 1000 }
                    }
                }
                # Nuke ตีทะลุเกราะเข้า Core
                $dmg = 5
                if ($e.Phase -ge 2) { $dmg = 400 }
                $nukeDead = $e.TakeDamage($dmg)
            }
            elseif ($eName -eq "RealPride") { $nukeDead = $e.TakeDamage(200) }
            elseif ($eName -eq "Nephilim") { $nukeDead = $e.TakeDamage(200) }
            elseif ($eName -eq "Gluttony")  { $nukeDead = $e.TakeDamage(50) }
            else { 
                if ($e -is [BaseEnemy]) { $nukeDead = $e.TakeDamage(99) } else { $nukeDead = $true }
            }

            if ($nukeDead) {
                if ($null -ne $e.ScoreValue) { $context.ScoreAdded += $e.ScoreValue } else { $context.ScoreAdded += 100 }
                
                # เก็บยอดคิลส่ง Director
                if ($eName -eq "Gluttony") { $context.GluttonyKills += 1 }
                elseif ($eName -eq "RealPride") { $context.RealPrideKilled = $true }
                elseif ($eName -eq "Lucifer") { $context.LuciferKilled = $true }
                elseif ($eName -eq "Lust") { $context.LustKills += 1 }
                elseif ($eName -eq "Greed") { $context.GreedKills += 1 }
                elseif ($eName -eq "Sloth") { $context.SlothKills += 1 }
                elseif ($eName -eq "Wrath") { $context.WrathKills += 1 }

                $enemies.RemoveAt($i)
            }
        }
    }
}