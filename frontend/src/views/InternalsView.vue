<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToastStore } from '../stores/toast';
import { adminApi, marketApi, apiError } from '../api/endpoints';
import BaseCard from '../components/ui/BaseCard.vue';
import BaseButton from '../components/ui/BaseButton.vue';
import BaseSelect from '../components/ui/BaseSelect.vue';
import StatusBadge from '../components/ui/StatusBadge.vue';
import EmptyState from '../components/ui/EmptyState.vue';
import { fmtDate, fmtDateTime } from '../utils/readings';

const { t, locale } = useI18n();
const toast = useToastStore();

const anomalies = ref(null);
const txData = ref(null);
const users = ref([]);
const quarantineTarget = ref('');
const matchLoading = ref(false);
const quarantineLoading = ref(false);

const userOptions = computed(() =>
  users.value.map((u) => ({ value: String(u.utilizador_id), label: `${u.nome} (${u.email})` }))
);

// Excertos reais de sql/logic.sql — mostrados como montra técnica
const sqlSnippets = {
  anomalies: `CREATE TRIGGER trg_DetectarAnomalias
AFTER INSERT ON Leituras
FOR EACH ROW EXECUTE FUNCTION fn_DetectarAnomalias();
-- temperatura > 80°C ou erro_codigo → contador MANUTENCAO`,
  matching: `CALL sp_MatchingEngine();
-- FIFO por antiguidade · melhor preço primeiro
-- fills parciais entre várias ofertas · FOR UPDATE`,
  quarantine: `CALL sp_QuarentenaUtilizador(p_utilizador_id);
-- contadores → MANUTENCAO + ofertas ATIVAS → CANCELADA
-- numa única transação`,
  partitions: `CREATE TABLE Leituras (...)
PARTITION BY RANGE (data_hora);
-- Leituras_2025_01 … Leituras_2026_12 (24 partições mensais)`,
};

onMounted(refresh);

async function refresh() {
  try {
    const [{ data: an }, { data: tx }, { data: us }] = await Promise.all([
      adminApi.anomalies(),
      adminApi.transactions(),
      adminApi.users(),
    ]);
    anomalies.value = an;
    txData.value = tx;
    users.value = us;
    if (us.length && !quarantineTarget.value) quarantineTarget.value = String(us[0].utilizador_id);
  } catch (e) {
    toast.error(apiError(e));
  }
}

async function runMatching() {
  matchLoading.value = true;
  const before = txData.value?.total ?? 0;
  try {
    await marketApi.runMatch();
    const { data } = await adminApi.transactions();
    txData.value = data;
    toast.push(t('internals.matchingDone', { delta: data.total - before }));
  } catch (e) {
    toast.error(apiError(e));
  } finally {
    matchLoading.value = false;
  }
}

async function quarantine() {
  const user = users.value.find((u) => String(u.utilizador_id) === quarantineTarget.value);
  if (!user || !confirm(t('internals.quarantineConfirm', { name: user.nome }))) return;

  quarantineLoading.value = true;
  try {
    await adminApi.quarantine(user.utilizador_id);
    toast.push(t('internals.quarantineDone'));
    await refresh();
  } catch (e) {
    toast.error(apiError(e));
  } finally {
    quarantineLoading.value = false;
  }
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-zinc-50">{{ t('internals.title') }}</h1>
      <p class="mt-2 max-w-3xl text-sm text-zinc-500 leading-relaxed">{{ t('internals.intro') }}</p>
    </div>

    <div class="grid gap-6 lg:grid-cols-2">
      <!-- Particionamento -->
      <BaseCard :title="t('internals.partitions')" :subtitle="t('internals.partitionsBlurb')">
        <pre class="overflow-x-auto rounded-lg border border-zinc-800 bg-zinc-950 p-3 font-mono text-xs text-volt/80">{{ sqlSnippets.partitions }}</pre>
      </BaseCard>

      <!-- Matching engine -->
      <BaseCard :title="t('internals.matching')" :subtitle="t('internals.matchingBlurb')">
        <pre class="mb-4 overflow-x-auto rounded-lg border border-zinc-800 bg-zinc-950 p-3 font-mono text-xs text-volt/80">{{ sqlSnippets.matching }}</pre>
        <BaseButton :loading="matchLoading" @click="runMatching">
          {{ t('internals.runMatching') }}
        </BaseButton>
      </BaseCard>

      <!-- Anomalias -->
      <BaseCard :title="t('internals.anomalies')" :subtitle="t('internals.anomaliesBlurb')">
        <pre class="mb-4 overflow-x-auto rounded-lg border border-zinc-800 bg-zinc-950 p-3 font-mono text-xs text-volt/80">{{ sqlSnippets.anomalies }}</pre>
        <template v-if="anomalies">
          <div class="mb-3 flex gap-4 text-sm">
            <span class="text-amber-400">{{ t('internals.anomalousReadings', { count: anomalies.totalAnomalias }) }}</span>
            <span class="text-red-400">{{ t('internals.metersInMaintenance', { count: anomalies.contadoresEmManutencao }) }}</span>
          </div>
          <div class="max-h-56 overflow-y-auto divide-y divide-zinc-800/60">
            <div
              v-for="reading in anomalies.leituras.slice(0, 20)"
              :key="reading.leitura_id"
              class="flex items-center justify-between py-2 text-xs"
            >
              <span class="text-zinc-500">
                #{{ reading.contador_id }} · {{ fmtDateTime(reading.data_hora, locale) }}
              </span>
              <span class="font-mono text-amber-400/90">
                {{ reading.dados_audit.erro_codigo || `${reading.dados_audit.temperatura}°C` }}
              </span>
            </div>
          </div>
        </template>
      </BaseCard>

      <!-- Quarentena -->
      <BaseCard :title="t('internals.quarantine')" :subtitle="t('internals.quarantineBlurb')">
        <pre class="mb-4 overflow-x-auto rounded-lg border border-zinc-800 bg-zinc-950 p-3 font-mono text-xs text-volt/80">{{ sqlSnippets.quarantine }}</pre>
        <div class="flex items-end gap-3">
          <div class="flex-1">
            <BaseSelect v-model="quarantineTarget" :label="t('internals.selectUser')" :options="userOptions" />
          </div>
          <BaseButton variant="danger" :loading="quarantineLoading" @click="quarantine">
            {{ t('internals.quarantineUser') }}
          </BaseButton>
        </div>
      </BaseCard>
    </div>

    <!-- Transações globais -->
    <BaseCard :title="t('internals.transactions')" :subtitle="t('internals.transactionsBlurb')">
      <template v-if="txData">
        <div class="mb-3 text-sm text-zinc-500">
          {{ t('internals.totalTransactions', { count: txData.total }) }}
        </div>
        <EmptyState v-if="!txData.transacoes.length">—</EmptyState>
        <div v-else class="max-h-96 overflow-y-auto overflow-x-auto">
          <table class="w-full text-sm">
            <thead class="sticky top-0 bg-zinc-900">
              <tr class="border-b border-zinc-800 text-left text-xs uppercase tracking-wide text-zinc-600">
                <th class="pb-2 pr-4">{{ t('common.id') }}</th>
                <th class="pb-2 pr-4">{{ t('activity.date') }}</th>
                <th class="pb-2 pr-4">{{ t('activity.type') }}</th>
                <th class="pb-2 pr-4 text-right">{{ t('activity.buyer') }}</th>
                <th class="pb-2 pr-4 text-right">{{ t('activity.seller') }}</th>
                <th class="pb-2 pr-4 text-right">kWh</th>
                <th class="pb-2 text-right">€</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-800/60">
              <tr v-for="tx in txData.transacoes" :key="tx.transacao_id">
                <td class="py-2 pr-4 font-mono text-xs text-zinc-600">#{{ tx.transacao_id }}</td>
                <td class="py-2 pr-4 text-zinc-400">{{ fmtDate(tx.data_transacao, locale) }}</td>
                <td class="py-2 pr-4"><StatusBadge :estado="tx.tipo_transacao" /></td>
                <td class="py-2 pr-4 text-right font-mono text-xs text-zinc-500">#{{ tx.comprador_id }}</td>
                <td class="py-2 pr-4 text-right font-mono text-xs text-zinc-500">#{{ tx.vendedor_id }}</td>
                <td class="py-2 pr-4 text-right tabular-nums text-zinc-300">{{ parseFloat(tx.quantidade_kwh).toFixed(2) }}</td>
                <td class="py-2 text-right tabular-nums text-volt">{{ parseFloat(tx.valor_total).toFixed(2) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
    </BaseCard>
  </div>
</template>
