# Brillant

Juego multijugador. Una persona **crea el servidor** y los demás **se conectan** a él.

## Antes de empezar

- **Quien crea el servidor** necesita [Node.js](https://nodejs.org) (versión 20 o superior).
- **Quien se conecta** necesita [Flutter](https://docs.flutter.dev/get-started/install).
  Además debe activar el Modo desarrollador de Windows: abre una terminal y escribe
  `start ms-settings:developers`.

## Si vas a crear la partida

1. Haz doble clic en **`iniciar-servidor.bat`**
   (clic derecho y *Ejecutar como administrador*, para que configure el firewall).
2. Te mostrará unas direcciones como `http://192.168.1.45:3000`.
   Pásale a tus amigos la que **no** diga `localhost`.
3. Deja esa ventana abierta mientras juegan.

## Si te vas a unir desde el teléfono

1. Conecta el teléfono a la misma red que la PC del servidor
   (si la red no tiene internet, apaga los datos móviles).
2. Abre en el navegador la dirección del servidor, por ejemplo `http://192.168.137.1:3000`.
3. Crea tu cuenta y juega. No hay que instalar nada.

La PC del servidor necesita Flutter para compilar el juego web la primera vez
(`iniciar-servidor.bat` lo hace solo). Si cambias el código del juego, ejecuta
**`compilar-web.bat`** y recarga la página en el teléfono.

## Si te vas a unir desde una PC

1. Haz doble clic en **`conectar.bat`**.
2. Escribe la dirección que te pasaron (por ejemplo `192.168.1.45`) y pulsa Enter.
3. Espera a que se abra el juego (la primera vez tarda unos minutos).

## Jugar

1. Cada quien **crea su propia cuenta**.
2. Uno crea una sala y comparte el **código de 6 letras**.
3. Los demás entran con ese código.
4. Todos marcan listo y el anfitrión inicia.

## Importante

- Todos deben estar en la **misma red WiFi**. Si están en lugares distintos, usa
  [Tailscale](https://tailscale.com) (todos lo instalan y usan la IP que les da) o `ngrok http 3000`.
- Si no conecta, revisa que el servidor siga abierto y que la dirección sea correcta.
- No subas a GitHub los archivos `servidor/.env` ni `servidor/usuarios.db`.
