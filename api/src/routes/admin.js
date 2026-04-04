const router = require('express').Router();
const db = require('../config/database');
const auth = require('../middleware/auth');

const errResponse = (res, status, msg) =>
  res.status(status).json({ timestamp: new Date(), status, erro: msg });

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
    `);

    return res.json({
      total: result.rows.length,
      transacoes: result.rows,
    });
  } catch (e) {
    console.error('transacoes error:', e.message);
    return errResponse(res, 500, 'Erro interno do servidor');
  }
});

module.exports = router;
