<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAuthStore } from '../stores/auth';
import { apiError } from '../api/endpoints';
import BaseInput from '../components/ui/BaseInput.vue';
import BaseButton from '../components/ui/BaseButton.vue';
import LanguageToggle from '../components/layout/LanguageToggle.vue';

const { t } = useI18n();
const router = useRouter();
const auth = useAuthStore();

const email = ref('');
const password = ref('');
const loading = ref(false);
const error = ref('');

async function submit() {
  loading.value = true;
  error.value = '';
  try {
    await auth.login(email.value, password.value);
    router.push({ name: 'dashboard' });
  } catch (e) {
    error.value = apiError(e);
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <div class="flex min-h-screen items-center justify-center p-4">
    <div class="w-full max-w-sm">
      <div class="mb-8 text-center">
        <svg viewBox="0 0 24 24" class="mx-auto h-10 w-10 text-volt" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
        </svg>
        <h1 class="mt-3 text-2xl font-bold text-zinc-50">{{ t('auth.loginTitle') }}</h1>
        <p class="mt-1 text-sm text-zinc-500">{{ t('auth.loginSubtitle') }}</p>
      </div>

      <form class="space-y-4" @submit.prevent="submit">
        <BaseInput v-model="email" :label="t('auth.email')" type="email" autocomplete="email" required />
        <BaseInput v-model="password" :label="t('auth.password')" type="password" autocomplete="current-password" required />

        <p v-if="error" class="rounded-lg border border-red-900 bg-red-950/40 px-3 py-2 text-sm text-red-400">
          {{ error }}
        </p>

        <BaseButton type="submit" class="w-full" :loading="loading">
          {{ loading ? t('auth.signingIn') : t('auth.signIn') }}
        </BaseButton>
      </form>

      <p class="mt-6 text-center text-sm text-zinc-500">
        {{ t('auth.noAccount') }}
        <router-link :to="{ name: 'register' }" class="text-volt hover:underline">{{ t('auth.signUp') }}</router-link>
      </p>
      <p class="mt-4 rounded-lg border border-volt/30 bg-volt/10 px-3 py-2 text-center text-xs font-medium text-volt">
        {{ t('auth.demoHint') }}
      </p>
      <div class="mt-4 flex justify-center"><LanguageToggle /></div>
    </div>
  </div>
</template>
