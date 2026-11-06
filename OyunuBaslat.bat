@echo off
setlocal
if not exist "%~dp0build\windows\SehirHayat.exe" (
  echo Oyun paketi bulunamadi. README.md icindeki export adimini uygulayin.
  pause
  exit /b 1
)
start "Sehir ve Hayat" /d "%~dp0build\windows" "%~dp0build\windows\SehirHayat.exe"
