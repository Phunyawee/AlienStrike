@echo off
cd /d "%~dp0"
:: รัน PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "AlienStrike.ps1"

:: ใส่ pause ไว้บรรทัดสุดท้าย เพื่อค้างหน้าจอไว้ดู Error
echo.
echo Press any key to exit...
pause