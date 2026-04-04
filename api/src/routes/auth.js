const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

const errResponse = (res, status, msg) =>
  res.status(status).json({ timestamp: new Date(), status, erro: msg });

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const { nome, email, password } = req.body || {};

  if (!nome || typeof nome !== 'string' || nome.trim().length === 0) {
    return errResponse(res, 400, 'Nome é obrigatório');
  }
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return errResponse(res, 400, 'Email inválido');
  }
  if (!password || password.length < 6) {
    return errResponse(res, 400, 'Password deve ter pelo menos 6 caracteres');
  }

  try {
    const existing = await db.query('SELECT utilizador_id FROM utilizadores WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return errResponse(res, 400, 'Email já registado');
    }

    const hash = await bcrypt.hash(password, 12);
    const result = await db.query(
      'INSERT INTO utilizadores (nome, email, password_hash) VALUES ($1, $2, $3) RETURNING utilizador_id, nome, email',
      [nome.trim(), email, hash]
    );

    const user = result.rows[0];
    const token = jwt.sign({ sub: user.email }, process.env.JWT_SECRET, { expiresIn: '24h' });
    return res.status(201).json({ token, tipo: 'Bearer', email: user.email, nome: user.nome });
  } catch (e) {
    console.error('register error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body || {};

  if (!email || !password) {
    return errResponse(res, 400, 'Email e password são obrigatórios');
  }

  try {
    const result = await db.query('SELECT * FROM utilizadores WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return errResponse(res, 401, 'Credenciais inválidas');
    }

    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return errResponse(res, 401, 'Credenciais inválidas');
    }

    await db.query('UPDATE utilizadores SET ultimo_acesso = NOW() WHERE utilizador_id = $1', [user.utilizador_id]);

    const token = jwt.sign({ sub: user.email }, process.env.JWT_SECRET, { expiresIn: '24h' });
    return res.json({ token, tipo: 'Bearer', email: user.email, nome: user.nome });
  } catch (e) {
    console.error('login error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

module.exports = router;
