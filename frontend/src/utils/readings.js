// Calcula que partições mensais (Leituras_YYYY_MM) um intervalo de datas
// atravessa — espelha o particionamento RANGE (data_hora) da tabela Leituras
export function partitionsForRange(inicio, fim) {
  const start = new Date(inicio);
  const end = new Date(fim);
  const partitions = [];
  const cursor = new Date(start.getFullYear(), start.getMonth(), 1);
  while (cursor <= end && partitions.length < 24) {
    const y = cursor.getFullYear();
    const m = String(cursor.getMonth() + 1).padStart(2, '0');
    partitions.push(`Leituras_${y}_${m}`);
    cursor.setMonth(cursor.getMonth() + 1);
  }
  return partitions;
}

// Reduz séries grandes para renderização fluida no Chart.js — média por
// bucket, mantém a forma da curva sem despejar dezenas de milhares de pontos
export function downsample(rows, maxPoints = 500) {
  if (rows.length <= maxPoints) return { rows, downsampled: false };
  const bucketSize = Math.ceil(rows.length / maxPoints);
  const out = [];
  for (let i = 0; i < rows.length; i += bucketSize) {
    const bucket = rows.slice(i, i + bucketSize);
    const avg = bucket.reduce((s, r) => s + parseFloat(r.kwh_leitura), 0) / bucket.length;
    out.push({ ...bucket[0], kwh_leitura: avg.toFixed(3) });
  }
  return { rows: out, downsampled: true };
}

export function fmtDateTime(value, locale) {
  return new Date(value).toLocaleString(locale === 'pt' ? 'pt-PT' : 'en-GB', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function fmtDate(value, locale) {
  return new Date(value).toLocaleDateString(locale === 'pt' ? 'pt-PT' : 'en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}
