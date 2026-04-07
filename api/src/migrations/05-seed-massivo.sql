-- Leituras massivas: 10 contadores x 50 000 = 500 000 leituras
-- 80% normais, 15% temperatura > 80 (anomalia), 5% com erro_codigo
INSERT INTO Leituras (contador_id, data_hora, kwh_leitura, dados_audit)
SELECT
    (((series_num - 1) % 10) + 1)                         AS contador_id,
    TIMESTAMP '2025-01-01 00:00:00'
        + (series_num * INTERVAL '126 seconds')            AS data_hora,
    ROUND((5 + random() * 115)::numeric, 3)               AS kwh_leitura,
    CASE
        WHEN (series_num % 20) < 16 THEN
            jsonb_build_object(
                'temperatura', ROUND((20 + random() * 55)::numeric, 1),
                'voltagem',    ROUND((220 + random() * 20)::numeric, 1),
                'erro_codigo', NULL
            )
        WHEN (series_num % 20) < 19 THEN
            jsonb_build_object(
                'temperatura', ROUND((81 + random() * 29)::numeric, 1),
                'voltagem',    ROUND((200 + random() * 30)::numeric, 1),
                'erro_codigo', NULL
            )
        ELSE
            jsonb_build_object(
                'temperatura', ROUND((20 + random() * 55)::numeric, 1),
                'voltagem',    ROUND((180 + random() * 50)::numeric, 1),
                'erro_codigo', (ARRAY[
                    'ERR_VOLT', 'ERR_FREQ', 'ERR_PHASE',
                    'ERR_OVERLOAD', 'ERR_042', 'ERR_COMM',
                    'ERR_SENSOR', 'ERR_CAL'
                ])[1 + floor(random() * 8)::int]
            )
    END AS dados_audit
FROM generate_series(1, 500000) AS series_num;


-- Ofertas de venda massivas (1000)
-- Vendedores: 7, 8, 9, 10 | Estados: 70% ATIVA, 20% VENDIDA, 10% CANCELADA
INSERT INTO OfertasVenda (vendedor_id, quantidade_kwh, preco_unitario, estado, data_criacao, regiao)
SELECT
    (ARRAY[7, 8, 9, 10])[ 1 + ((s - 1) % 4) ]            AS vendedor_id,
    ROUND((10 + random() * 190)::numeric, 3)              AS quantidade_kwh,
    ROUND((0.08 + random() * 0.12)::numeric, 4)           AS preco_unitario,
    CASE
        WHEN s % 10 < 7 THEN 'ATIVA'
        WHEN s % 10 < 9 THEN 'VENDIDA'
        ELSE                 'CANCELADA'
    END                                                    AS estado,
    TIMESTAMP '2025-01-01' + (s * INTERVAL '8 hours')     AS data_criacao,
    (ARRAY['Norte', 'Centro', 'Sul', NULL])[ 1 + ((s - 1) % 4) ] AS regiao
FROM generate_series(1, 1000) AS s;


-- Ordens de compra massivas (500)
-- Compradores: 1, 2, 3, 4, 5 | Estados: 60% PENDENTE, 30% CONCLUIDA, 10% CANCELADA
UPDATE Utilizadores SET saldo = 50000.00 WHERE utilizador_id IN (1, 2, 3, 4, 5);

INSERT INTO OrdensCompra (comprador_id, quantidade_kwh, preco_maximo, estado, data_criacao, regiao)
SELECT
    (ARRAY[1, 2, 3, 4, 5])[ 1 + ((s - 1) % 5) ]          AS comprador_id,
    ROUND((5 + random() * 95)::numeric, 3)                AS quantidade_kwh,
    ROUND((0.10 + random() * 0.12)::numeric, 4)           AS preco_maximo,
    CASE
        WHEN s % 10 < 6 THEN 'PENDENTE'
        WHEN s % 10 < 9 THEN 'CONCLUIDA'
        ELSE                 'CANCELADA'
    END                                                    AS estado,
    TIMESTAMP '2025-01-01' + (s * INTERVAL '17 hours')    AS data_criacao,
    (ARRAY['Norte', 'Centro', 'Sul', NULL])[ 1 + ((s - 1) % 4) ] AS regiao
FROM generate_series(1, 500) AS s;


-- Marcar contadores com leituras anomalas como MANUTENCAO
UPDATE Contadores c
SET estado = 'MANUTENCAO'
WHERE EXISTS (
    SELECT 1 FROM Leituras l
    WHERE l.contador_id = c.contador_id
      AND (
          (l.dados_audit ? 'temperatura' AND (l.dados_audit->>'temperatura')::numeric > 80)
          OR (l.dados_audit->>'erro_codigo') IS NOT NULL
      )
);

-- Verificacao dos totais
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

    RAISE NOTICE '=== SEED MASSIVO CONCLUIDO ===';
    RAISE NOTICE 'Leituras:         %', v_leituras;
    RAISE NOTICE 'Ofertas de venda: %', v_ofertas;
    RAISE NOTICE 'Ordens de compra: %', v_ordens;
    RAISE NOTICE 'Leituras anomalas:%', v_anomalias;
    RAISE NOTICE 'Contadores em MANUTENCAO: %', v_manutencao;
END;
$$;
