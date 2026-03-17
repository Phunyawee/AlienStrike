# src/Managers/LogicModules/EntityManager.ps1

# ==========================================
# 1. FACTORY & INVENTORY: โรงงานผลิตและระบบคลังแสง
# ==========================================
function New-Sin ([string]$name, [float]$x = 210, [float]$y = -150) {
    switch ($name) {
        "Wrath"    { return [Wrath]::new($x, $y, 5) }
        "Envy"     { return [Envy]::new($x, $y, $Script:player) }
        "Pride"    { return [Pride]::new($x, $y) }
        "Lust"     { return [Lust]::new($x, $y, 1) }
        "Sloth"    { return [Sloth]::new($x, $y, $x, 150, 0) }
        "Greed"    { return [Greed]::new($x, $y, $Script:player) }
        "Gluttony" { return [Gluttony]::new($x, $y, $Script:player) }
        "RealPride"{ return [RealPride]::new($x, $y, $Script:player) }
        "Lucifer"  { return [Lucifer]::new($x, $y, $Script:player) }
        default    { return $null }
    }
}

function New-EnemySpawn ($width, $level, $rnd) {
    $ex = $rnd.Next(0, ($width - 40))
    if ($rnd.Next(1, 101) -le 8) {
        return [Wrath]::new($ex, -40, [math]::Min(([math]::Floor($level / 200) + 1), 5))
    }
    $minS = [math]::Min((2 + [math]::Floor($level / 2)), 15)
    $speed = $rnd.Next($minS, ($minS + 5))
    $colors = @([System.Drawing.Color]::Red, [System.Drawing.Color]::Orange, [System.Drawing.Color]::Purple, [System.Drawing.Color]::Cyan, [System.Drawing.Color]::Lime, [System.Drawing.Color]::Gold)
    return [Enemy]::new($ex, -40, $speed, $colors[($level - 1) % $colors.Count])
}

function Get-GameDifficulty ($currentScore) {
    $calculatedLevel = [math]::Floor([math]::Sqrt($currentScore / 750)) + 1
    $lvl = [math]::Min($calculatedLevel, 999)
    $rate = [math]::Min((2 + ($lvl * 0.5)), 15) 
    return @{ Level = $lvl; SpawnRate = $rate; NextLevelScore = ([math]::Pow($lvl, 2) * 750) }
}
