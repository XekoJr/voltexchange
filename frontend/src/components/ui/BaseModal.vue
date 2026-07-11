<script setup>
defineProps({
  open: { type: Boolean, required: true },
  title: { type: String, default: '' },
});
defineEmits(['close']);
</script>

<template>
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="open"
        class="fixed inset-0 z-40 flex items-center justify-center bg-black/70 p-4"
        @click.self="$emit('close')"
      >
        <div class="w-full max-w-md rounded-xl border border-zinc-800 bg-zinc-900 p-6 shadow-2xl">
          <div class="mb-4 flex items-center justify-between">
            <h3 class="font-semibold text-zinc-100">{{ title }}</h3>
            <button class="text-zinc-500 hover:text-zinc-200" @click="$emit('close')">✕</button>
          </div>
          <slot />
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
</style>
