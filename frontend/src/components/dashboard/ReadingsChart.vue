<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { Line } from 'vue-chartjs';
import {
  Chart as ChartJS,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  Tooltip,
  Filler,
} from 'chart.js';
import { fmtDateTime } from '../../utils/readings';

ChartJS.register(LineElement, PointElement, LinearScale, CategoryScale, Tooltip, Filler);

const props = defineProps({
  // Linhas já ordenadas por data_hora ASC (e possivelmente downsampled)
  readings: { type: Array, required: true },
});

const { locale } = useI18n();

const chartData = computed(() => ({
  labels: props.readings.map((r) => fmtDateTime(r.data_hora, locale.value)),
  datasets: [
    {
      data: props.readings.map((r) => parseFloat(r.kwh_leitura)),
      borderColor: '#22d3ee',
      backgroundColor: 'rgba(34, 211, 238, 0.08)',
      borderWidth: 1.5,
      pointRadius: 0,
      pointHitRadius: 8,
      fill: true,
      tension: 0.3,
    },
  ],
}));

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    tooltip: {
      backgroundColor: '#18181b',
      borderColor: '#3f3f46',
      borderWidth: 1,
      titleColor: '#e4e4e7',
      bodyColor: '#22d3ee',
      displayColors: false,
      callbacks: { label: (ctx) => `${ctx.parsed.y.toFixed(3)} kWh` },
    },
  },
  scales: {
    x: {
      ticks: { color: '#52525b', maxTicksLimit: 8, maxRotation: 0 },
      grid: { color: 'rgba(63, 63, 70, 0.25)' },
    },
    y: {
      ticks: { color: '#52525b' },
      grid: { color: 'rgba(63, 63, 70, 0.25)' },
    },
  },
};
</script>

<template>
  <div class="h-64">
    <Line :data="chartData" :options="chartOptions" />
  </div>
</template>
