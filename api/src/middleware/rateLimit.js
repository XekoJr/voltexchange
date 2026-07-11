const rateLimit = require('express-rate-limit');

// Login/registo expostos publicamente sem qualquer limite eram um alvo
// óbvio para força bruta/spam de contas — 10 tentativas por IP a cada 15 min
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { timestamp: new Date(), status: 429, erro: 'Demasiadas tentativas — tenta novamente mais tarde' },
});

// O depósito é dinheiro fictício, mas sem limite de frequência um script
// conseguiria inflacionar o saldo indefinidamente e distorcer a demo para
// todos os outros visitantes
const depositLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { timestamp: new Date(), status: 429, erro: 'Demasiados depósitos — tenta novamente mais tarde' },
});

module.exports = { authLimiter, depositLimiter };
