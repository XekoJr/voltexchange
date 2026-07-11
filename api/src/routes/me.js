const router = require('express').Router();
const db = require('../config/database');
const auth = require('../middleware/auth');
const { errResponse, getUserId } = require('../utils/helpers');
const { depositLimiter } = require('../middleware/rateLimit');

// Teto de saldo — dinheiro fictício, mas sem isto um script em loop
// inflacionava o saldo indefinidamente e distorcia a demo para todos
const SALDO_MAXIMO = 100000;

// GET /api/me — perfil do utilizador autenticado (inclui saldo)
router.get('/', auth, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT utilizador_id, nome, email, saldo, data_criacao, ultimo_acesso FROM utilizadores WHERE email = $1',
      [req.user.email]
    );
    if (!result.rows.length) return errResponse(res, 401, 'Utilizador não encontrado');
    return res.json(result.rows[0]);
  } catch (e) {
    console.error('perfil error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// POST /api/me/deposit — carregamento de saldo FICTÍCIO (limitado em
// frequência por depositLimiter e com um teto de saldo total)
router.post('/deposit', auth, depositLimiter, async (req, res) => {
  const { valor } = req.body || {};
  const parsed = parseFloat(valor);

  if (!valor || isNaN(parsed) || parsed <= 0) {
    return errResponse(res, 400, 'valor deve ser um número positivo');
  }
  if (parsed > 10000) {
    return errResponse(res, 400, 'valor máximo por depósito é 10000');
  }

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    const result = await db.query(
      'UPDATE utilizadores SET saldo = LEAST(saldo + $1, $3) WHERE utilizador_id = $2 RETURNING saldo',
      [parsed, userId, SALDO_MAXIMO]
    );
    return res.json({
      mensagem: 'Depósito de demonstração efetuado',
      saldo: result.rows[0].saldo,
      demo: true,
    });
  } catch (e) {
    console.error('deposito error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// GET /api/me/offers?estado= — ofertas de venda do próprio utilizador
router.get('/offers', auth, async (req, res) => {
  const { estado } = req.query;
  const estadosValidos = ['ATIVA', 'VENDIDA', 'CANCELADA'];

  if (estado && !estadosValidos.includes(estado)) {
    return errResponse(res, 400, `estado deve ser um de: ${estadosValidos.join(', ')}`);
  }

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    const result = estado
      ? await db.query(
          'SELECT * FROM ofertasvenda WHERE vendedor_id = $1 AND estado = $2 ORDER BY data_criacao DESC',
          [userId, estado]
        )
      : await db.query(
          'SELECT * FROM ofertasvenda WHERE vendedor_id = $1 ORDER BY data_criacao DESC',
          [userId]
        );
    return res.json(result.rows);
  } catch (e) {
    console.error('minhas ofertas error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// GET /api/me/orders?estado= — ordens de compra do próprio utilizador
router.get('/orders', auth, async (req, res) => {
  const { estado } = req.query;
  const estadosValidos = ['PENDENTE', 'CONCLUIDA', 'CANCELADA'];

  if (estado && !estadosValidos.includes(estado)) {
    return errResponse(res, 400, `estado deve ser um de: ${estadosValidos.join(', ')}`);
  }

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    const result = estado
      ? await db.query(
          'SELECT * FROM ordenscompra WHERE comprador_id = $1 AND estado = $2 ORDER BY ordem_id DESC',
          [userId, estado]
        )
      : await db.query(
          'SELECT * FROM ordenscompra WHERE comprador_id = $1 ORDER BY ordem_id DESC',
          [userId]
        );
    return res.json(result.rows);
  } catch (e) {
    console.error('minhas ordens error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// GET /api/me/transactions?papel=comprador|vendedor — histórico do próprio
// utilizador; is_comprador indica o papel dele em cada transação
router.get('/transactions', auth, async (req, res) => {
  const { papel } = req.query;

  if (papel && !['comprador', 'vendedor'].includes(papel)) {
    return errResponse(res, 400, 'papel deve ser comprador ou vendedor');
  }

  try {
    const userId = await getUserId(req.user.email);
    if (!userId) return errResponse(res, 401, 'Utilizador não encontrado');

    let where = '(comprador_id = $1 OR vendedor_id = $1)';
    if (papel === 'comprador') where = 'comprador_id = $1';
    if (papel === 'vendedor') where = 'vendedor_id = $1';

    const result = await db.query(
      `SELECT *, (comprador_id = $1) AS is_comprador
       FROM transacoes
       WHERE ${where}
       ORDER BY data_transacao DESC
       LIMIT 200`,
      [userId]
    );
    return res.json(result.rows);
  } catch (e) {
    console.error('minhas transacoes error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

module.exports = router;
