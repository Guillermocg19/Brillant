<<<<<<< HEAD
@echo off
setlocal EnableExtensions
title Brillant - Servidor

rem ------------------------------------------------------------
rem  Arranca el servidor de Brillant.
rem  Coloca este archivo en la RAIZ del repositorio (junto a la carpeta "servidor").
rem  Si tu archivo principal no se llama servidor.js / index.js / server.js / app.js / main.js,
rem  escribe su nombre aqui:
rem ------------------------------------------------------------
set "ARCHIVO="

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
for %%F in (servidor.js index.js server.js app.js main.js) do if not defined ARCHIVO if exist "%%F" set "ARCHIVO=%%F"
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

rem ---- Firewall de Windows (necesita administrador) ----
rem Las redes creadas (hotspot) Windows las marca como "publicas". Si alguna vez
rem se respondio "Cancelar" al aviso del firewall, Windows crea reglas que
rem BLOQUEAN node.exe en redes publicas, y un bloqueo gana a cualquier permiso.
net session >nul 2>nul
if errorlevel 1 (
  echo.
  echo [AVISO] Sin permisos de administrador no puedo revisar el firewall.
  echo Si otros equipos no logran conectarse, cierra esto y abre el .bat con
  echo clic derecho - Ejecutar como administrador.
  goto finFirewall
)
powershell -NoProfile -Command "Get-NetFirewallApplicationFilter -Program '*node.exe' -ErrorAction SilentlyContinue | Get-NetFirewallRule | Where-Object Action -eq Block | Remove-NetFirewallRule" >nul 2>nul
netsh advfirewall firewall delete rule name="Brillant servidor" >nul 2>nul
netsh advfirewall firewall add rule name="Brillant servidor" dir=in action=allow protocol=TCP localport=%PUERTO% profile=any >nul 2>nul
if errorlevel 1 (
  echo [AVISO] No pude abrir el puerto %PUERTO% en el firewall.
) else (
  echo Firewall listo: puerto %PUERTO% abierto en redes privadas y publicas.
)
:finFirewall

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
=======
@echo off
setlocal EnableExtensions
title Brillant - Servidor

rem ------------------------------------------------------------
rem  Arranca el servidor de Brillant.
rem  Coloca este archivo en la RAIZ del repositorio (junto a la carpeta "servidor").
rem  Si tu archivo principal no se llama servidor.js / index.js / server.js / app.js / main.js,
rem  escribe su nombre aqui:
rem ------------------------------------------------------------
set "ARCHIVO="

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
for %%F in (servidor.js index.js server.js app.js main.js) do if not defined ARCHIVO if exist "%%F" set "ARCHIVO=%%F"
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

rem ---- Firewall de Windows (necesita administrador) ----
rem Las redes creadas (hotspot) Windows las marca como "publicas". Si alguna vez
rem se respondio "Cancelar" al aviso del firewall, Windows crea reglas que
rem BLOQUEAN node.exe en redes publicas, y un bloqueo gana a cualquier permiso.
net session >nul 2>nul
if errorlevel 1 (
  echo.
  echo [AVISO] Sin permisos de administrador no puedo revisar el firewall.
  echo Si otros equipos no logran conectarse, cierra esto y abre el .bat con
  echo clic derecho - Ejecutar como administrador.
  goto finFirewall
)
powershell -NoProfile -Command "Get-NetFirewallApplicationFilter -Program '*node.exe' -ErrorAction SilentlyContinue | Get-NetFirewallRule | Where-Object Action -eq Block | Remove-NetFirewallRule" >nul 2>nul
netsh advfirewall firewall delete rule name="Brillant servidor" >nul 2>nul
netsh advfirewall firewall add rule name="Brillant servidor" dir=in action=allow protocol=TCP localport=%PUERTO% profile=any >nul 2>nul
if errorlevel 1 (
  echo [AVISO] No pude abrir el puerto %PUERTO% en el firewall.
) else (
  echo Firewall listo: puerto %PUERTO% abierto en redes privadas y publicas.
)
:finFirewall

rem ---- Juego web para el telefono (build\web) ----
if not exist "%~dp0build\web\index.html" (
  echo.
  echo No esta compilado el juego web ^(para jugar desde el telefono^).
  call "%~dp0compilar-web.bat" nopause
)

echo.
echo ============================================================
echo  SERVIDOR BRILLANT
echo  En este equipo:   http://localhost:%PUERTO%
echo  Desde otros equipos de tu red usa una de estas direcciones:
for /f "tokens=2 delims=:" %%I in ('ipconfig ^| findstr /i "IPv4"') do (
  for /f "tokens=*" %%J in ("%%I") do echo      http://%%J:%PUERTO%
)
echo  Telefono: abre esa misma direccion en el navegador y juega ahi.
echo  ^(Si cambiaste el codigo del juego, ejecuta compilar-web.bat^)
echo.
echo  Para detenerlo: Ctrl+C
echo ============================================================
echo.

node --env-file=.env %ARCHIVO%

echo.
echo El servidor se detuvo.
>>>>>>> d643b2deb77645cecab8a4ac2a7cc615a22d40ed
pause