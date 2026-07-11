<script setup>
import { useI18n } from 'vue-i18n';
import { setLocale } from '../../i18n';

const { locale } = useI18n();

function toggle(lang) {
  setLocale(lang);
}
</script>

<template>
  <div class="flex items-center gap-1 text-xs">
    <button
      v-for="lang in ['en', 'pt']"
      :key="lang"
      class="rounded px-1.5 py-0.5 uppercase transition-colors"
      :class="locale === lang ? 'bg-zinc-800 text-volt font-semibold' : 'text-zinc-500 hover:text-zinc-300'"
      @click="toggle(lang)"
    >
      {{ lang }}
    </button>
  </div>
</template>
