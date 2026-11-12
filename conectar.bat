@echo off
setlocal EnableExtensions
title Brillant - Conectar a un servidor

rem ------------------------------------------------------------
rem  Abre el juego apuntando a un servidor que YA esta corriendo
rem  (en tu red local, con ngrok/Tailscale o en un VPS).
rem  Coloca este archivo en la raiz del proyecto Flutter (junto a pubspec.yaml).
rem
rem  Sin argumentos: abre en Chrome, Edge o Brave, el que tengas instalado.
rem  Si no hay ninguno, abre la app de Windows.
rem  Forzar uno:  conectar.bat chrome   conectar.bat edge   conectar.bat windows
rem ------------------------------------------------------------

cd /d "%~dp0"
if not exist pubspec.yaml (
  echo [ERROR] No encuentro pubspec.yaml junto a este archivo.
  echo Pon este .bat en la raiz del proyecto Flutter.
  pause
  exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter no esta instalado o no esta en el PATH.
  echo Instalalo desde https://docs.flutter.dev/get-started/install y abre este archivo de nuevo.
  pause
  exit /b 1
)

set "GUARDADO=%~dp0.ultimo-servidor.txt"
set "ULTIMO="
if exist "%GUARDADO%" set /p ULTIMO=<"%GUARDADO%"

echo.
echo Escribe la direccion del servidor. Ejemplos:
echo     10.22.17.114
echo     192.168.1.45:3000
echo     https://abc123.ngrok-free.app
if defined ULTIMO echo Enter vacio = usar la ultima: %ULTIMO%
echo.
set "ENTRADA="
set /p ENTRADA=Servidor: 
if not defined ENTRADA set "ENTRADA=%ULTIMO%"
if not defined ENTRADA (
  echo No escribiste ninguna direccion.
  pause
  exit /b 1
)

rem ---- Completar http:// y el puerto 3000 si faltan ----
echo %ENTRADA%| findstr /b /i /c:"http://" /c:"https://" >nul
if not errorlevel 1 goto urlLista
echo %ENTRADA%| findstr /c:":" >nul
if errorlevel 1 set "ENTRADA=%ENTRADA%:3000"
set "ENTRADA=http://%ENTRADA%"
:urlLista
set "URL=%ENTRADA%"

rem ---- Comprobar que el servidor responde ----
where curl >nul 2>nul
if errorlevel 1 goto elegirDispositivo
echo.
echo Probando conexion con %URL% ...
curl -s -m 6 -o NUL "%URL%/yo"
if errorlevel 1 (
  echo.
  echo [ERROR] No hay respuesta del servidor en %URL%
  echo   - Esta corriendo iniciar-servidor.bat en la otra PC?
  echo   - Estan en la misma red WiFi, o usas ngrok/Tailscale si estan en redes distintas?
  echo   - El firewall de la PC del servidor permite el puerto 3000?
  pause
  exit /b 1
)
echo Servidor encontrado.
>"%GUARDADO%" echo %URL%

:elegirDispositivo
set "DISPOSITIVO=%~1"
if defined DISPOSITIVO goto dispositivoElegido

echo.
echo Buscando un navegador compatible...
set "TMPDEV=%TEMP%\brillant-dispositivos.txt"
call flutter devices > "%TMPDEV%" 2>&1

findstr /i /r /c:"web-javascript.*chrome" "%TMPDEV%" >nul
if not errorlevel 1 (
  set "DISPOSITIVO=chrome"
  goto dispositivoElegido
)
findstr /i /r /c:"web-javascript.*edge" "%TMPDEV%" >nul
if not errorlevel 1 (
  set "DISPOSITIVO=edge"
  goto dispositivoElegido
)

rem ---- Brave: Flutter lo usa si se lo indicamos como "Chrome" ----
set "BRAVE="
if exist "%ProgramFiles%\BraveSoftware\Brave-Browser\Application\brave.exe" set "BRAVE=%ProgramFiles%\BraveSoftware\Brave-Browser\Application\brave.exe"
if exist "%ProgramFiles(x86)%\BraveSoftware\Brave-Browser\Application\brave.exe" set "BRAVE=%ProgramFiles(x86)%\BraveSoftware\Brave-Browser\Application\brave.exe"
if exist "%LocalAppData%\BraveSoftware\Brave-Browser\Application\brave.exe" set "BRAVE=%LocalAppData%\BraveSoftware\Brave-Browser\Application\brave.exe"
if not defined BRAVE goto sinNavegador
set "CHROME_EXECUTABLE=%BRAVE%"
set "DISPOSITIVO=chrome"
goto dispositivoElegido

:sinNavegador
echo No encontre Chrome, Edge ni Brave. Se abrira la app de Windows.
set "DISPOSITIVO=windows"

:dispositivoElegido
set "EXTRA="
if /i "%DISPOSITIVO%"=="chrome" set "EXTRA=--web-port=8099"
if /i "%DISPOSITIVO%"=="edge" set "EXTRA=--web-port=8099"

echo.
echo Iniciando Brillant en "%DISPOSITIVO%" con servidor %URL% ...
echo ^(la primera vez tarda varios minutos en compilar; no cierres esta ventana mientras juegas^)
echo.
call flutter run -d %DISPOSITIVO% %EXTRA% --dart-define=API_URL=%URL%
if errorlevel 1 (
  echo.
  echo Si el error menciona "symlink" o "Developer Mode":
  echo ejecuta  start ms-settings:developers  y activa el Modo desarrollador.
  echo Si el puerto 8099 esta ocupado, cierra otra ventana de Brillant que siga abierta.
)
pause
