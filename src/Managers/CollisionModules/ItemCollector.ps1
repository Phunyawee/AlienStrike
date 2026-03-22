# AlienStrike\src\CollisionModules\ItemCollector.ps1
function Invoke-ItemCollection ($player, $items) {
    for ($k = $items.Count - 1; $k -ge 0; $k--) {
        $it = $items[$k]
        if ($null -eq $it) { continue }

        if ($it.GetBounds().IntersectsWith($player.GetBounds())) {
            # ห้ามใช้ (if) ในวงเล็บ
            $Script:defenseHits += 5
            if ($Script:defenseHits -gt 400) { $Script:defenseHits = 400 }
            
            $items.RemoveAt($k)
            Write-Host ">>> ITEM COLLECTED: SHIELD REINFORCED <<<" -ForegroundColor Green
            continue
        }

        if ($it.Y -gt 650) { $items.RemoveAt($k) }
    }
}