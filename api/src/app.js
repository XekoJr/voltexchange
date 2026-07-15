require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const authRoutes = require('./routes/auth');
const meterRoutes = require('./routes/meters');
const marketRoutes = require('./routes/market');
const adminRoutes = require('./routes/admin');
const meRoutes = require('./routes/me');
const { authLimiter } = require('./middleware/rateLimit');

const app = express();

app.use(helmet());
// No CORS_ORIGIN set → fall back to the known production origin, never to
// "true" (which would accept any origin, including an attacker's site).
app.use(cors({ origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : 'https://volt.andrepacheco.pt' }));
app.use(express.json());

// Health check — public
app.get('/api/health', (req, res) => res.json({ status: 'ok', service: 'VoltExchange API' }));

// Routes
app.use('/api/auth', authLimiter, authRoutes);      // public — rate-limited (força bruta/spam)
app.use('/api/me', meRoutes);          // protected
app.use('/api/meters', meterRoutes);   // protected
app.use('/api/market', marketRoutes);  // protected
app.use('/api/admin', adminRoutes);    // protected

// 404
app.use((req, res) => res.status(404).json({ timestamp: new Date(), status: 404, erro: 'Rota não encontrada' }));

// Global error handler
app.use((err, req, res, _next) => {
  console.error(err);
  res.status(500).json({ timestamp: new Date(), status: 500, erro: 'Erro interno do servidor' });
});

if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => console.log(`VoltExchange API running on port ${PORT}`));
}

module.exports = app;
