class SilenceBullet : EnemyBullet {
    hidden [Object]$Target
    [bool]$IsTracking

    # รับค่าตำแหน่งเริ่มต้น และรับ Object ของ Player มาเพื่อล็อกเป้า
    SilenceBullet([float]$x, [float]$y, [Object]$player) : base($x, $y, 0, 2) {
        $this.Color = [System.Drawing.Color]::Magenta # กระสุนสีม่วง/ชมพู
        $this.Width = 8
        $this.Height = 8
        $this.Target = $player
        $this.IsTracking = $true
    }

    [void] Update() {
        if ($this.IsTracking -and $null -ne $this.Target) {
            # 1. หาจุดศูนย์กลางของกระสุนและผู้เล่น
            $bx = $this.X + ($this.Width / 2)
            $by = $this.Y + ($this.Height / 2)
            $px = $this.Target.X + ($this.Target.Width / 2)
            $py = $this.Target.Y + ($this.Target.Height / 2)

            # 2. คำนวณระยะห่าง (Distance)
            $dx = $px - $bx
            $dy = $py - $by
            $dist =[math]::Sqrt($dx * $dx + $dy * $dy)

            # 3. เมคานิก "ห่าง 10 หน่วยเลิกตาม" 
            # (หมายเหตุ: ในเกม 1 หน่วยมักเล็กมาก ผมเลยคูณด้วย 8 เป็นระยะ 80 Pixels นะครับ ผู้เล่นจะได้มีระยะดึงหลบได้จริง)
            if ($dist -le 80) {
                $this.IsTracking = $false # เลิกนำวิถี! กระสุนจะพุ่งตรงไปตามแรงเฉื่อยเดิม
            } else {
                # 4. พุ่งหาผู้เล่น (ความเร็วช้าๆ = 3)
                $speed = 3
                $this.SpeedX = ($dx / $dist) * $speed
                $this.SpeedY = ($dy / $dist) * $speed
            }
        }
        
        # Correct way to call parent method in PowerShell
        ([EnemyBullet]$this).Update()
    }
}