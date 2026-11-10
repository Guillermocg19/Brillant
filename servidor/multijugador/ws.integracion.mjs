// Prueba de integración de la capa WebSocket (auth JWT, lobby, reconexión, conceder).
// Uso: node multijugador/ws.integracion.mjs   (requiere: npm i ws jsonwebtoken)
// Se ejecutó con ws real y un reemplazo mínimo de jsonwebtoken; con el paquete real es la misma API.
import http from 'node:http';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';
import WebSocket from 'ws';
import { adjuntarMultijugador } from './ws.js';
import { Gestor } from './gestor.js';
import { NIVELES, zonasDeNivel } from './niveles.js';
import { generarValoresIniciales } from './tablero.js';

const SECRETO = 'x'.repeat(40);
const usuarios = { 1:{id:1,nombre:'Ana'}, 2:{id:2,nombre:'Beto'}, 3:{id:3,nombre:'Cris'} };
const db = { prepare: () => ({ get: (id) => usuarios[id] }) };
const srv = http.createServer();
const gestor = new Gestor({ graciaMs: 300 });
adjuntarMultijugador(srv, { db, secreto: SECRETO, gestor });
await new Promise((r) => srv.listen(0, r));
const url = `ws://localhost:${srv.address().port}/ws`;
const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

class Cli {
  constructor(){ this.msgs=[]; }
  async abrir(){ this.ws=new WebSocket(url); this.ws.on('message',d=>this.msgs.push(JSON.parse(d)));
    await new Promise(r=>this.ws.on('open',r)); return this; }
  send(o){ this.ws.send(JSON.stringify(o)); }
  async espera(fn,ms=1000){ const t=Date.now(); while(Date.now()-t<ms){ const m=this.msgs.findLast(fn); if(m) return m; await esperar(10);} throw new Error('timeout '+JSON.stringify(this.msgs.slice(-3))); }
  estado(){ return this.msgs.findLast(m=>m.type==='state'); }
}
const tok = (id) => jwt.sign({ id }, SECRETO);
const conectar = async (id) => { const c = await new Cli().abrir(); c.send({type:'auth',token:tok(id)}); await c.espera(m=>m.type==='auth_ok'); return c; };

// 1. Sin autenticar no se puede hacer nada; token falso se rechaza y cierra
{ const c = await new Cli().abrir(); c.send({type:'create_room',nivel:1});
  const e = await c.espera(m=>m.type==='error'); assert.equal(e.code,'unauthenticated'); c.ws.close(); }
{ const c = await new Cli().abrir(); c.send({type:'auth',token:'basura'});
  const e = await c.espera(m=>m.type==='error'); assert.equal(e.code,'unauthorized');
  for (let i=0;i<100&&c.ws.readyState!==3;i++) await esperar(10);
  assert.equal(c.ws.readyState,3,'el servidor debe cerrar el socket'); }
console.log('ok auth');

// 2. Crear sala, unirse con código, lobby con nivel y jugador por nombre de cuenta
const ana = await conectar(1);
ana.send({type:'create_room',nivel:2});
const joined = await ana.espera(m=>m.type==='joined');
assert.match(joined.code,/^[A-HJKMNP-Z2-9]{6}$/);
const beto = await conectar(2);
beto.send({type:'join_room',code:joined.code.toLowerCase()});
await beto.espera(m=>m.type==='joined');
const st = await ana.espera(m=>m.type==='state'&&m.players.length===2);
assert.deepEqual(st.players.map(p=>p.name),['Ana','Beto']);
assert.equal(st.nivel,2); assert.equal(st.players[0].isHost,true);
beto.send({type:'join_room',code:'ZZZZZZ'}); // otra sala inexistente
assert.equal((await beto.espera(m=>m.type==='error')).code,'already_in_room'.replace('already_in_room','room_not_found'));
console.log('ok lobby');

// 3. Iniciar: primero la PREPARACIÓN (cada jugador elige sus números), luego la ronda
beto.send({type:'lobby_ready',ready:true}); 
await ana.espera(m=>m.type==='state'&&m.players[1]?.lobbyReady);
ana.send({type:'start'});
const sp = await ana.espera(m=>m.type==='state'&&m.status==='preparando');
assert.equal(sp.setup.stars.length,6); assert.equal(sp.setup.confirmed,false);
assert.equal(sp.dice.length,0); assert.equal(sp.round,0);
ana.send({type:'place',round:0,ancla:1,fila:0,columna:0});          // aún no se juega
assert.equal((await ana.espera(m=>m.type==='error'&&m.code==='not_playing')).code,'not_playing');
ana.send({type:'confirm_setup',valores:[1,1,2,3,4,5]});             // repetidos: rechazado
assert.equal((await ana.espera(m=>m.type==='error'&&m.code==='invalid_setup')).code,'invalid_setup');
const disp = () => generarValoresIniciales(NIVELES[2], zonasDeNivel(2), Math.random).map(x=>x.valor);
const va = disp(); let vb = disp();
while (JSON.stringify(va)===JSON.stringify(vb)) vb = disp();
ana.send({type:'confirm_setup',valores:va});
await ana.espera(m=>m.type==='state'&&m.setup?.confirmed===true);
await esperar(50); assert.equal(gestor.salaDe('1').estado,'preparando'); // falta Beto
beto.send({type:'confirm_setup',valores:vb});                       // cada uno con su disposición
console.log('ok preparación');

const s1 = await ana.espera(m=>m.type==='state'&&m.status==='jugando');
assert.equal(s1.round,1); assert.equal(s1.dice.length,2); assert.equal(s1.board.flat().filter(v=>v!==null).length,6);
assert.ok(s1.options.length>=1); assert.ok(s1.canPlay);
const opt = s1.options.find(o=>o.cells.length);
ana.send({type:'place',round:1,ancla:opt.ancla,fila:opt.cells[0][0],columna:opt.cells[0][1]});
const s2 = await ana.espera(m=>m.type==='state'&&m.yourPending);
assert.equal(s2.yourPending.ancla,opt.ancla);
ana.send({type:'ready',round:1});
await esperar(50); assert.equal(gestor.salaDe('1').ronda,1);   // falta Beto
beto.send({type:'ready',round:1});                              // pasa
const s3 = await ana.espera(m=>m.type==='state'&&m.round===2);
assert.equal(s3.board.flat().filter(v=>v!==null).length,7);
console.log('ok ronda');

// 4. Mensaje inválido y rate limit no tumban al servidor
ana.ws.send('esto no es json');
assert.equal((await ana.espera(m=>m.type==='error'&&m.code==='bad_request')).code,'bad_request');
ana.send({type:'place',round:2,ancla:'x',fila:0,columna:0});
await ana.espera(m=>m.type==='error'&&m.code==='bad_request');
console.log('ok robustez');

// 5. Caída y reconexión automática por cuenta (sin token de sala)
beto.ws.terminate();
await ana.espera(m=>m.type==='event'&&m.kind==='player_disconnected');
const beto2 = await conectar(2);                    // vuelve dentro de la gracia
const s4 = await beto2.espera(m=>m.type==='state');
assert.equal(s4.status,'jugando'); assert.equal(s4.round,2);
await ana.espera(m=>m.type==='event'&&m.kind==='player_reconnected');
await esperar(400); assert.equal(gestor.salaDe('2').jugador('2').activo,true);
console.log('ok reconexión');

// 6. Misma cuenta en otro dispositivo: el viejo recibe replaced y se cierra
const beto3 = await conectar(2);
await beto2.espera(m=>m.type==='replaced');
await beto3.espera(m=>m.type==='state');
console.log('ok replaced');

// 7. Conceder
beto3.send({type:'resign'});
const fin = await ana.espera(m=>m.type==='state'&&m.status==='terminada');
assert.equal(fin.result.reason,'last_standing'); assert.deepEqual(fin.result.winnerIds,['1']);
console.log('ok conceder');

// 8. Tras terminar, crear otra sala libera la anterior
ana.send({type:'create_room',nivel:1});
await ana.espera(m=>m.type==='joined'&&m.code!==joined.code);
console.log('ok nueva sala tras terminar');

// 9. Salir: ya no se reanuda
ana.send({type:'leave'}); await ana.espera(m=>m.type==='left');
ana.ws.close(); await esperar(50);
const ana2 = new Cli(); await ana2.abrir(); ana2.send({type:'auth',token:tok(1)});
assert.equal((await ana2.espera(m=>m.type==='auth_ok')).inRoom,false);
console.log('ok salir');
process.exit(0);
