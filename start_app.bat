@echo off
echo ========================================
echo Starting VyapaarSaathi App
echo ========================================

echo.
echo [1/2] Starting Backend Server...
start "Backend" cmd /k "cd C:\Users\Heman\Downloads\vyapaarsaathi\backend && venv\Scripts\activate && python main.py"

timeout /t 3 /nobreak >nul

echo [2/2] Starting Frontend App...
start "Frontend" cmd /k "cd C:\Users\Heman\Downloads\vyapaarsaathi\frontend && flutter run"

echo.
echo Both servers are starting!
echo Close these windows when done.
pause