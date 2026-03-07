# src/Entities/Enemies/BaseEnemy.ps1

class BaseEnemy : GameObject {
    [int]$Speed
    [int]$HP
    [int]$MaxHP
    [int]$Ammo
    [int]$ScoreValue

    hidden [System.Random]$Rnd

    # Constructor ที่เปิดกว้างให้ 7 บาป ส่งค่าเฉพาะตัวมาได้
    BaseEnemy([float]$x, [float]$y, [int]$width, [int]$height, [int]$speed, [int]$hp, [System.Drawing.Color]$color) 
        : base($x, $y, $width, $height, $color) {
        
        $this.Speed = $speed
        $this.HP = $hp
        $this.MaxHP = $hp
        $this.Ammo = 2 # ค่าเริ่มต้น ให้ Sins ไปเขียนทับ (Override) ได้
        $this.ScoreValue = 100 # <--- 2. ตั้งค่าหัวมาตรฐานไว้ที่ 100 คะแนน
        $this.Rnd = [System.Random]::new()
    }

    # 1. การเคลื่อนที่พื้นฐาน (ลงล่างอย่างเดียว)
    # *Sins สามารถ Override ฟังก์ชันนี้เพื่อทำท่าเดินแปลกๆ ได้
    [void] Update() {
        $this.Y += $this.Speed
    }

    # 2. ระบบรับดาเมจ (คืนค่า $true ถ้าเลือดหมด/ตาย)
    [bool] TakeDamage([int]$damageAmount) {
        $this.HP -= $damageAmount
        return ($this.HP -le 0)
    }

    # 3. ฟังก์ชันลองยิงกระสุน (ใช้โค้ดเดิมของคุณ แต่ปรับจุดเกิดกระสุนให้เป๊ะขึ้น)
    [Object] TryShoot([int]$currentLevel) {
        if ($currentLevel -ge 4 -and $this.Ammo -gt 0) {
            
            if ($this.Rnd.Next(0, 100) -lt 2) { 
                $this.Ammo--
                
                # คำนวณให้กระสุนออกตรงกลางตัวศัตรูพอดี (เผื่อศัตรูตัวใหญ่ขึ้น)
                $bulletX = $this.X + ($this.Width / 2) - 4 
                $bulletY = $this.Y + $this.Height
                
                return [EnemyBullet]::new($bulletX, $bulletY)
            }
        }
        return $null
    }

    # 4. อัปเกรดการวาด! ให้ BaseEnemy วาดหลอดเลือดตัวเองได้ด้วย
    [void] Draw([System.Drawing.Graphics]$g) {
        
        # แก้ตรงนี้! เรียกใช้ Draw ของ GameObject ด้วยวิธีของ PowerShell
        ([GameObject]$this).Draw($g) 

        # กิมมิค: ถ้าเลือดไม่เต็ม ให้โชว์หลอดเลือดเล็กๆ บนหัว
        if ($this.HP -lt $this.MaxHP -and $this.HP -gt 0) {
            $healthPercent = $this.HP / $this.MaxHP
            $barWidth = $this.Width * $healthPercent
            
            $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::DarkRed)
            $hpBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Lime)
            
            # วาดพื้นหลังหลอดเลือด (สีแดง)
            $g.FillRectangle($bgBrush, $this.X, ($this.Y - 6), $this.Width, 3)
            # วาดเลือดที่เหลือ (สีเขียว)
            $g.FillRectangle($hpBrush, $this.X, ($this.Y - 6), $barWidth, 3)
        }
    }
}