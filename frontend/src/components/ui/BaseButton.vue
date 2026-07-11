<script setup>
defineProps({
  variant: { type: String, default: 'primary' }, // primary | ghost | danger
  loading: { type: Boolean, default: false },
  type: { type: String, default: 'button' },
});

const classes = {
  primary:
    'bg-volt/10 text-volt border border-volt/40 hover:bg-volt/20 hover:border-volt/70',
  ghost:
    'bg-transparent text-zinc-400 border border-zinc-700 hover:text-zinc-100 hover:border-zinc-500',
  danger:
    'bg-red-950/40 text-red-400 border border-red-900 hover:bg-red-950/70 hover:border-red-700',
};
</script>

<template>
  <button
    :type="type"
    :disabled="loading || $attrs.disabled"
    class="inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2 text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
    :class="classes[variant]"
  >
    <svg v-if="loading" class="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
    </svg>
    <slot />
  </button>
</template>
