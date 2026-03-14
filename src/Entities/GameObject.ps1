class GameObject {
    [float]$X; [float]$Y
    [int]$Width; [int]$Height
    [System.Drawing.Color]$Color
    [int]$FlashTimer = 0

    GameObject([float]$x, [float]$y, [int]$width, [int]$height, [System.Drawing.Color]$color) {
        $this.X = $x; $this.Y = $y
        $this.Width = $width; $this.Height = $height
        $this.Color = $color
    }

    # --- [NEW] ฟังก์ชันส่งคืนสีที่ควรวาด ณ เฟรมนั้น ---
    [System.Drawing.Color] GetFlashColor() {
        if ($this.FlashTimer -gt 0) {
            $this.FlashTimer--
            return [System.Drawing.Color]::White # ถ้าโดนยิง ให้ส่งสีขาวกลับไป
        }
        return $this.Color # ถ้าปกติ ส่งสีตัวเองกลับไป
    }

    # แก้ไข Draw มาตรฐานให้ใช้ GetFlashColor
    [void] Draw([System.Drawing.Graphics]$g) {
        $brush = New-Object System.Drawing.SolidBrush($this.GetFlashColor())
        $g.FillRectangle($brush, [float]$this.X, [float]$this.Y, [float]$this.Width, [float]$this.Height)
    }

    [System.Drawing.RectangleF] GetBounds() {
        return [System.Drawing.RectangleF]::new($this.X, $this.Y, $this.Width, $this.Height)
    }
}