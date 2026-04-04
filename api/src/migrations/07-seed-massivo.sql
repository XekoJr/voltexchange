-- =============================================================================
-- VoltExchange — 07-seed-massivo.sql
-- Seed massivo para testes de performance e demonstração do CP1/CP2
--
-- Requer: 06-seed-mini.sql já executado (utilizadores e contadores existem)
--
-- Conteúdo:
--   500 000+ leituras (generate_series, ~2025-01 a 2026-12)
--   1 000+ ofertas de venda
--   500+ ordens de compra
--
-- Estratégia de geração:
--   - Leituras: para cada um dos 10 contadores, ~50 000 leituras via generate_series
--   - 80% normais (temperatura 20-60°C), 20% anómalas
--   - Dados JSONB variados para exercitar o índice GIN
--   - Triggers desactivados durante inserção massiva (performance)
--   - Reactivados no final
-- =============================================================================

-- Desactivar triggers pesados durante a carga massiva
ALTER TABLE Leituras    DISABLE TRIGGER trg_DetectarAnomalias;
ALTER TABLE OfertasVenda DISABLE TRIGGER trg_AutoMatching_Oferta;
ALTER TABLE OrdensCompra DISABLE TRIGGER trg_AutoMatching_Ordem;

-- =============================================================================
-- LEITURAS MASSIVAS (~500 000)
-- 10 contadores × 50 000 leituras cada = 500 000 leituras
-- Distribuídas uniformemente de 2025-01-01 a 2026-12-31 (2 anos)
--
-- Lógica JSONB:
--   - 80%: temperatura aleatória [20, 75], sem erro_codigo
--   - 15%: temperatura aleatória [81, 110] → ANOMALIA temperatura
--   -  5%: temperatura normal + erro_codigo → ANOMALIA erro_codigo
-- =============================================================================
INSERT INTO Leituras (contador_id, data_hora, kwh_leitura, dados_audit)
SELECT
    -- Distribuir pelos 10 contadores (1-10) em Round-Robin
    (((series_num - 1) % 10) + 1)                         AS contador_id,

    -- Datas uniformemente distribuídas 2025-01-01 → 2026-12-31 (730 dias)
    TIMESTAMP '2025-01-01 00:00:00'
        + (series_num * INTERVAL '126 seconds')            AS data_hora,

    -- kWh aleatório entre 5 e 120 kWh (3 casas decimais)
    ROUND((5 + random() * 115)::numeric, 3)               AS kwh_leitura,

    -- JSONB com distribuição 80% / 15% / 5%
    CASE
        WHEN (series_num % 20) < 16 THEN
            -- 80% normais
            jsonb_build_object(
                'temperatura', ROUND((20 + random() * 55)::numeric, 1),
                'voltagem',    ROUND((220 + random() * 20)::numeric, 1),
                'erro_codigo', NULL
            )
        WHEN (series_num % 20) < 19 THEN
            -- 15% anomalia de temperatura (> 80)
            jsonb_build_object(
                'temperatura', ROUND((81 + random() * 29)::numeric, 1),
                'voltagem',    ROUND((200 + random() * 30)::numeric, 1),
                'erro_codigo', NULL
            )
        ELSE
            -- 5% anomalia de erro_codigo
            jsonb_build_object(
                'temperatura', ROUND((20 + random() * 55)::numeric, 1),
                'voltagem',    ROUND((180 + random() * 50)::numeric, 1),
                'erro_codigo', (ARRAY[
                    'ERR_VOLT', 'ERR_FREQ', 'ERR_PHASE',
                    'ERR_OVERLOAD', 'ERR_042', 'ERR_COMM',
                    'ERR_SENSOR', 'ERR_CAL'
                ])[1 + floor(random() * 8)::int]
            )
    END                                                    AS dados_audit

FROM generate_series(1, 500000) AS series_num;


-- =============================================================================
-- OFERTAS DE VENDA MASSIVAS (1 000)
-- Vendedores: utilizadores 7, 8, 9, 10 (João, Hugo, Inês, Gabriela)
-- Regiões: Norte, Centro, Sul, NULL (sem preferência)
-- Preços: 0.08 – 0.20 €/kWh
-- Estados: 70% ATIVA, 20% VENDIDA, 10% CANCELADA
-- =============================================================================
INSERT INTO OfertasVenda (vendedor_id, quantidade_kwh, preco_unitario, estado, data_criacao, regiao)
SELECT
    -- Vendedores rotativos (ids 7, 8, 9, 10)
    (ARRAY[7, 8, 9, 10])[ 1 + ((s - 1) % 4) ]            AS vendedor_id,

    -- Quantidade 10–200 kWh
    ROUND((10 + random() * 190)::numeric, 3)              AS quantidade_kwh,

    -- Preço 0.08–0.20 €/kWh
    ROUND((0.08 + random() * 0.12)::numeric, 4)           AS preco_unitario,

    -- Estado distribuído
    CASE
        WHEN s % 10 < 7 THEN 'ATIVA'
        WHEN s % 10 < 9 THEN 'VENDIDA'
        ELSE                 'CANCELADA'
    END                                                    AS estado,

    -- Data de criação distribuída ao longo de 2025
    TIMESTAMP '2025-01-01' + (s * INTERVAL '8 hours')     AS data_criacao,

    -- Região (25% cada)
    (ARRAY['Norte', 'Centro', 'Sul', NULL])[ 1 + ((s - 1) % 4) ]  AS regiao

FROM generate_series(1, 1000) AS s;


-- =============================================================================
-- ORDENS DE COMPRA MASSIVAS (500)
-- Compradores: utilizadores 1, 2, 3, 4, 5 (Alice, Bruno, Carla, David, Eva)
-- Garante variedade de saldos para testar matching engine
-- =============================================================================

-- Aumentar saldos dos compradores para suportar as compras massivas do matching
UPDATE Utilizadores SET saldo = 50000.00 WHERE utilizador_id IN (1, 2, 3, 4, 5);

INSERT INTO OrdensCompra (comprador_id, quantidade_kwh, preco_maximo, estado, data_criacao, regiao)
SELECT
    -- Compradores rotativos (ids 1–5)
    (ARRAY[1, 2, 3, 4, 5])[ 1 + ((s - 1) % 5) ]          AS comprador_id,

    -- Quantidade 5–100 kWh
    ROUND((5 + random() * 95)::numeric, 3)                AS quantidade_kwh,

    -- Preço máximo 0.10–0.22 €/kWh (deliberadamente acima do mínimo das ofertas)
    ROUND((0.10 + random() * 0.12)::numeric, 4)           AS preco_maximo,

    -- Estado distribuído: 60% PENDENTE, 30% CONCLUIDA, 10% CANCELADA
    CASE
        WHEN s % 10 < 6 THEN 'PENDENTE'
        WHEN s % 10 < 9 THEN 'CONCLUIDA'
        ELSE                 'CANCELADA'
    END                                                    AS estado,

    -- Data de criação distribuída ao longo de 2025
    TIMESTAMP '2025-01-01' + (s * INTERVAL '17 hours')    AS data_criacao,

    -- Região com distribuição igual + NULL
    (ARRAY['Norte', 'Centro', 'Sul', NULL])[ 1 + ((s - 1) % 4) ]  AS regiao

FROM generate_series(1, 500) AS s;


-- =============================================================================
-- Corrigir anomalias na tabela Contadores após carga masssiva de leituras
-- (o trigger estava desactivado, aplicar manualmente a lógica)
-- Contadores com ≥ 1 leitura anómala → MANUTENCAO
-- =============================================================================
UPDATE Contadores c
SET estado = 'MANUTENCAO'
WHERE EXISTS (
    SELECT 1
    FROM Leituras l
    WHERE l.contador_id = c.contador_id
      AND (
          (l.dados_audit ? 'temperatura'
              AND (l.dados_audit->>'temperatura')::numeric > 80)
          OR (l.dados_audit->>'erro_codigo') IS NOT NULL
      )
);

-- Reactivar todos os triggers
ALTER TABLE Leituras    ENABLE TRIGGER trg_DetectarAnomalias;
ALTER TABLE OfertasVenda ENABLE TRIGGER trg_AutoMatching_Oferta;
ALTER TABLE OrdensCompra ENABLE TRIGGER trg_AutoMatching_Ordem;

-- =============================================================================
-- Verificação rápida dos totais inseridos
-- =============================================================================
DO $$
DECLARE
    v_leituras   BIGINT;
    v_ofertas    BIGINT;
    v_ordens     BIGINT;
    v_anomalias  BIGINT;
    v_manutencao BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_leituras   FROM Leituras;
    SELECT COUNT(*) INTO v_ofertas    FROM OfertasVenda;
    SELECT COUNT(*) INTO v_ordens     FROM OrdensCompra;
    SELECT COUNT(*) INTO v_manutencao FROM Contadores WHERE estado = 'MANUTENCAO';
    SELECT COUNT(*) INTO v_anomalias  FROM Leituras
        WHERE (dados_audit ? 'temperatura' AND (dados_audit->>'temperatura')::numeric > 80)
           OR (dados_audit->>'erro_codigo') IS NOT NULL;

    RAISE NOTICE '=== SEED MASSIVO CONCLUÍDO ===';
    RAISE NOTICE 'Leituras:         %', v_leituras;
    RAISE NOTICE 'Ofertas de venda: %', v_ofertas;
    RAISE NOTICE 'Ordens de compra: %', v_ordens;
    RAISE NOTICE 'Leituras anómalas:%', v_anomalias;
    RAISE NOTICE 'Contadores em MANUTENCAO: %', v_manutencao;
END;
$$;
