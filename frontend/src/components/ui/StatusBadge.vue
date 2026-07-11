<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  estado: { type: String, required: true },
});

const { t } = useI18n();

// Mapa estado→cor partilhado por ofertas, ordens, contadores e transações
const palette = {
  ATIVA: 'bg-emerald-950/60 text-emerald-400 border-emerald-900',
  ATIVO: 'bg-emerald-950/60 text-emerald-400 border-emerald-900',
  PENDENTE: 'bg-amber-950/60 text-amber-400 border-amber-900',
  VENDIDA: 'bg-sky-950/60 text-sky-400 border-sky-900',
  CONCLUIDA: 'bg-sky-950/60 text-sky-400 border-sky-900',
  MATCHED: 'bg-violet-950/60 text-violet-400 border-violet-900',
  DIRETA: 'bg-sky-950/60 text-sky-400 border-sky-900',
  CANCELADA: 'bg-zinc-800 text-zinc-500 border-zinc-700',
  MANUTENCAO: 'bg-red-950/60 text-red-400 border-red-900',
};

const cls = computed(() => palette[props.estado] || 'bg-zinc-800 text-zinc-400 border-zinc-700');
const label = computed(() => t(`common.estados.${props.estado}`, props.estado));
</script>

<template>
  <span class="inline-block rounded-full border px-2 py-0.5 text-xs font-medium" :class="cls">
    {{ label }}
  </span>
</template>
