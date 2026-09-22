@echo off
set PATH=%PATH%;C:\Program Files\nodejs;C:\Users\Heman\flutter\bin;C:\Program Files\Git\cmd

echo [1/3] Starting web server in background...
start /b npx -y http-server frontend/build/web -p 8080

echo [2/3] Waiting for server to start...
timeout /t 15 /nobreak

echo [3/3] Running Playwright tests...
cd frontend/test/playwright
call npx playwright test vyapaarsaathi.spec.js --project=chromium

echo Done.
