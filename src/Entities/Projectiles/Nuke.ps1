class Nuke : Bullet {
    [bool]$Exploded = $false
    Nuke([float]$x, [float]$y) : base($x, $y) {
        $this.Width = 20; $this.Height = 35; $this.Color = [System.Drawing.Color]::OrangeRed
        $this.Speed = 9
    }
    [void] Update() {
        if (-not $this.Exploded) {
            $this.Y -= $this.Speed
            # ระเบิดเมื่อถึงกลางสนามแนวแกน Y (ประมาณ 300)
            if ($this.Y -le 300) { $this.Exploded = $true }
        }
    }
    [void] Draw([System.Drawing.Graphics]$g) {
        $b = New-Object System.Drawing.SolidBrush($this.Color)
        if (-not $this.Exploded) {
            $g.FillRectangle($b, $this.X, $this.Y, $this.Width, $this.Height)
        } else {
            # วาดวงกลมระเบิดเล็กๆ แต่ดาเมจกระจายทั้งจอ (จัดการใน Manager)
            $g.FillEllipse($b, $this.X - 15, $this.Y - 15, 50, 50)
            $this.Y = -2000 # หายไปหลังระเบิด 1 เฟรม
        }
    }
}