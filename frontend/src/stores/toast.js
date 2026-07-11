import { defineStore } from 'pinia';

let nextId = 1;

// Notificações efémeras (sucesso/erro) usadas em toda a app
export const useToastStore = defineStore('toast', {
  state: () => ({ toasts: [] }),
  actions: {
    push(message, type = 'success') {
      const id = nextId++;
      this.toasts.push({ id, message, type });
      setTimeout(() => this.dismiss(id), 5000);
    },
    error(message) {
      this.push(message, 'error');
    },
    dismiss(id) {
      this.toasts = this.toasts.filter((t) => t.id !== id);
    },
  },
});
