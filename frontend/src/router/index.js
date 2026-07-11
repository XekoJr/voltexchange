import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../stores/auth';

const routes = [
  { path: '/', redirect: '/dashboard' },
  { path: '/login', name: 'login', component: () => import('../views/LoginView.vue'), meta: { public: true } },
  { path: '/register', name: 'register', component: () => import('../views/RegisterView.vue'), meta: { public: true } },
  { path: '/dashboard', name: 'dashboard', component: () => import('../views/DashboardView.vue') },
  { path: '/market', name: 'market', component: () => import('../views/MarketView.vue') },
  { path: '/activity', name: 'activity', component: () => import('../views/ActivityView.vue') },
  { path: '/meters', name: 'meters', component: () => import('../views/MetersView.vue') },
  { path: '/internals', name: 'internals', component: () => import('../views/InternalsView.vue') },
  { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach((to) => {
  const auth = useAuthStore();
  if (!to.meta.public && !auth.isAuthenticated) return { name: 'login' };
  if (to.meta.public && auth.isAuthenticated) return { name: 'dashboard' };
});

export default router;
