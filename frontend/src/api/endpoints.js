import client from './client';

// Uma função fina por rota da API — mantém os componentes livres de URLs

export const authApi = {
  register: (nome, email, password) => client.post('/auth/register', { nome, email, password }),
  login: (email, password) => client.post('/auth/login', { email, password }),
};

export const meApi = {
  profile: () => client.get('/me'),
  deposit: (valor) => client.post('/me/deposit', { valor }),
  offers: (estado) => client.get('/me/offers', { params: estado ? { estado } : {} }),
  orders: (estado) => client.get('/me/orders', { params: estado ? { estado } : {} }),
  transactions: (papel) => client.get('/me/transactions', { params: papel ? { papel } : {} }),
};

export const metersApi = {
  list: () => client.get('/meters'),
  submitReading: (contadorId, kwhLeitura, dadosAudit) =>
    client.post(`/meters/${contadorId}/readings`, { kwhLeitura, dadosAudit }),
  readings: (contadorId, inicio, fim) =>
    client.get(`/meters/${contadorId}/readings`, { params: { inicio, fim } }),
};

export const marketApi = {
  offers: (regiao) => client.get('/market/offers', { params: regiao ? { regiao } : {} }),
  postOffer: (quantidadeKwh, precoUnitario, regiao) =>
    client.post('/market/offers', { quantidadeKwh, precoUnitario, regiao: regiao || undefined }),
  buy: (ofertaId, quantidade) => client.post(`/market/offers/${ofertaId}/buy`, { quantidade }),
  postOrder: (quantidadeKwh, precoMaximo, regiao) =>
    client.post('/market/order', { quantidadeKwh, precoMaximo, regiao: regiao || undefined }),
  cancelOffer: (id) => client.patch(`/market/offers/${id}/cancel`),
  cancelOrder: (id) => client.patch(`/market/order/${id}/cancel`),
  runMatch: () => client.post('/market/match'),
};

export const adminApi = {
  anomalies: () => client.get('/admin/anomalies'),
  transactions: () => client.get('/admin/transactions'),
  users: () => client.get('/admin/users'),
  quarantine: (userId) => client.post(`/admin/quarantine/${userId}`),
};

// Extrai a mensagem do envelope de erro consistente da API ({erro})
export const apiError = (e) =>
  e.response?.data?.erro || e.message || 'Unexpected error';
