const router = require('express').Router();
const db = require('../config/database');
const auth = require('../middleware/auth');
const { errResponse } = require('../utils/helpers');

// GET /api/admin/anomalies — JSONB query (uses GIN index on dados_audit)
router.get('/anomalies', auth, async (req, res) => {
  try {
    const leituras = await db.query(`
      SELECT l.leitura_id, l.contador_id, l.data_hora, l.dados_audit
      FROM leituras l
      WHERE (
        (l.dados_audit ? 'temperatura'
          AND (l.dados_audit->>'temperatura')::numeric > 80)
        OR (l.dados_audit->>'erro_codigo') IS NOT NULL
      )
      ORDER BY l.data_hora DESC
      LIMIT 100
    `);

    const contadores = await db.query(
      "SELECT contador_id, numero_serie, regiao, estado FROM contadores WHERE estado = 'MANUTENCAO'"
    );

    return res.json({
      totalAnomalias: leituras.rows.length,
      contadoresEmManutencao: contadores.rows.length,
      leituras: leituras.rows,
      contadores: contadores.rows,
    });
  } catch (e) {
    console.error('anomalias error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// GET /api/admin/transactions — full transaction history
router.get('/transactions', auth, async (req, res) => {
  try {
    const result = await db.query(`
      SELECT transacao_id, tipo_transacao, comprador_id, vendedor_id,
             quantidade_kwh, preco_unitario, valor_total, data_transacao
      FROM transacoes
      ORDER BY data_transacao DESC
      LIMIT 200
    `);

    const total = await db.query('SELECT COUNT(*)::int AS total FROM transacoes');

    return res.json({
      total: total.rows[0].total,
      transacoes: result.rows,
    });
  } catch (e) {
    console.error('transacoes error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// GET /api/admin/users — lista de utilizadores (alimenta o dropdown de
// quarentena no painel de demonstração; nunca expõe password_hash)
router.get('/users', auth, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT utilizador_id, nome, email, saldo FROM utilizadores ORDER BY utilizador_id'
    );
    return res.json(result.rows);
  } catch (e) {
    console.error('listar utilizadores error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

// POST /api/admin/quarantine/:userId — chama sp_QuarentenaUtilizador:
// põe todos os contadores do utilizador em MANUTENCAO e cancela as suas
// ofertas ATIVAS numa única transação
router.post('/quarantine/:userId', auth, async (req, res) => {
  const userId = parseInt(req.params.userId);
  if (isNaN(userId)) return errResponse(res, 400, 'userId inválido');

  try {
    await db.query('CALL sp_QuarentenaUtilizador($1)', [userId]);
    return res.json({ mensagem: 'Utilizador colocado em quarentena', utilizadorId: userId });
  } catch (e) {
    // A stored procedure lança exceções com mensagens descritivas
    console.error('quarentena error:', e.message);
    return errResponse(res, 400, e.message || 'Erro ao executar quarentena');
  }
});

module.exports = router;
