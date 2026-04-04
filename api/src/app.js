require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const meterRoutes = require('./routes/meters');
const marketRoutes = require('./routes/market');
const adminRoutes = require('./routes/admin');

const app = express();

app.use(cors());
app.use(express.json());

// Health check — public
app.get('/api/health', (req, res) => res.json({ status: 'ok', service: 'VoltExchange API' }));

// Routes
app.use('/api/auth', authRoutes);      // public
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`VoltExchange API running on port ${PORT}`));

module.exports = app;
