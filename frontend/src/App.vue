<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useAuthStore } from './stores/auth';
import AppSidebar from './components/layout/AppSidebar.vue';
import ToastHost from './components/ui/ToastHost.vue';

const route = useRoute();
const auth = useAuthStore();
const showShell = computed(() => auth.isAuthenticated && !route.meta.public);
</script>

<template>
  <div class="min-h-screen">
    <div v-if="showShell" class="flex min-h-screen">
      <AppSidebar />
      <main class="flex-1 min-w-0 p-6 lg:p-8">
        <router-view />
      </main>
    </div>
    <router-view v-else />
    <ToastHost />
  </div>
</template>
