const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ timestamp: new Date(), status: 401, erro: 'Token não fornecido' });
  }
  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = { email: payload.sub };
    next();
  } catch {
    return res.status(401).json({ timestamp: new Date(), status: 401, erro: 'Token inválido ou expirado' });
  }
};
