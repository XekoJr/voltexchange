<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToastStore } from '../stores/toast';
import { meApi, marketApi, apiError } from '../api/endpoints';
import BaseCard from '../components/ui/BaseCard.vue';
import BaseButton from '../components/ui/BaseButton.vue';
import StatusBadge from '../components/ui/StatusBadge.vue';
import EmptyState from '../components/ui/EmptyState.vue';
import { fmtDate } from '../utils/readings';

const { t, locale } = useI18n();
const toast = useToastStore();

const offers = ref([]);
const orders = ref([]);
const transactions = ref([]);
const papel = ref('');

const papelOptions = computed(() => [
  { value: '', label: t('activity.all') },
  { value: 'comprador', label: t('activity.asBuyer') },
  { value: 'vendedor', label: t('activity.asSeller') },
]);

onMounted(refresh);

async function refresh() {
  try {
    const [{ data: of }, { data: or }, { data: tx }] = await Promise.all([
      meApi.offers(),
      meApi.orders(),
      meApi.transactions(papel.value || undefined),
    ]);
    offers.value = of;
    orders.value = or;
    transactions.value = tx;
  } catch (e) {
    toast.error(apiError(e));
  }
}

async function fetchTransactions() {
  try {
    const { data } = await meApi.transactions(papel.value || undefined);
    transactions.value = data;
  } catch (e) {
    toast.error(apiError(e));
  }
}

async function cancelOffer(offer) {
  if (!confirm(t('activity.cancelOfferConfirm'))) return;
  try {
    await marketApi.cancelOffer(offer.oferta_id);
    toast.push(t('activity.cancelled'));
    refresh();
  } catch (e) {
    toast.error(apiError(e));
  }
}

async function cancelOrder(order) {
  if (!confirm(t('activity.cancelOrderConfirm'))) return;
  try {
    await marketApi.cancelOrder(order.ordem_id);
    toast.push(t('activity.cancelled'));
    refresh();
  } catch (e) {
    toast.error(apiError(e));
  }
}
</script>

<template>
  <div class="space-y-6">
    <h1 class="text-2xl font-bold text-zinc-50">{{ t('activity.title') }}</h1>

    <div class="grid gap-6 lg:grid-cols-2">
      <!-- Ofertas -->
      <BaseCard :title="t('activity.myOffers')">
        <EmptyState v-if="!offers.length">{{ t('activity.noOffers') }}</EmptyState>
        <div v-else class="max-h-80 overflow-y-auto divide-y divide-zinc-800/60">
          <div v-for="offer in offers" :key="offer.oferta_id" class="flex items-center justify-between py-2.5 text-sm">
            <div class="flex items-center gap-3">
              <span class="font-mono text-xs text-zinc-600">#{{ offer.oferta_id }}</span>
              <StatusBadge :estado="offer.estado" />
              <span class="text-zinc-500">{{ offer.regiao || '—' }}</span>
            </div>
            <div class="flex items-center gap-3 tabular-nums">
              <span class="text-zinc-300">{{ parseFloat(offer.quantidade_kwh).toFixed(2) }} kWh</span>
              <span class="text-volt">€{{ parseFloat(offer.preco_unitario).toFixed(4) }}</span>
              <BaseButton
                v-if="offer.estado === 'ATIVA'"
                variant="danger"
                class="!px-2.5 !py-1 !text-xs"
                @click="cancelOffer(offer)"
              >
                {{ t('activity.cancel') }}
              </BaseButton>
            </div>
          </div>
        </div>
      </BaseCard>

      <!-- Ordens -->
      <BaseCard :title="t('activity.myOrders')">
        <EmptyState v-if="!orders.length">{{ t('activity.noOrders') }}</EmptyState>
        <div v-else class="max-h-80 overflow-y-auto divide-y divide-zinc-800/60">
          <div v-for="order in orders" :key="order.ordem_id" class="flex items-center justify-between py-2.5 text-sm">
            <div class="flex items-center gap-3">
              <span class="font-mono text-xs text-zinc-600">#{{ order.ordem_id }}</span>
              <StatusBadge :estado="order.estado" />
              <span class="text-zinc-500">{{ order.regiao || '—' }}</span>
            </div>
            <div class="flex items-center gap-3 tabular-nums">
              <span class="text-zinc-300">{{ parseFloat(order.quantidade_kwh).toFixed(2) }} kWh</span>
              <span class="text-volt">≤ €{{ parseFloat(order.preco_maximo).toFixed(4) }}</span>
              <BaseButton
                v-if="order.estado === 'PENDENTE'"
                variant="danger"
                class="!px-2.5 !py-1 !text-xs"
                @click="cancelOrder(order)"
              >
                {{ t('activity.cancel') }}
              </BaseButton>
            </div>
          </div>
        </div>
      </BaseCard>
    </div>

    <!-- Transações -->
    <BaseCard :title="t('activity.myTransactions')">
      <template #header>
        <div class="flex gap-1 text-xs">
          <button
            v-for="opt in papelOptions"
            :key="opt.value"
            class="rounded-lg border px-3 py-1.5 transition-colors"
            :class="papel === opt.value ? 'border-volt/60 bg-volt/10 text-volt' : 'border-zinc-700 text-zinc-500 hover:text-zinc-300'"
            @click="papel = opt.value; fetchTransactions()"
          >
            {{ opt.label }}
          </button>
        </div>
      </template>

      <EmptyState v-if="!transactions.length">{{ t('activity.noTransactions') }}</EmptyState>
      <div v-else class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-zinc-800 text-left text-xs uppercase tracking-wide text-zinc-600">
              <th class="pb-2 pr-4">{{ t('common.id') }}</th>
              <th class="pb-2 pr-4">{{ t('activity.date') }}</th>
              <th class="pb-2 pr-4">{{ t('activity.type') }}</th>
              <th class="pb-2 pr-4">{{ t('activity.role') }}</th>
              <th class="pb-2 pr-4 text-right">kWh</th>
              <th class="pb-2 text-right">€</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-800/60">
            <tr v-for="tx in transactions" :key="tx.transacao_id">
              <td class="py-2.5 pr-4 font-mono text-xs text-zinc-600">#{{ tx.transacao_id }}</td>
              <td class="py-2.5 pr-4 text-zinc-400">{{ fmtDate(tx.data_transacao, locale) }}</td>
              <td class="py-2.5 pr-4"><StatusBadge :estado="tx.tipo_transacao" /></td>
              <td class="py-2.5 pr-4 text-zinc-400">
                {{ tx.is_comprador ? t('activity.buyer') : t('activity.seller') }}
              </td>
              <td class="py-2.5 pr-4 text-right tabular-nums text-zinc-300">
                {{ parseFloat(tx.quantidade_kwh).toFixed(2) }}
              </td>
              <td class="py-2.5 text-right tabular-nums font-medium" :class="tx.is_comprador ? 'text-red-400' : 'text-emerald-400'">
                {{ tx.is_comprador ? '−' : '+' }}{{ parseFloat(tx.valor_total).toFixed(2) }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </BaseCard>
  </div>
</template>
