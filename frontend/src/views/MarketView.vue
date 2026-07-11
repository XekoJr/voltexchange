<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useUserStore } from '../stores/user';
import { useToastStore } from '../stores/toast';
import { marketApi, apiError } from '../api/endpoints';
import BaseCard from '../components/ui/BaseCard.vue';
import BaseButton from '../components/ui/BaseButton.vue';
import BaseInput from '../components/ui/BaseInput.vue';
import BaseSelect from '../components/ui/BaseSelect.vue';
import BaseModal from '../components/ui/BaseModal.vue';
import EmptyState from '../components/ui/EmptyState.vue';

const { t } = useI18n();
const user = useUserStore();
const toast = useToastStore();

const offers = ref([]);
const loading = ref(false);
const regiao = ref('');

const regionOptions = computed(() => [
  { value: '', label: t('market.allRegions') },
  { value: 'Norte', label: 'Norte' },
  { value: 'Centro', label: 'Centro' },
  { value: 'Sul', label: 'Sul' },
]);
const regionFormOptions = computed(() => [
  { value: '', label: t('market.regionOptional') },
  { value: 'Norte', label: 'Norte' },
  { value: 'Centro', label: 'Centro' },
  { value: 'Sul', label: 'Sul' },
]);

// Compra direta
const buyTarget = ref(null);
const buyQty = ref('');
const buyLoading = ref(false);

// Formulários de publicação
const offerForm = ref({ qty: '', price: '', regiao: '' });
const orderForm = ref({ qty: '', maxPrice: '', regiao: '' });
const offerLoading = ref(false);
const orderLoading = ref(false);

onMounted(() => {
  refresh();
  user.fetchProfile();
});

async function refresh() {
  loading.value = true;
  try {
    const { data } = await marketApi.offers(regiao.value || undefined);
    offers.value = data;
  } catch (e) {
    toast.error(apiError(e));
  } finally {
    loading.value = false;
  }
}

// Depois de qualquer mutação refazemos ofertas + saldo — os triggers de
// auto-matching podem já ter consumido o que acabou de ser publicado
async function refreshAll() {
  await Promise.all([refresh(), user.fetchProfile()]);
}

function openBuy(offer) {
  buyTarget.value = offer;
  buyQty.value = offer.quantidade_kwh;
}

async function confirmBuy() {
  buyLoading.value = true;
  try {
    await marketApi.buy(buyTarget.value.oferta_id, parseFloat(buyQty.value));
    toast.push(t('market.bought'));
    buyTarget.value = null;
    await refreshAll();
  } catch (e) {
    toast.error(apiError(e));
  } finally {
    buyLoading.value = false;
  }
}

async function submitOffer() {
  offerLoading.value = true;
  try {
    await marketApi.postOffer(parseFloat(offerForm.value.qty), parseFloat(offerForm.value.price), offerForm.value.regiao);
    toast.push(t('market.offerPosted'));
    offerForm.value = { qty: '', price: '', regiao: '' };
    await refreshAll();
  } catch (e) {
    toast.error(apiError(e));
  } finally {
    offerLoading.value = false;
  }
}

async function submitOrder() {
  orderLoading.value = true;
  try {
    await marketApi.postOrder(parseFloat(orderForm.value.qty), parseFloat(orderForm.value.maxPrice), orderForm.value.regiao);
    toast.push(t('market.orderPosted'));
    orderForm.value = { qty: '', maxPrice: '', regiao: '' };
    await refreshAll();
  } catch (e) {
    toast.error(apiError(e));
  } finally {
    orderLoading.value = false;
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-bold text-zinc-50">{{ t('market.title') }}</h1>
      <div class="text-sm text-zinc-500">
        {{ t('market.yourBalance') }}:
        <span class="font-semibold text-volt tabular-nums">€{{ user.saldo.toFixed(2) }}</span>
      </div>
    </div>

    <div class="grid gap-6 lg:grid-cols-3">
      <!-- Lista de ofertas -->
      <BaseCard :title="t('market.activeOffers')" class="lg:col-span-2">
        <template #header>
          <div class="w-40">
            <BaseSelect v-model="regiao" :options="regionOptions" @update:model-value="refresh" />
          </div>
        </template>

        <EmptyState v-if="!loading && !offers.length">{{ t('market.noOffers') }}</EmptyState>
        <div v-else class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-zinc-800 text-left text-xs uppercase tracking-wide text-zinc-600">
                <th class="pb-2 pr-4">{{ t('common.id') }}</th>
                <th class="pb-2 pr-4">{{ t('market.region') }}</th>
                <th class="pb-2 pr-4 text-right">{{ t('market.quantity') }}</th>
                <th class="pb-2 pr-4 text-right">{{ t('market.price') }}</th>
                <th class="pb-2"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-800/60">
              <tr v-for="offer in offers" :key="offer.oferta_id" class="hover:bg-zinc-900/40">
                <td class="py-2.5 pr-4 font-mono text-xs text-zinc-500">#{{ offer.oferta_id }}</td>
                <td class="py-2.5 pr-4 text-zinc-400">{{ offer.regiao || '—' }}</td>
                <td class="py-2.5 pr-4 text-right tabular-nums text-zinc-200">
                  {{ parseFloat(offer.quantidade_kwh).toFixed(2) }} kWh
                </td>
                <td class="py-2.5 pr-4 text-right tabular-nums font-medium text-volt">
                  €{{ parseFloat(offer.preco_unitario).toFixed(4) }}
                </td>
                <td class="py-2.5 text-right">
                  <BaseButton variant="ghost" class="!px-3 !py-1" @click="openBuy(offer)">
                    {{ t('market.buy') }}
                  </BaseButton>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </BaseCard>

      <!-- Publicar oferta / ordem -->
      <div class="space-y-6">
        <BaseCard :title="t('market.postOffer')">
          <form class="space-y-3" @submit.prevent="submitOffer">
            <BaseInput v-model="offerForm.qty" :label="t('market.quantity')" type="number" min="0.001" step="0.001" required />
            <BaseInput v-model="offerForm.price" :label="t('market.unitPrice')" type="number" min="0.0001" step="0.0001" required />
            <BaseSelect v-model="offerForm.regiao" :options="regionFormOptions" />
            <BaseButton type="submit" class="w-full" :loading="offerLoading">
              {{ t('market.publishOffer') }}
            </BaseButton>
          </form>
        </BaseCard>

        <BaseCard :title="t('market.postOrder')">
          <form class="space-y-3" @submit.prevent="submitOrder">
            <BaseInput v-model="orderForm.qty" :label="t('market.quantity')" type="number" min="0.001" step="0.001" required />
            <BaseInput v-model="orderForm.maxPrice" :label="t('market.maxPrice')" type="number" min="0.0001" step="0.0001" required />
            <BaseSelect v-model="orderForm.regiao" :options="regionFormOptions" />
            <BaseButton type="submit" class="w-full" :loading="orderLoading">
              {{ t('market.publishOrder') }}
            </BaseButton>
          </form>
        </BaseCard>
      </div>
    </div>

    <!-- Modal de compra direta -->
    <BaseModal :open="!!buyTarget" :title="t('market.buyTitle')" @close="buyTarget = null">
      <template v-if="buyTarget">
        <p class="mb-4 text-sm text-zinc-400">
          {{ t('market.buyQuantityHint', { qty: parseFloat(buyTarget.quantidade_kwh).toFixed(2), price: parseFloat(buyTarget.preco_unitario).toFixed(4) }) }}
        </p>
        <form class="space-y-4" @submit.prevent="confirmBuy">
          <BaseInput
            v-model="buyQty"
            :label="t('market.quantity')"
            type="number"
            min="0.001"
            :max="buyTarget.quantidade_kwh"
            step="0.001"
            required
          />
          <div class="flex items-center justify-between text-sm">
            <span class="text-zinc-500">{{ t('market.total') }}</span>
            <span class="font-semibold text-volt tabular-nums">
              €{{ (parseFloat(buyQty || 0) * parseFloat(buyTarget.preco_unitario)).toFixed(2) }}
            </span>
          </div>
          <BaseButton type="submit" class="w-full" :loading="buyLoading">
            {{ t('market.confirmBuy') }}
          </BaseButton>
        </form>
      </template>
    </BaseModal>
  </div>
</template>
