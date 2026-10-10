@echo off

taskkill /IM vm.exe /F >nul 2>&1
taskkill /IM viewer.exe /F >nul 2>&1

echo ===== Compile mem =====
py tools\asm.py a program\program.asm program.mem
if errorlevel 1 (
    echo mem build FAILED
    pause
    exit /b 1
)

echo ===== Compile bin =====
py tools\asm.py b hello.asm hello.bin
if errorlevel 1 (
    echo bin build FAILED
    pause
    exit /b 1
)

echo ===== Building vm.exe =====
gcc vm.c -o vm.exe
if errorlevel 1 (
    echo vm.c build FAILED
    pause
    exit /b 1
)

echo ===== Building viewer.exe =====
gcc viewer.c -o viewer.exe -mwindows -lgdi32 -luser32
if errorlevel 1 (
    echo viewer.c build FAILED
    pause
    exit /b 1
)

echo ===== Build OK =====

echo Starting vm.exe in a new window...
start "vm" cmd /k vm.exe

timeout /t 2 /nobreak >nul

echo Starting viewer.exe ...
start "" viewer.exe

echo.
echo Both started. Type commands in the "vm" window.
timeout /t 3 /nobreak >nul