class LuciferPart {
    [float]$RelX; [float]$RelY
    [int]$HP; [int]$MaxHP
    [int]$Width; [int]$Height
    [string]$Type # "Cannon" (Laser), "Turret" (Small Gun)
    [bool]$IsDestroyed = $false
    [int]$FlashTimer = 0 # <--- [เพิ่ม] บรรทัดนี้

    LuciferPart([float]$rx, [float]$ry, [int]$hp, [int]$w, [int]$h, [string]$type) {
        $this.RelX = $rx; $this.RelY = $ry
        $this.HP = $hp; $this.MaxHP = $hp
        $this.Width = $w; $this.Height = $h
        $this.Type = $type
    }

    [bool] TakeDamage([int]$dmg) {
        if ($this.IsDestroyed) { return $false }
        $this.HP -= $dmg
        $this.FlashTimer = 3 # <--- [เพิ่ม] กะพริบ 3 เฟรมเมื่อโดนยิง
        if ($this.HP -le 0) { $this.IsDestroyed = $true; return $true }
        return $false
    }

    [System.Drawing.RectangleF] GetBounds([float]$parentX, [float]$parentY) {
        return [System.Drawing.RectangleF]::new($parentX + $this.RelX, $parentY + $this.RelY, $this.Width, $this.Height)
    }
}