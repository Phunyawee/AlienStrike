# src/Managers/LogicModules/EntityManager.ps1

# ==========================================
# 1. FACTORY & INVENTORY: โรงงานผลิตและระบบคลังแสง
# ==========================================
function New-Sin ([string]$name, [float]$x = 210, [float]$y = -150) {
    # ปรับให้ตัดช่องว่างออกก่อนเทียบ Case
    switch ($name.Replace(" ", "").ToUpper()) { 
        "AZAZEL"     { return [Azazel]::new($x, $y, $Script:player) }
        "REALPRIDE"  { return [RealPride]::new($x, $y, $Script:player) }
        "WRATH"      { return [Wrath]::new($x, $y, 5) }
        "ENVY"       { return [Envy]::new($x, $y, $Script:player) }
           "WATCHER"    { return [Watcher]::new($x, $y, $x, 150.0, "Minion") }
        
        "MINION"     { return [Enemy]::new($x, $y, 3, [System.Drawing.Color]::Lime) }
        "PRIDE"      { return [Pride]::new($x, $y) }
        "LUST"       { return [Lust]::new($x, $y, 1) }
        "SLOTH"      { return [Sloth]::new($x, $y, $x, 150, 0) }
        "GREED"      { return [Greed]::new($x, $y, $Script:player) }
        "GLUTTONY"   { return [Gluttony]::new($x, $y, $Script:player) }
        "NEPHILIM"   { return [Nephilim]::new($x, $y, $Script:player) }
        "LUCIFER"    { return [Lucifer]::new($x, $y, $Script:player) }
        default      { return $null }
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
