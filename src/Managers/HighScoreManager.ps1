# AlienStrike\src\HighScoreManager.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scoreFile = Join-Path (Split-Path $PSScriptRoot -Parent) "scores.json"

function Get-HighScores {
    if (Test-Path $scoreFile) {
        try {
            $json = Get-Content $scoreFile -Raw -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace($json)) { return @() }
            
            # อ่านข้อมูลดิบมาก่อน
            $raw = @($json | ConvertFrom-Json)
            
            # --- ขั้นตอนการซ่อมไฟล์ (Flatten) ---
            # สร้าง List ว่างๆ เพื่อรอรับข้อมูลที่ "สะอาด"
            $cleanList = [System.Collections.ArrayList]::new()
            
            foreach ($item in $raw) {
                # เช็คว่าใช่ตัวบั๊กที่มี "value" กับ "Count" หรือไม่
                if ($item.PSObject.Properties.Name -contains "value" -and $item.value -is [Array]) {
                    # ถ้าใช่ ให้เจาะเอาไส้ใน (value) ออกมาใส่แทน
                    foreach ($innerItem in $item.value) {
                        [void]$cleanList.Add($innerItem)
                    }
                } else {
                    # ถ้าปกติ ก็ใส่เข้าไปเลย
                    [void]$cleanList.Add($item)
                }
            }
            return $cleanList
        }
        catch {
            return @()
        }
    }
    return @()
}

function Save-Score ($name, $score, $lvl) {
    # 1. โหลดคะแนนเก่ามา (ซึ่งผ่านการซ่อมจากฟังก์ชัน Get-HighScores แล้ว)
    $scoreList = [System.Collections.ArrayList]::new()
    $oldScores = Get-HighScores
    if ($oldScores) {
        $scoreList.AddRange($oldScores)
    }

    # 2. สร้างคะแนนใหม่
    $newEntry = [PSCustomObject]@{
        Name  = "$name"
        Score = [int]$score
        Level = [int]$lvl
        Date  = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    }

    # 3. เพิ่มลงไปใน List
    [void]$scoreList.Add($newEntry)

    # 4. เรียงและบันทึก (ConvertTo-Json จะไม่เพี้ยนถ้ามาจาก ArrayList ที่ไส้ในเป็น Object ปกติ)
    $scoreList | 
        Sort-Object Score -Descending | 
        Select-Object -First 10 | 
        ConvertTo-Json -Depth 5 | 
        Out-File $scoreFile -Encoding UTF8
}

function Show-NameInputBox ($score) {
    $inputForm = New-Object System.Windows.Forms.Form
    $inputForm.Text = "NEW HIGH SCORE!"
    $inputForm.Size = New-Object System.Drawing.Size(300, 180)
    $inputForm.StartPosition = "CenterScreen"
    $inputForm.BackColor = "Black"
    $inputForm.FormBorderStyle = "FixedToolWindow"

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "SCORE: $score`nEnter Your Name:"
    $lbl.ForeColor = "Yellow"
    $lbl.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point(20, 20)
    $inputForm.Controls.Add($lbl)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(20, 70)
    $txt.Size = New-Object System.Drawing.Size(240, 30)
    $txt.Font = New-Object System.Drawing.Font("Arial", 12)
    $inputForm.Controls.Add($txt)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "SAVE"
    $btn.DialogResult = "OK"
    $btn.BackColor = "Green"
    $btn.ForeColor = "White"
    $btn.FlatStyle = "Flat"
    $btn.Location = New-Object System.Drawing.Point(180, 110)
    $inputForm.Controls.Add($btn)
    
    $inputForm.AcceptButton = $btn
    
    $result = $inputForm.ShowDialog()
    if ($result -eq "OK" -and $txt.Text.Trim() -ne "") {
        return $txt.Text.Trim()
    }
    return "Unknown"
}