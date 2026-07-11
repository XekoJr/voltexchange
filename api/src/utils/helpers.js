const db = require('../config/database');

// Envelope de erro consistente em toda a API
const errResponse = (res, status, msg) =>
  res.status(status).json({ timestamp: new Date(), status, erro: msg });

// O JWT só transporta o email (sub) — resolve o utilizador_id a partir dele
const getUserId = async (email) => {
  const r = await db.query('SELECT utilizador_id FROM utilizadores WHERE email = $1', [email]);
  return r.rows.length ? r.rows[0].utilizador_id : null;
};

module.exports = { errResponse, getUserId };
