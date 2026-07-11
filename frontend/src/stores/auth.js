import { defineStore } from 'pinia';
import { authApi } from '../api/endpoints';

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('vx_token') || null,
    user: JSON.parse(localStorage.getItem('vx_user') || 'null'),
  }),
  getters: {
    isAuthenticated: (state) => !!state.token,
  },
  actions: {
    persist(data) {
      this.token = data.token;
      this.user = { nome: data.nome, email: data.email };
      localStorage.setItem('vx_token', data.token);
      localStorage.setItem('vx_user', JSON.stringify(this.user));
    },
    async login(email, password) {
      const { data } = await authApi.login(email, password);
      this.persist(data);
    },
    async register(nome, email, password) {
      const { data } = await authApi.register(nome, email, password);
      this.persist(data);
    },
    logout() {
      this.token = null;
      this.user = null;
      localStorage.removeItem('vx_token');
      localStorage.removeItem('vx_user');
    },
  },
});
