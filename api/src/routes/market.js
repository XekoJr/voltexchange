const router = require('express').Router();
const db = require('../config/database');
const auth = require('../middleware/auth');
const { errResponse, getUserId } = require('../utils/helpers');

// GET /api/market/offers?regiao= — list active offers ordered by price
router.get('/offers', auth, async (req, res) => {
  const { regiao } = req.query;
  try {
    let result;
    if (regiao) {
      result = await db.query(
        "SELECT * FROM ofertasvenda WHERE estado = 'ATIVA' AND regiao = $1 ORDER BY preco_unitario ASC",
        [regiao]
      );
    } else {
      result = await db.query(
        "SELECT * FROM ofertasvenda WHERE estado = 'ATIVA' ORDER BY preco_unitario ASC"
      );
    }
    return res.json(result.rows);
  } catch (e) {
    console.error('listar ofertas error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// POST /api/market/offers — create a new sale offer
router.post('/offers', auth, async (req, res) => {
  const { quantidadeKwh, precoUnitario, regiao } = req.body || {};

  if (!quantidadeKwh || parseFloat(quantidadeKwh) <= 0) {
    return errResponse(res, 400, 'quantidadeKwh deve ser positivo');
  }
  if (!precoUnitario || parseFloat(precoUnitario) <= 0) {
    return errResponse(res, 400, 'precoUnitario deve ser positivo');
  }

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    const result = await db.query(
      "INSERT INTO ofertasvenda (vendedor_id, quantidade_kwh, preco_unitario, estado, regiao) VALUES ($1, $2, $3, 'ATIVA', $4) RETURNING *",
      [userId, parseFloat(quantidadeKwh), parseFloat(precoUnitario), regiao || null]
    );
    return res.status(201).json(result.rows[0]);
  } catch (e) {
    console.error('criar oferta error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// POST /api/market/offers/:ofertaId/buy — direct purchase via sp_ExecutarCompraDireta
router.post('/offers/:ofertaId/buy', auth, async (req, res) => {
  const ofertaId = parseInt(req.params.ofertaId);
  const { quantidade } = req.body || {};

  if (!quantidade || parseFloat(quantidade) <= 0) {
    return errResponse(res, 400, 'quantidade deve ser positiva');
  }

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    await db.query('CALL sp_ExecutarCompraDireta($1, $2, $3)', [ofertaId, userId, parseFloat(quantidade)]);
    return res.json({
      mensagem: 'Compra realizada com sucesso',
      ofertaId,
      quantidade: parseFloat(quantidade),
    });
  } catch (e) {
    // Stored procedure raises exceptions with descriptive messages
    console.error('compra direta error:', e.message);
    return errResponse(res, 400, e.message || 'Erro ao executar compra');
  }
});

// POST /api/market/order — create a pending purchase order
router.post('/order', auth, async (req, res) => {
  const { quantidadeKwh, precoMaximo, regiao } = req.body || {};

  if (!quantidadeKwh || parseFloat(quantidadeKwh) <= 0) {
    return errResponse(res, 400, 'quantidadeKwh deve ser positivo');
  }
  if (!precoMaximo || parseFloat(precoMaximo) <= 0) {
    return errResponse(res, 400, 'precoMaximo deve ser positivo');
  }

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    const result = await db.query(
      "INSERT INTO ordenscompra (comprador_id, quantidade_kwh, preco_maximo, estado, regiao) VALUES ($1, $2, $3, 'PENDENTE', $4) RETURNING *",
      [userId, parseFloat(quantidadeKwh), parseFloat(precoMaximo), regiao || null]
    );
    return res.status(201).json(result.rows[0]);
  } catch (e) {
    console.error('criar ordem error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// PATCH /api/market/offers/:id/cancel — cancel own active offer
router.patch('/offers/:id/cancel', auth, async (req, res) => {
  const ofertaId = parseInt(req.params.id);
  if (isNaN(ofertaId)) return errResponse(res, 400, 'id inválido');

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    const result = await db.query(
      "UPDATE ofertasvenda SET estado = 'CANCELADA' WHERE oferta_id = $1 AND vendedor_id = $2 AND estado = 'ATIVA' RETURNING *",
      [ofertaId, userId]
    );
    if (!result.rows.length) {
      return errResponse(res, 404, 'Oferta ativa não encontrada para este utilizador');
    }
    return res.json(result.rows[0]);
  } catch (e) {
    console.error('cancelar oferta error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// PATCH /api/market/order/:id/cancel — cancel own pending order
router.patch('/order/:id/cancel', auth, async (req, res) => {
  const ordemId = parseInt(req.params.id);
  if (isNaN(ordemId)) return errResponse(res, 400, 'id inválido');

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    const result = await db.query(
      "UPDATE ordenscompra SET estado = 'CANCELADA' WHERE ordem_id = $1 AND comprador_id = $2 AND estado = 'PENDENTE' RETURNING *",
      [ordemId, userId]
    );
    if (!result.rows.length) {
      return errResponse(res, 404, 'Ordem pendente não encontrada para este utilizador');
    }
    return res.json(result.rows[0]);
  } catch (e) {
    console.error('cancelar ordem error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// POST /api/market/match — trigger matching engine manually (MANDATORY)
router.post('/match', auth, async (req, res) => {
  try {
    await db.query('CALL sp_MatchingEngine()');
    return res.json({ mensagem: 'Matching engine executado com sucesso' });
  } catch (e) {
    console.error('matching engine error:', e.message);
    return errResponse(res, 500, e.message || 'Erro ao executar matching engine');
  }
});

module.exports = router;
