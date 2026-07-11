import axios from 'axios';

// URL do backend em runtime (window.APP_CONFIG vem de /config.js, injetado
// pelo container nginx no arranque) — a mesma imagem serve qualquer ambiente
const runtimeUrl = window.APP_CONFIG?.API_URL;
const baseURL =
  runtimeUrl && !runtimeUrl.startsWith('${') ? runtimeUrl : 'http://localhost:3000';

const client = axios.create({
  baseURL: `${baseURL}/api`,
  headers: { 'Content-Type': 'application/json' },
});

client.interceptors.request.use((config) => {
  const token = localStorage.getItem('vx_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

client.interceptors.response.use(
  (response) => response,
  (error) => {
    // Token expirado/inválido → limpa a sessão e volta ao login
    if (error.response?.status === 401 && !error.config.url.includes('/auth/')) {
      localStorage.removeItem('vx_token');
      localStorage.removeItem('vx_user');
      if (window.location.pathname !== '/login') window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default client;
