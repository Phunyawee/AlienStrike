# AlienStrike\src\GameLogic.ps1

# --- Function 1: คำนวณ Level และ SpawnRate จาก Score แบบสมการ ---
function Get-GameDifficulty ($currentScore) {
    # 1. คำนวณ Level ปัจจุบัน
    $calculatedLevel = [math]::Floor([math]::Sqrt($currentScore / 750)) + 1
    $lvl = [math]::Min($calculatedLevel, 999)
    $rate = [math]::Min((3 + [math]::Floor($lvl * 1.5)), 100)
    
    # 2. คำนวณคะแนนที่ต้องการสำหรับ "เลเวลถัดไป" (Target Score)
    # สมการย้อนกลับ: (Level)^2 * 750
    $nextLevelScore = [math]::Pow($lvl, 2) * 750

    # ส่งค่าเป้าหมายคะแนนกลับไปด้วย!
    return @{ 
        Level = $lvl; 
        SpawnRate = $rate; 
        NextLevelScore = $nextLevelScore 
    }
}

# --- Function 2: สร้างศัตรูที่รับรอง Level 1 - 999 ---
function New-EnemySpawn ($width, $level, $rnd) {
    $ex = $rnd.Next(0, ($width - 30))
    $ey = -40
    
    # 1. สมการความเร็ว (Speed)
    # เลเวลยิ่งสูง ความเร็วขั้นต่ำและขั้นสูงจะขยับขึ้นไปเรื่อยๆ
    $minSpeed = 2 + [math]::Floor($level / 2)
    $maxSpeed = $minSpeed + 3 + [math]::Floor($level / 10)
    
    # บังคับความเร็วสูงสุด ป้องกันบั๊ก "ศัตรูบินทะลุจอในเฟรมเดียว"
    $minSpeed = [math]::Min($minSpeed, 20)
    $maxSpeed = [math]::Min($maxSpeed, 25)
    
    $speed = $rnd.Next($minSpeed, $maxSpeed)
    
    # 2. ระบบสีวนลูป (Color Looping)
    # เก็บชุดสีไว้ใน Array
    $colorList = @(
        [System.Drawing.Color]::Red,     # สีตั้งต้น
        [System.Drawing.Color]::Orange,
        [System.Drawing.Color]::Purple,
        [System.Drawing.Color]::Cyan,
        [System.Drawing.Color]::Lime,
        [System.Drawing.Color]::Gold,
        [System.Drawing.Color]::Silver   # สีระดับสูง
    )
    
    # ใช้เครื่องหมาย % (Modulo - หารเอาเศษ) เพื่อให้สีวนลูปกลับมาเริ่มใหม่แบบ Infinity
    # ($level - 1) เพราะ Level เริ่มที่ 1 แต่ Array เริ่มที่ 0
    $colorIndex = ($level - 1) % $colorList.Count
    $enemyColor = $colorList[$colorIndex]
    
    # กิมมิคพิเศษ: ถ้าถึง Level 999 ให้ศัตรูเป็นสีดำ/สีพิเศษไปเลย
    if ($level -eq 999) {
        $enemyColor = [System.Drawing.Color]::DarkRed 
    }
    
    return [Enemy]::new($ex, $ey, $speed, $enemyColor)
}