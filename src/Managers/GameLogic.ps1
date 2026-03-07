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

# --- Function 2: สร้างศัตรู (รวมระบบ Mini-Boss: Wrath) ---
function New-EnemySpawn ($width, $level, $rnd) {
    # เผื่อความกว้างไว้ 40 เพราะ Wrath ตัวกว้าง 40 (กันเกิดแล้วทะลุขอบจอ)
    $ex = $rnd.Next(0, ($width - 40))
    $ey = -40
    
    # ==========================================
    # 1. ระบบสุ่มเกิด Mini-Boss (บาป Wrath)
    # ==========================================
    # ให้มีโอกาส 8% ที่ศัตรูตัวนี้จะกลายเป็น Wrath (ปรับเลข 8 ได้ตามความโหดที่ต้องการ)
    $spawnChance = $rnd.Next(1, 101) 
    
    if ($spawnChance -le 8) {
        
        # คำนวณความโกรธ (Sin Level) เก่งขึ้นทุกๆ 200 เลเวล
        # เลเวล 1-199 จะได้ 0+1 = 1 | เลเวล 200-399 จะได้ 1+1 = 2
        $sinLevel =[math]::Floor($level / 200) + 1
        
        # บังคับไม่ให้ความโกรธเกินระดับ 5
        $sinLevel = [math]::Min($sinLevel, 5)
        
        # ส่ง Wrath ออกไปเกิดแทนศัตรูธรรมดา!
        return [Wrath]::new($ex, $ey, $sinLevel)
    }

    # if ($spawnChance -le 100) { 
        
    #     # ล็อกให้เป็นเลเวล 5 (โหดสุด) ไปเลย
    #     $sinLevel = 5
        
    #     return [Wrath]::new($ex, $ey, $sinLevel)
    # }

    # ==========================================
    # 2. ถ้ายกเว้นด้านบน (92%) ให้เกิดศัตรูธรรมดา
    # ==========================================
    $minSpeed = 2 + [math]::Floor($level / 2)
    $maxSpeed = $minSpeed + 3 + [math]::Floor($level / 10)
    
    # บังคับความเร็วสูงสุด ป้องกันบั๊ก
    $minSpeed = [math]::Min($minSpeed, 20)
    $maxSpeed = [math]::Min($maxSpeed, 25)
    
    $speed = $rnd.Next($minSpeed, $maxSpeed)
    
    # ระบบสีวนลูป
    $colorList = @(
        [System.Drawing.Color]::Red,     
        [System.Drawing.Color]::Orange,
        [System.Drawing.Color]::Purple,
        [System.Drawing.Color]::Cyan,
        [System.Drawing.Color]::Lime,[System.Drawing.Color]::Gold,
        [System.Drawing.Color]::Silver   
    )
    
    $colorIndex = ($level - 1) % $colorList.Count
    $enemyColor = $colorList[$colorIndex]
    
    if ($level -ge 999) {
        $enemyColor = [System.Drawing.Color]::DarkRed 
    }
    
    return [Enemy]::new($ex, $ey, $speed, $enemyColor)
}