import { defineStore } from 'pinia';
import { meApi } from '../api/endpoints';

export const useUserStore = defineStore('user', {
  state: () => ({
    profile: null,
    loading: false,
  }),
  getters: {
    saldo: (state) => (state.profile ? parseFloat(state.profile.saldo) : 0),
  },
  actions: {
    async fetchProfile() {
      this.loading = true;
      try {
        const { data } = await meApi.profile();
        this.profile = data;
      } finally {
        this.loading = false;
      }
    },
    async deposit(valor) {
      const { data } = await meApi.deposit(valor);
      if (this.profile) this.profile.saldo = data.saldo;
      return data;
    },
  },
});
