<script setup>
import { useToastStore } from '../../stores/toast';

const toastStore = useToastStore();
</script>

<template>
  <div class="fixed bottom-4 right-4 z-50 flex flex-col gap-2 max-w-sm">
    <TransitionGroup name="toast">
      <div
        v-for="toast in toastStore.toasts"
        :key="toast.id"
        class="rounded-lg border px-4 py-3 text-sm shadow-lg backdrop-blur cursor-pointer"
        :class="
          toast.type === 'error'
            ? 'bg-red-950/90 border-red-800 text-red-200'
            : 'bg-zinc-900/90 border-volt/40 text-zinc-100'
        "
        @click="toastStore.dismiss(toast.id)"
      >
        {{ toast.message }}
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.25s ease;
}
.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(8px);
}
</style>
