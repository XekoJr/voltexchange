<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToastStore } from '../stores/toast';
import { metersApi, apiError } from '../api/endpoints';
import { downsample, partitionsForRange } from '../utils/readings';
import BaseCard from '../components/ui/BaseCard.vue';
import BaseButton from '../components/ui/BaseButton.vue';
import BaseInput from '../components/ui/BaseInput.vue';
import BaseSelect from '../components/ui/BaseSelect.vue';
import StatusBadge from '../components/ui/StatusBadge.vue';
import EmptyState from '../components/ui/EmptyState.vue';
import ReadingsChart from '../components/dashboard/ReadingsChart.vue';
import { fmtDate } from '../utils/readings';

const { t, locale } = useI18n();
const toast = useToastStore();

const meters = ref([]);
const selectedMeterId = ref('');

// Registo de leitura
const reading = ref({ kwh: '', temperatura: '', erroCodigo: '' });
const readingLoading = ref(false);

// Consulta por intervalo (demonstra partition pruning)
const today = new Date().toISOString().slice(0, 10);
const weekAgo = new Date(Date.now() - 7 * 24 * 3600 * 1000).toISOString().slice(0, 10);
const range = ref({ inicio: weekAgo, fim: today });
const queryLoading = ref(false);
const queryRows = ref(null);
const queryDownsampled = ref(false);
const queryPartitions = ref([]);
const rowCount = ref(0);

const meterOptions = computed(() =>
  meters.value.map((m) => ({ value: String(m.contador_id), label: `${m.numero_serie} (${m.regiao})` }))
);
const selectedMeter = computed(() =>
  meters.value.find((m) => String(m.contador_id) === selectedMeterId.value)
);
const chartRows = computed(() => (queryRows.value ? [...queryRows.value].reverse() : []));

onMounted(refresh);

async function refresh() {
  try {
    const { data } = await metersApi.list();
    meters.value = data;
    if (data.length && !selectedMeterId.value) selectedMeterId.value = String(data[0].contador_id);
  } catch (e) {
    toast.error(apiError(e));
  }
}

async function submitReading() {
  readingLoading.value = true;
  try {
    const dadosAudit = {};
    if (reading.value.temperatura) dadosAudit.temperatura = parseFloat(reading.value.temperatura);
    if (reading.value.erroCodigo) dadosAudit.erro_codigo = reading.value.erroCodigo;

    await metersApi.submitReading(selectedMeterId.value, parseFloat(reading.value.kwh), dadosAudit);

    // Se os dados disparam o trigger de anomalia, o contador mudou de estado
    const anomalous = dadosAudit.temperatura > 80 || dadosAudit.erro_codigo;
    toast.push(anomalous ? t('meters.anomalyTriggered') : t('meters.readingSubmitted'), anomalous ? 'error' : 'success');
    reading.value = { kwh: '', temperatura: '', erroCodigo: '' };
    await refresh();
  } catch (e) {
    toast.error(apiError(e));
  } finally {
    readingLoading.value = false;
  }
}

async function runQuery() {
  // Limita o intervalo a 3 meses — o seed tem ~500k leituras
  const start = new Date(range.value.inicio);
  const end = new Date(range.value.fim + 'T23:59:59');
  if (end - start > 92 * 24 * 3600 * 1000) {
    toast.error(t('meters.rangeCapped'));
    return;
  }

  queryLoading.value = true;
  try {
    const { data } = await metersApi.readings(selectedMeterId.value, start.toISOString(), end.toISOString());
    rowCount.value = data.length;
    const result = downsample(data);
    queryRows.value = result.rows;
    queryDownsampled.value = result.downsampled;
    queryPartitions.value = partitionsForRange(start, end);
  } catch (e) {
    toast.error(apiError(e));
  } finally {
    queryLoading.value = false;
  }
}
</script>

<template>
  <div class="space-y-6">
    <h1 class="text-2xl font-bold text-zinc-50">{{ t('meters.title') }}</h1>

    <!-- Lista de contadores -->
    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <BaseCard v-for="meter in meters" :key="meter.contador_id">
        <div class="flex items-start justify-between">
          <div>
            <div class="font-mono text-sm text-zinc-100">{{ meter.numero_serie }}</div>
            <div class="mt-1 text-xs text-zinc-500">
              {{ meter.regiao }} · {{ t('meters.installed') }} {{ fmtDate(meter.data_instalacao, locale) }}
            </div>
          </div>
          <StatusBadge :estado="meter.estado" />
        </div>
      </BaseCard>
      <EmptyState v-if="!meters.length" class="sm:col-span-2 lg:col-span-3">
        {{ t('dashboard.noMeters') }}
      </EmptyState>
    </div>

    <div v-if="meters.length" class="grid gap-6 lg:grid-cols-3">
      <!-- Registar leitura -->
      <BaseCard :title="t('meters.submitReading')">
        <form class="space-y-3" @submit.prevent="submitReading">
          <BaseSelect v-model="selectedMeterId" :label="t('meters.selectMeter')" :options="meterOptions" />
          <BaseInput v-model="reading.kwh" :label="t('meters.kwh')" type="number" min="0.001" step="0.001" required />
          <BaseInput v-model="reading.temperatura" :label="t('meters.temperature')" type="number" step="0.1" />
          <BaseInput v-model="reading.erroCodigo" :label="t('meters.errorCode')" placeholder="ERR_CAL" />
          <p class="rounded-lg border border-zinc-800 bg-zinc-900 px-3 py-2 text-xs text-zinc-500 leading-relaxed">
            {{ t('meters.anomalyHint') }}
          </p>
          <BaseButton type="submit" class="w-full" :loading="readingLoading">
            {{ t('meters.submitReading') }}
          </BaseButton>
        </form>
      </BaseCard>

      <!-- Consulta por intervalo -->
      <BaseCard :title="t('meters.queryReadings')" class="lg:col-span-2">
        <form class="mb-4 flex flex-wrap items-end gap-3" @submit.prevent="runQuery">
          <div class="w-40"><BaseInput v-model="range.inicio" :label="t('meters.from')" type="date" required /></div>
          <div class="w-40"><BaseInput v-model="range.fim" :label="t('meters.to')" type="date" required /></div>
          <BaseButton type="submit" :loading="queryLoading">{{ t('meters.run') }}</BaseButton>
        </form>

        <template v-if="queryRows !== null">
          <div class="mb-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs">
            <span class="text-zinc-500">
              {{ t('meters.rows', { count: rowCount }) }}<span v-if="queryDownsampled"> · {{ t('meters.chartDownsampled') }}</span>
            </span>
            <span class="font-mono text-volt/80">
              {{ t('meters.partitionHit', { partitions: queryPartitions.join(', ') }) }}
            </span>
          </div>
          <EmptyState v-if="!queryRows.length">{{ t('meters.noReadings') }}</EmptyState>
          <ReadingsChart v-else :readings="chartRows" />
        </template>
      </BaseCard>
    </div>
  </div>
</template>
