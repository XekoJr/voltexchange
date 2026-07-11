<script setup>
defineProps({
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
});
</script>

<template>
  <div class="rounded-xl border border-zinc-800 bg-zinc-900/60 p-5">
    <div v-if="title || $slots.header" class="mb-4 flex items-start justify-between gap-3">
      <div>
        <h3 v-if="title" class="font-semibold text-zinc-100">{{ title }}</h3>
        <p v-if="subtitle" class="mt-1 text-sm text-zinc-500 leading-relaxed">{{ subtitle }}</p>
      </div>
      <slot name="header" />
    </div>
    <slot />
  </div>
</template>
