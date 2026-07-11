<script setup>
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAuthStore } from '../../stores/auth';
import { useUserStore } from '../../stores/user';
import LanguageToggle from './LanguageToggle.vue';

const { t } = useI18n();
const router = useRouter();
const auth = useAuthStore();
const user = useUserStore();

onMounted(() => {
  if (!user.profile) user.fetchProfile();
});

const nav = [
  { name: 'dashboard', label: 'nav.dashboard', icon: 'M3 12l9-9 9 9M5 10v10h5v-6h4v6h5V10' },
  { name: 'market', label: 'nav.market', icon: 'M3 3v18h18M7 15l4-4 3 3 5-6' },
  { name: 'activity', label: 'nav.activity', icon: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0' },
  { name: 'meters', label: 'nav.meters', icon: 'M13 2L3 14h9l-1 8 10-12h-9l1-8z' },
  { name: 'internals', label: 'nav.internals', icon: 'M4 7c0-1.7 3.6-3 8-3s8 1.3 8 3-3.6 3-8 3-8-1.3-8-3zm0 0v10c0 1.7 3.6 3 8 3s8-1.3 8-3V7M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3' },
];

function logout() {
  auth.logout();
  router.push({ name: 'login' });
}
</script>

<template>
  <aside class="w-60 shrink-0 border-r border-zinc-800 bg-zinc-950 flex flex-col sticky top-0 h-screen">
    <div class="px-5 py-6 flex items-center gap-2.5">
      <svg viewBox="0 0 24 24" class="h-7 w-7 text-volt" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
      </svg>
      <div>
        <div class="font-bold text-zinc-50 leading-tight">VoltExchange</div>
        <div class="text-[11px] text-zinc-500">{{ t('app.tagline') }}</div>
      </div>
    </div>

    <nav class="flex-1 px-3 space-y-1">
      <router-link
        v-for="item in nav"
        :key="item.name"
        :to="{ name: item.name }"
        class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm text-zinc-400 hover:text-zinc-100 hover:bg-zinc-900 transition-colors"
        active-class="!text-volt bg-zinc-900"
      >
        <svg viewBox="0 0 24 24" class="h-4 w-4 shrink-0" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path :d="item.icon" />
        </svg>
        {{ t(item.label) }}
      </router-link>
    </nav>

    <div class="p-4 border-t border-zinc-800 space-y-3">
      <div v-if="user.profile" class="flex items-baseline justify-between text-sm">
        <span class="text-zinc-500 truncate">{{ auth.user?.nome }}</span>
        <span class="font-semibold text-volt tabular-nums">€{{ user.saldo.toFixed(2) }}</span>
      </div>
      <div class="flex items-center justify-between">
        <LanguageToggle />
        <button
          class="text-sm text-zinc-500 hover:text-red-400 transition-colors"
          @click="logout"
        >
          {{ t('nav.logout') }}
        </button>
      </div>
    </div>
  </aside>
</template>
