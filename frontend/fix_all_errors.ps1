# VyapaarSaathi - Complete Fix Script
Write-Host "=== VyapaarSaathi Complete Fix ===" -ForegroundColor Cyan
Write-Host ""

Set-Location "C:\Users\Heman\Downloads\vyapaarsaathi\frontend"

Write-Host "[1/3] Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "[2/3] Running analysis..." -ForegroundColor Yellow
flutter analyze

Write-Host ""
Write-Host "[3/3] Building APK..." -ForegroundColor Yellow
flutter build apk --debug

Write-Host ""
Write-Host "=== Complete! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check errors above. If you see errors, fix them manually." -ForegroundColor Yellow
Write-Host ""
Write-Host "Manual fixes needed:" -ForegroundColor Yellow
Write-Host "  1. Add 'intl: ^0.19.0' to pubspec.yaml" -ForegroundColor White
Write-Host "  2. Fix voice_provider.dart (3 errors)" -ForegroundColor White
Write-Host "  3. Fix transaction_tile.dart (3 errors)" -ForegroundColor White
Write-Host ""
Write-Host "See MANUAL_FIX_GUIDE.md for detailed instructions." -ForegroundColor White