@echo off
setlocal EnableExtensions
title Brillant - Servidor

rem ------------------------------------------------------------
rem  Arranca el servidor de Brillant.
rem  Coloca este archivo en la RAIZ del repositorio (junto a la carpeta "servidor").
rem  Si tu archivo principal no se llama index.js / server.js / app.js / main.js,
rem  escribe su nombre aqui:
rem ------------------------------------------------------------
set "ARCHIVO=servidor.js"

if not exist "%~dp0servidor\" (
  echo [ERROR] No encuentro la carpeta "servidor" junto a este archivo.
  echo Estoy buscando en: %~dp0
  echo Mueve este .bat a la carpeta que contiene "servidor" y "pubspec.yaml".
  pause
  exit /b 1
)
cd /d "%~dp0servidor"

rem ---- Node.js ----
where node >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Node.js no esta instalado.
  echo Descargalo en https://nodejs.org ^(version 20 o superior^) y abre este archivo de nuevo.
  pause
  exit /b 1
)
node -e "process.exit(parseInt(process.versions.node)>=20?0:1)"
if errorlevel 1 (
  echo [ERROR] Necesitas Node.js 20 o superior. Tu version:
  node -v
  pause
  exit /b 1
)

rem ---- Archivo principal ----
for %%F in (index.js server.js app.js main.js) do if not defined ARCHIVO if exist "%%F" set "ARCHIVO=%%F"
if not defined ARCHIVO (
  echo [ERROR] No encontre el archivo principal del servidor en la carpeta "servidor".
  echo Edita este .bat y escribe su nombre en la linea:  set "ARCHIVO="
  pause
  exit /b 1
)

rem ---- Dependencias ----
if not exist node_modules (
  echo Instalando dependencias, solo la primera vez...
  call npm install
  if errorlevel 1 (
    echo [ERROR] Fallo "npm install".
    pause
    exit /b 1
  )
)

rem ---- Archivo .env con un secreto nuevo para ESTE equipo ----
if not exist .env (
  echo Creando .env con un secreto nuevo para este equipo...
  node -e "require('fs').writeFileSync('.env','JWT_SECRET='+require('crypto').randomBytes(32).toString('hex')+'\nPORT=3000\n')"
)

set "PUERTO=3000"
for /f "tokens=1,* delims==" %%A in ('findstr /b "PORT=" .env') do set "PUERTO=%%B"

rem ---- Firewall de Windows (necesita administrador solo la primera vez) ----
netsh advfirewall firewall show rule name="Brillant servidor" >nul 2>nul
if errorlevel 1 (
  netsh advfirewall firewall add rule name="Brillant servidor" dir=in action=allow protocol=TCP localport=%PUERTO% >nul 2>nul
  if errorlevel 1 (
    echo.
    echo [AVISO] No pude abrir el puerto %PUERTO% en el firewall: falta ejecutar como administrador.
    echo Si otros equipos no logran conectarse, cierra esto y abre el .bat con
    echo clic derecho - Ejecutar como administrador.
  ) else (
    echo Puerto %PUERTO% abierto en el firewall.
  )
)

echo.
echo ============================================================
echo  SERVIDOR BRILLANT
echo  En este equipo:   http://localhost:%PUERTO%
echo  Desde otros equipos de tu red usa una de estas direcciones:
for /f "tokens=2 delims=:" %%I in ('ipconfig ^| findstr /i "IPv4"') do (
  for /f "tokens=*" %%J in ("%%I") do echo      http://%%J:%PUERTO%
)
echo.
echo  Para detenerlo: Ctrl+C
echo ============================================================
echo.

node --env-file=.env %ARCHIVO%

echo.
echo El servidor se detuvo.
pause
