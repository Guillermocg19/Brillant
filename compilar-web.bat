@echo off
setlocal EnableExtensions
title Brillant - Compilar juego web

rem ------------------------------------------------------------
rem  Compila la version web del juego en build\web.
rem  El servidor (iniciar-servidor.bat) la publica en http://IP:3000
rem  para jugar desde el navegador del telefono.
rem  Vuelve a ejecutarlo cada vez que cambies el codigo del juego.
rem ------------------------------------------------------------

cd /d "%~dp0"
if not exist pubspec.yaml (
  echo [ERROR] No encuentro pubspec.yaml junto a este archivo.
  if /i not "%~1"=="nopause" pause
  exit /b 1
)
where flutter >nul 2>nul
if errorlevel 1 (
  rem Ruta que guardo conectar.bat la ultima vez que encontro Flutter.
  if exist "%~dp0.ruta-flutter.txt" (
    set /p FLUTTER_BIN=<"%~dp0.ruta-flutter.txt"
  )
)
if defined FLUTTER_BIN set "PATH=%FLUTTER_BIN%;%PATH%"
where flutter >nul 2>nul
if errorlevel 1 (
  echo Abre conectar.bat una vez para indicar donde esta Flutter.
  echo [ERROR] Flutter no esta instalado o no esta en el PATH.
  echo Sin Flutter no se puede compilar el juego web.
  if /i not "%~1"=="nopause" pause
  exit /b 1
)

echo Compilando el juego web (tarda unos minutos)...
rem --no-web-resources-cdn: incluye CanvasKit en build\web para que funcione
rem aunque la red local no tenga internet. Sin API_URL: el juego usa como
rem servidor la misma direccion desde la que se abrio la pagina.
call flutter build web --release --no-web-resources-cdn
if errorlevel 1 (
  echo Reintentando sin --no-web-resources-cdn ^(Flutter antiguo^)...
  call flutter build web --release
)
if errorlevel 1 (
  echo [ERROR] No se pudo compilar el juego web.
  if /i not "%~1"=="nopause" pause
  exit /b 1
)
echo Juego web listo en build\web.
if /i not "%~1"=="nopause" pause
exit /b 0
