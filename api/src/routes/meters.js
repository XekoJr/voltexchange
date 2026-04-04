const router = require('express').Router();
const db = require('../config/database');
const auth = require('../middleware/auth');

const errResponse = (res, status, msg) =>
  res.status(status).json({ timestamp: new Date(), status, erro: msg });

const getUserId = async (email) => {
  const r = await db.query('SELECT utilizador_id FROM utilizadores WHERE email = $1', [email]);
  return r.rows.length ? r.rows[0].utilizador_id : null;
};

// GET /api/meters — list authenticated user's meters
router.get('/', auth, async (req, res) => {
  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    const result = await db.query('SELECT * FROM contadores WHERE utilizador_id = $1', [userId]);
    return res.json(result.rows);
  } catch (e) {
    console.error('listar contadores error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// POST /api/meters/:contadorId/readings — submit a new reading
router.post('/:contadorId/readings', auth, async (req, res) => {
  const contadorId = parseInt(req.params.contadorId);
  const { kwhLeitura, dadosAudit } = req.body || {};

  if (!kwhLeitura || parseFloat(kwhLeitura) <= 0) {
    return errResponse(res, 400, 'kwhLeitura deve ser um número positivo');
  }

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    const contador = await db.query(
      'SELECT contador_id FROM contadores WHERE contador_id = $1 AND utilizador_id = $2',
      [contadorId, userId]
    );
    if (!contador.rows.length) {
      return errResponse(res, 403, 'Contador não pertence a este utilizador');
    }

    const now = new Date();
    const result = await db.query(
      'INSERT INTO leituras (contador_id, data_hora, kwh_leitura, dados_audit) VALUES ($1, $2, $3, $4) RETURNING leitura_id, data_hora',
      [contadorId, now, parseFloat(kwhLeitura), JSON.stringify(dadosAudit || {})]
    );

    return res.status(201).json({
      mensagem: 'Leitura registada com sucesso',
      leituraId: result.rows[0].leitura_id,
      dataHora: result.rows[0].data_hora,
      contadorId,
    });
  } catch (e) {
    console.error('registar leitura error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// GET /api/meters/:id/readings?inicio=&fim= — list readings by period (exploits partitioning)
router.get('/:id/readings', auth, async (req, res) => {
  const contadorId = parseInt(req.params.id);
  const { inicio, fim } = req.query;

  if (!inicio || !fim) {
    return errResponse(res, 400, 'Parâmetros inicio e fim são obrigatórios (ISO 8601)');
  }

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    const contador = await db.query(
      'SELECT contador_id FROM contadores WHERE contador_id = $1 AND utilizador_id = $2',
      [contadorId, userId]
    );
    if (!contador.rows.length) {
      return errResponse(res, 403, 'Contador não pertence a este utilizador');
    }

    const result = await db.query(
      'SELECT * FROM leituras WHERE contador_id = $1 AND data_hora BETWEEN $2 AND $3 ORDER BY data_hora DESC',
      [contadorId, inicio, fim]
    );
    return res.json(result.rows);
  } catch (e) {
    console.error('listar leituras error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

module.exports = router;
