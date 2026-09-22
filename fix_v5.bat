@echo off
powershell -Command "$file = 'frontend/lib/screens/dashboard/heatmap_screen.dart'; if (Test-Path $file) { (Get-Content $file) -replace 'Colors.emerald', 'Colors.green' | Set-Content $file; Write-Host Fixed $file }"
