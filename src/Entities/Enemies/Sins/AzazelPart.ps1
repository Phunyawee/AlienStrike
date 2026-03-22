# src/Entities/Enemies/Sins/AzazelPart.ps1
class AzazelPart {
    [float]$RelX; [float]$RelY; [int]$HP; [int]$MaxHP; [int]$Width; [int]$Height
    [string]$Type; [bool]$IsDestroyed = $false
    [int]$FlashTimer = 0

    AzazelPart([float]$rx, [float]$ry, [int]$hp, [int]$w, [int]$h, [string]$type) {
        $this.RelX = $rx; $this.RelY = $ry; $this.HP = $hp; $this.MaxHP = $hp
        $this.Width = $w; $this.Height = $h; $this.Type = $type
    }

    [bool] TakeDamage([int]$dmg, [string]$weaponType) {
        if ($this.IsDestroyed) { return $false }
        # กฎ: ปืนกันอาวุธหนัก (ยกเว้น Nuke)
        if ($weaponType -match "Missile|HomingMissile|HolyBomb") { return $false }
        
        $this.HP -= $dmg
        $this.FlashTimer = 5 # กะพริบนานขึ้นนิดนึงให้เห็นชัด
        if ($this.HP -le 0) { $this.IsDestroyed = $true; return $true }
        return $false
    }

    [System.Drawing.RectangleF] GetBounds([float]$px, [float]$py) {
        # คำนวณพิกัดสัมบูรณ์บนจอ: พิกัดแม่ + พิกัดสัมพัทธ์
        return [System.Drawing.RectangleF]::new(($px + $this.RelX), ($py + $this.RelY), $this.Width, $this.Height)
    }
}