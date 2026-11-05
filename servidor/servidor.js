import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import Database from 'better-sqlite3';
import jwt from 'jsonwebtoken';
import { hash, verify } from '@node-rs/argon2';

const SECRETO = process.env.JWT_SECRET;
if (!SECRETO || SECRETO.length < 32) {
  console.error('Falta JWT_SECRET en el archivo .env (mínimo 32 caracteres).');
  process.exit(1);
}
const PUERTO = process.env.PORT || 3000;

// ---------- Base de datos (un archivo SQLite) ----------
const db = new Database(process.env.DB_PATH || 'usuarios.db');
db.exec(`
  CREATE TABLE IF NOT EXISTS usuarios (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre     TEXT NOT NULL,
    correo     TEXT NOT NULL UNIQUE,
    contrasena TEXT NOT NULL      -- aquí va el HASH, nunca la contraseña
  )
`);

// ---------- Servidor ----------
const app = express();
app.use(helmet());
app.use(express.json({ limit: '10kb' }));

// Máximo 20 intentos de entrar/registrarse cada 15 minutos por IP (frena la fuerza bruta).
const limite = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: Number(process.env.LIMITE || 20),
  handler: (req, res) =>
    res.status(429).json({ error: 'Demasiados intentos. Espera unos minutos.' }),
});

const publico = (u) => ({ id: u.id, nombre: u.nombre, correo: u.correo });
const crearToken = (u) => jwt.sign({ id: u.id }, SECRETO, { expiresIn: '7d' });

// Exige "Authorization: Bearer <token>" y que la cuenta todavía exista.
function requiereToken(req, res, next) {
  const token = (req.get('authorization') || '').replace('Bearer ', '');
  try {
    const { id } = jwt.verify(token, SECRETO, { algorithms: ['HS256'] });
    const usuario = db.prepare('SELECT * FROM usuarios WHERE id = ?').get(id);
    if (!usuario) throw new Error('cuenta borrada');
    req.usuario = usuario;
    next();
  } catch {
    res.status(401).json({ error: 'Sesión no válida. Inicia sesión de nuevo.' });
  }
}

// Crear cuenta
app.post('/registro', limite, async (req, res) => {
  const nombre = String(req.body.nombre ?? '').trim();
  const correo = String(req.body.correo ?? '').trim().toLowerCase();
  const contrasena = String(req.body.contrasena ?? '');

  if (!nombre || nombre.length > 40)
    return res.status(400).json({ error: 'Escribe tu nombre (máximo 40 letras).' });
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(correo) || correo.length > 254)
    return res.status(400).json({ error: 'El correo no es válido.' });
  if (contrasena.length < 10 || contrasena.length > 128)
    return res.status(400).json({ error: 'La contraseña debe tener entre 10 y 128 caracteres.' });

  if (db.prepare('SELECT 1 FROM usuarios WHERE correo = ?').get(correo))
    return res.status(409).json({ error: 'Ese correo ya está registrado.' });

  const resultado = db
    .prepare('INSERT INTO usuarios (nombre, correo, contrasena) VALUES (?, ?, ?)')
    .run(nombre, correo, await hash(contrasena)); // Argon2id
  const usuario = { id: resultado.lastInsertRowid, nombre, correo };
  res.status(201).json({ usuario: publico(usuario), token: crearToken(usuario) });
});

// Iniciar sesión
const HASH_FALSO = await hash('contrasena-de-relleno');
app.post('/login', limite, async (req, res) => {
  const correo = String(req.body.correo ?? '').trim().toLowerCase();
  const contrasena = String(req.body.contrasena ?? '');

  const usuario = db.prepare('SELECT * FROM usuarios WHERE correo = ?').get(correo);
  // Se verifica SIEMPRE un hash (aunque el correo no exista) para tardar lo mismo
  // y no revelar qué correos están registrados.
  const correcta = await verify(usuario ? usuario.contrasena : HASH_FALSO, contrasena)
    .catch(() => false);

  if (!usuario || !correcta)
    return res.status(401).json({ error: 'Correo o contraseña incorrectos.' });
  res.json({ usuario: publico(usuario), token: crearToken(usuario) });
});

// Datos de la cuenta (sirve para recordar la sesión al abrir la app)
app.get('/yo', requiereToken, (req, res) => {
  res.json({ usuario: publico(req.usuario) });
});

// Borrar la cuenta: hay que estar dentro Y volver a escribir la contraseña
app.delete('/cuenta', requiereToken, limite, async (req, res) => {
  const contrasena = String(req.body.contrasena ?? '');
  const correcta = await verify(req.usuario.contrasena, contrasena).catch(() => false);
  if (!correcta) return res.status(403).json({ error: 'La contraseña no es correcta.' });

  db.prepare('DELETE FROM usuarios WHERE id = ?').run(req.usuario.id);
  res.status(204).end();
});

// Cualquier error (JSON roto, etc.) se responde sin revelar detalles internos.
app.use((err, req, res, next) => {
  res.status(err.status === 400 ? 400 : 500).json({ error: 'Petición no válida.' });
});

app.listen(PUERTO, () => console.log(`Servidor listo en http://localhost:${PUERTO}`));