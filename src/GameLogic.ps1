# AlienStrike\src\GameLogic.ps1

# --- Function 1: คำนวณ Level และ SpawnRate จาก Score ---
function Get-GameDifficulty ($currentScore) {
    # ค่า Default
    $lvl = 1
    $rate = 3
    
    if ($currentScore -ge 5000) {
        $lvl = 4
        $rate = 10
    } 
    elseif ($currentScore -ge 3000) {
        $lvl = 3
        $rate = 8
    } 
    elseif ($currentScore -ge 1000) {
        $lvl = 2
        $rate = 5
    }
    
    # ส่งค่ากลับเป็น Hashtable (จะได้ดึงใช้ง่ายๆ)
    return @{ Level = $lvl; SpawnRate = $rate }
}

# --- Function 2: สร้างศัตรูตามระดับ Level ---
function New-EnemySpawn ($width, $level, $rnd) {
    $ex = $rnd.Next(0, ($width - 30))
    $ey = -40
    
    if ($level -eq 1) {
        return [Enemy]::new($ex, $ey, $rnd.Next(3, 6), [System.Drawing.Color]::Red)
    } 
    elseif ($level -eq 2) {
        return [Enemy]::new($ex, $ey, $rnd.Next(5, 9), [System.Drawing.Color]::Orange)
    } 
    elseif ($level -eq 3) {
        return [Enemy]::new($ex, $ey, $rnd.Next(8, 12), [System.Drawing.Color]::Purple)
    } 
    else {
        # Level 4+: สีเงิน เร็วและโหด
        return [Enemy]::new($ex, $ey, $rnd.Next(9, 13), [System.Drawing.Color]::Silver)
    }
}