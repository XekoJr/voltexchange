<script setup>
defineProps({
  label: { type: String, default: '' },
  modelValue: { type: [String, Number], default: '' },
  type: { type: String, default: 'text' },
  placeholder: { type: String, default: '' },
  hint: { type: String, default: '' },
});
defineEmits(['update:modelValue']);
</script>

<template>
  <label class="block">
    <span v-if="label" class="mb-1.5 block text-sm text-zinc-400">{{ label }}</span>
    <input
      :type="type"
      :value="modelValue"
      :placeholder="placeholder"
      v-bind="$attrs"
      class="w-full rounded-lg border border-zinc-700 bg-zinc-900 px-3 py-2 text-sm text-zinc-100 placeholder-zinc-600 outline-none transition-colors focus:border-volt/60 tabular-nums"
      @input="$emit('update:modelValue', $event.target.value)"
    />
    <span v-if="hint" class="mt-1 block text-xs text-zinc-600">{{ hint }}</span>
  </label>
</template>
