<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useUserStore } from '../stores/user';
import { useToastStore } from '../stores/toast';
import { metersApi, meApi, apiError } from '../api/endpoints';
import { downsample, partitionsForRange, fmtDate } from '../utils/readings';
import BaseCard from '../components/ui/BaseCard.vue';
import BaseButton from '../components/ui/BaseButton.vue';
import BaseInput from '../components/ui/BaseInput.vue';
import BaseModal from '../components/ui/BaseModal.vue';
import StatusBadge from '../components/ui/StatusBadge.vue';
import EmptyState from '../components/ui/EmptyState.vue';
import ReadingsChart from '../components/dashboard/ReadingsChart.vue';

const { t, locale } = useI18n();
const user = useUserStore();
const toast = useToastStore();

const meters = ref([]);
const readings = ref([]);
const readingsDownsampled = ref(false);
const readingsPartitions = ref([]);
const selectedMeter = ref(null);
const transactions = ref([]);

const depositOpen = ref(false);
const depositValue = ref('100');
const depositLoading = ref(false);

const chartRows = computed(() => [...readings.value].reverse());

onMounted(async () => {
  user.fetchProfile();
  try {
    const [{ data: m }, { data: tx }] = await Promise.all([metersApi.list(), meApi.transactions()]);
    meters.value = m;
    transactions.value = tx.slice(0, 6);
    if (m.length) selectMeter(m[0]);
  } catch (e) {
    toast.error(apiError(e));
  }
});

async function selectMeter(meter) {
  selectedMeter.value = meter;
  const fim = new Date();
  const inicio = new Date(fim.getTime() - 7 * 24 * 3600 * 1000);
  try {
    const { data } = await metersApi.readings(meter.contador_id, inicio.toISOString(), fim.toISOString());
    const result = downsample(data);
    readings.value = result.rows;
    readingsDownsampled.value = result.downsampled;
    readingsPartitions.value = partitionsForRange(inicio, fim);
  } catch (e) {
    toast.error(apiError(e));
  }
}

async function submitDeposit() {
  depositLoading.value = true;
  try {
    await user.deposit(parseFloat(depositValue.value));
    depositOpen.value = false;
    toast.push(t('dashboard.depositDemo') + ' ✓');
  } catch (e) {
    toast.error(apiError(e));
  } finally {
    depositLoading.value = false;
  }
}
</script>

<template>
  <div class="space-y-6">
    <h1 class="text-2xl font-bold text-zinc-50">{{ t('dashboard.title') }}</h1>

    <div class="grid gap-6 lg:grid-cols-3">
      <!-- Saldo -->
      <BaseCard :title="t('dashboard.balance')">
        <template #header>
          <BaseButton @click="depositOpen = true">{{ t('dashboard.deposit') }}</BaseButton>
        </template>
        <div class="text-4xl font-bold text-volt tabular-nums">
          €{{ user.saldo.toFixed(2) }}
        </div>
        <p v-if="user.profile" class="mt-2 text-xs text-zinc-600">
          {{ user.profile.email }}
        </p>
      </BaseCard>

      <!-- Contadores -->
      <BaseCard :title="t('dashboard.meters')" class="lg:col-span-2">
        <EmptyState v-if="!meters.length">{{ t('dashboard.noMeters') }}</EmptyState>
        <div v-else class="flex flex-wrap gap-2">
          <button
            v-for="meter in meters"
            :key="meter.contador_id"
            class="flex items-center gap-2 rounded-lg border px-3 py-2 text-sm transition-colors"
            :class="
              selectedMeter?.contador_id === meter.contador_id
                ? 'border-volt/60 bg-volt/10 text-zinc-100'
                : 'border-zinc-700 text-zinc-400 hover:border-zinc-500'
            "
            @click="selectMeter(meter)"
          >
            <span class="font-mono text-xs">{{ meter.numero_serie }}</span>
            <StatusBadge :estado="meter.estado" />
          </button>
        </div>
      </BaseCard>
    </div>

    <!-- Consumo -->
    <BaseCard v-if="selectedMeter" :title="`${t('dashboard.consumption')} — ${selectedMeter.numero_serie}`">
      <template #header>
        <div class="text-right text-xs text-zinc-600">
          <div>{{ t('meters.rows', { count: readings.length }) }}<span v-if="readingsDownsampled"> · {{ t('meters.chartDownsampled') }}</span></div>
          <div class="mt-0.5 font-mono text-volt/70">{{ readingsPartitions.join(' · ') }}</div>
        </div>
      </template>
      <EmptyState v-if="!readings.length">{{ t('meters.noReadings') }}</EmptyState>
      <ReadingsChart v-else :readings="chartRows" />
    </BaseCard>

    <!-- Transações recentes -->
    <BaseCard :title="t('dashboard.recentTransactions')">
      <template #header>
        <router-link :to="{ name: 'activity' }" class="text-sm text-volt hover:underline">
          {{ t('dashboard.viewAll') }}
        </router-link>
      </template>
      <EmptyState v-if="!transactions.length">{{ t('activity.noTransactions') }}</EmptyState>
      <div v-else class="divide-y divide-zinc-800">
        <div
          v-for="tx in transactions"
          :key="tx.transacao_id"
          class="flex items-center justify-between py-2.5 text-sm"
        >
          <div class="flex items-center gap-3">
            <StatusBadge :estado="tx.tipo_transacao" />
            <span class="text-zinc-500">{{ fmtDate(tx.data_transacao, locale) }}</span>
          </div>
          <div class="tabular-nums">
            <span class="text-zinc-400">{{ parseFloat(tx.quantidade_kwh).toFixed(2) }} kWh</span>
            <span class="ml-3 font-medium" :class="tx.is_comprador ? 'text-red-400' : 'text-emerald-400'">
              {{ tx.is_comprador ? '−' : '+' }}€{{ parseFloat(tx.valor_total).toFixed(2) }}
            </span>
          </div>
        </div>
      </div>
    </BaseCard>

    <!-- Modal de depósito (demo) -->
    <BaseModal :open="depositOpen" :title="t('dashboard.depositDemo')" @close="depositOpen = false">
      <p class="mb-4 rounded-lg border border-amber-900 bg-amber-950/30 px-3 py-2 text-xs text-amber-400">
        {{ t('dashboard.depositNote') }}
      </p>
      <form class="space-y-4" @submit.prevent="submitDeposit">
        <BaseInput v-model="depositValue" :label="t('dashboard.amount')" type="number" min="1" max="10000" step="0.01" required />
        <BaseButton type="submit" class="w-full" :loading="depositLoading">
          {{ t('dashboard.confirmDeposit') }}
        </BaseButton>
      </form>
    </BaseModal>
  </div>
</template>
