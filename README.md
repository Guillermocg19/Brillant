# Brillant

Juego multijugador. Una persona **crea el servidor** y los demás **se conectan** a él.

## Antes de empezar

- **Quien crea el servidor** necesita [Node.js](https://nodejs.org) (versión 20 o superior).
- **Quien se conecta** necesita [Flutter](https://docs.flutter.dev/get-started/install).
  Además debe activar el Modo desarrollador de Windows: abre una terminal y escribe
  `start ms-settings:developers`.

## Si vas a crear la partida

1. Haz doble clic en **`iniciar-servidor.bat`**
   (la primera vez, clic derecho y *Ejecutar como administrador*).
2. Te mostrará unas direcciones como `http://192.168.1.45:3000`.
   Pásale a tus amigos la que **no** diga `localhost`.
3. Deja esa ventana abierta mientras juegan.

## Si te vas a unir a una partida

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
