-- -------------------------------------------------------------
-- 04-seed-mini.sql
-- -------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Utilizadores (10)
INSERT INTO Utilizadores (nome, email, password_hash, saldo) VALUES
    ('Alice Ferreira',    'alice@voltexchange.com',    crypt('senha123', gen_salt('bf', 12)), 500.00),
    ('Bruno Santos',      'bruno@voltexchange.com',    crypt('senha123', gen_salt('bf', 12)), 250.00),
    ('Carla Oliveira',    'carla@voltexchange.com',    crypt('senha123', gen_salt('bf', 12)), 100.00),
    ('David Costa',       'david@voltexchange.com',    crypt('senha123', gen_salt('bf', 12)), 750.00),
    ('Eva Rodrigues',     'eva@voltexchange.com',      crypt('senha123', gen_salt('bf', 12)), 50.00),
    ('Fernando Lopes',    'fernando@voltexchange.com', crypt('senha123', gen_salt('bf', 12)), 0.00),
    ('Gabriela Nunes',    'gabriela@voltexchange.com', crypt('senha123', gen_salt('bf', 12)), 1000.00),
    ('Hugo Pereira',      'hugo@voltexchange.com',     crypt('senha123', gen_salt('bf', 12)), 200.00),
    ('Inês Carvalho',     'ines@voltexchange.com',     crypt('senha123', gen_salt('bf', 12)), 150.00),
    ('João Martins',      'joao@voltexchange.com',     crypt('senha123', gen_salt('bf', 12)), 300.00);

-- Contadores (10)
INSERT INTO Contadores (utilizador_id, numero_serie, estado, regiao) VALUES
    (1,  'CTR-NORTE-001', 'ATIVO', 'Norte'),
    (1,  'CTR-NORTE-002', 'ATIVO', 'Norte'),
    (2,  'CTR-CENTRO-001','ATIVO', 'Centro'),
    (4,  'CTR-NORTE-003', 'ATIVO', 'Norte'),
    (5,  'CTR-SUL-001',   'ATIVO', 'Sul'),
    (7,  'CTR-CENTRO-002','ATIVO', 'Centro'),
    (7,  'CTR-SUL-002',   'ATIVO', 'Sul'),
    (8,  'CTR-NORTE-004', 'ATIVO', 'Norte'),
    (9,  'CTR-CENTRO-003','ATIVO', 'Centro'),
    (10, 'CTR-SUL-003',   'ATIVO', 'Sul');

-- Leituras normais (40)
INSERT INTO Leituras (contador_id, data_hora, kwh_leitura, dados_audit) VALUES
    (1, '2025-01-10 08:00:00', 42.500, '{"temperatura": 23, "voltagem": 230, "erro_codigo": null}'),
    (1, '2025-02-10 08:00:00', 38.200, '{"temperatura": 25, "voltagem": 231, "erro_codigo": null}'),
    (1, '2025-03-10 08:00:00', 45.100, '{"temperatura": 28, "voltagem": 229, "erro_codigo": null}'),
    (1, '2025-04-10 08:00:00', 51.300, '{"temperatura": 31, "voltagem": 230, "erro_codigo": null}'),
    (1, '2025-05-10 08:00:00', 47.800, '{"temperatura": 35, "voltagem": 232, "erro_codigo": null}'),
    (2, '2025-01-15 09:00:00', 33.400, '{"temperatura": 22, "voltagem": 228, "erro_codigo": null}'),
    (2, '2025-02-15 09:00:00', 36.700, '{"temperatura": 24, "voltagem": 230, "erro_codigo": null}'),
    (2, '2025-03-15 09:00:00', 29.900, '{"temperatura": 27, "voltagem": 229, "erro_codigo": null}'),
    (2, '2025-04-15 09:00:00', 41.200, '{"temperatura": 30, "voltagem": 231, "erro_codigo": null}'),
    (2, '2025-05-15 09:00:00', 44.600, '{"temperatura": 34, "voltagem": 230, "erro_codigo": null}'),
    (3, '2025-01-20 10:00:00', 28.100, '{"temperatura": 21, "voltagem": 230, "erro_codigo": null}'),
    (3, '2025-02-20 10:00:00', 31.500, '{"temperatura": 23, "voltagem": 229, "erro_codigo": null}'),
    (3, '2025-03-20 10:00:00', 35.200, '{"temperatura": 26, "voltagem": 231, "erro_codigo": null}'),
    (3, '2025-06-20 10:00:00', 52.300, '{"temperatura": 42, "voltagem": 230, "erro_codigo": null}'),
    (3, '2025-07-20 10:00:00', 60.100, '{"temperatura": 55, "voltagem": 228, "erro_codigo": null}'),
    (4, '2025-02-05 07:30:00', 39.800, '{"temperatura": 24, "voltagem": 230, "erro_codigo": null}'),
    (4, '2025-03-05 07:30:00', 43.200, '{"temperatura": 27, "voltagem": 231, "erro_codigo": null}'),
    (4, '2025-04-05 07:30:00', 48.700, '{"temperatura": 32, "voltagem": 229, "erro_codigo": null}'),
    (4, '2025-08-05 07:30:00', 65.400, '{"temperatura": 58, "voltagem": 230, "erro_codigo": null}'),
    (4, '2025-09-05 07:30:00', 58.900, '{"temperatura": 50, "voltagem": 232, "erro_codigo": null}'),
    (5, '2025-01-25 11:00:00', 22.300, '{"temperatura": 20, "voltagem": 230, "erro_codigo": null}'),
    (5, '2025-03-25 11:00:00', 26.800, '{"temperatura": 25, "voltagem": 229, "erro_codigo": null}'),
    (5, '2025-05-25 11:00:00', 31.100, '{"temperatura": 33, "voltagem": 231, "erro_codigo": null}'),
    (5, '2025-07-25 11:00:00', 38.500, '{"temperatura": 47, "voltagem": 230, "erro_codigo": null}'),
    (5, '2025-09-25 11:00:00', 44.200, '{"temperatura": 51, "voltagem": 228, "erro_codigo": null}'),
    (6, '2025-02-12 14:00:00', 55.600, '{"temperatura": 26, "voltagem": 230, "erro_codigo": null}'),
    (6, '2025-04-12 14:00:00', 62.300, '{"temperatura": 34, "voltagem": 231, "erro_codigo": null}'),
    (6, '2025-06-12 14:00:00', 70.100, '{"temperatura": 45, "voltagem": 229, "erro_codigo": null}'),
    (6, '2025-08-12 14:00:00', 75.200, '{"temperatura": 57, "voltagem": 230, "erro_codigo": null}'),
    (6, '2025-10-12 14:00:00', 68.400, '{"temperatura": 48, "voltagem": 232, "erro_codigo": null}'),
    (7, '2025-03-08 16:00:00', 32.100, '{"temperatura": 27, "voltagem": 230, "erro_codigo": null}'),
    (7, '2025-05-08 16:00:00', 37.800, '{"temperatura": 35, "voltagem": 229, "erro_codigo": null}'),
    (7, '2025-07-08 16:00:00', 43.500, '{"temperatura": 48, "voltagem": 231, "erro_codigo": null}'),
    (8, '2025-02-18 12:00:00', 28.900, '{"temperatura": 23, "voltagem": 230, "erro_codigo": null}'),
    (8, '2025-05-18 12:00:00', 35.600, '{"temperatura": 36, "voltagem": 228, "erro_codigo": null}'),
    (9, '2025-01-30 15:00:00', 19.400, '{"temperatura": 21, "voltagem": 230, "erro_codigo": null}'),
    (9, '2025-04-30 15:00:00', 24.700, '{"temperatura": 31, "voltagem": 231, "erro_codigo": null}'),
    (10,'2025-02-28 08:30:00', 41.300, '{"temperatura": 24, "voltagem": 230, "erro_codigo": null}'),
    (10,'2025-06-28 08:30:00', 53.200, '{"temperatura": 43, "voltagem": 229, "erro_codigo": null}'),
    (10,'2025-10-28 08:30:00', 61.800, '{"temperatura": 52, "voltagem": 231, "erro_codigo": null}');

-- Leituras anomalas: temperatura > 80 (5)
INSERT INTO Leituras (contador_id, data_hora, kwh_leitura, dados_audit) VALUES
    (1, '2025-11-01 06:00:00', 12.500, '{"temperatura": 95, "voltagem": 228, "erro_codigo": null}'),
    (3, '2025-11-05 06:00:00', 8.300,  '{"temperatura": 87, "voltagem": 215, "erro_codigo": null}'),
    (5, '2025-11-10 06:00:00', 15.100, '{"temperatura": 102,"voltagem": 220, "erro_codigo": null}'),
    (7, '2025-11-15 06:00:00', 6.900,  '{"temperatura": 83, "voltagem": 225, "erro_codigo": null}'),
    (9, '2025-11-20 06:00:00', 9.700,  '{"temperatura": 91, "voltagem": 210, "erro_codigo": null}');

-- Leituras anomalas: erro_codigo presente (5)
INSERT INTO Leituras (contador_id, data_hora, kwh_leitura, dados_audit) VALUES
    (2, '2025-11-02 07:00:00', 7.200,  '{"temperatura": 45, "voltagem": 215, "erro_codigo": "ERR_VOLT"}'),
    (4, '2025-11-06 07:00:00', 5.800,  '{"temperatura": 38, "voltagem": 195, "erro_codigo": "ERR_FREQ"}'),
    (6, '2025-11-11 07:00:00', 11.400, '{"temperatura": 52, "voltagem": 185, "erro_codigo": "ERR_PHASE"}'),
    (8, '2025-11-16 07:00:00', 4.600,  '{"temperatura": 29, "voltagem": 175, "erro_codigo": "ERR_042"}'),
    (10,'2025-11-21 07:00:00', 8.100,  '{"temperatura": 41, "voltagem": 200, "erro_codigo": "ERR_OVERLOAD"}');

-- Ofertas de venda (20)
INSERT INTO OfertasVenda (vendedor_id, quantidade_kwh, preco_unitario, estado, regiao) VALUES
    (7, 100.000, 0.1100, 'ATIVA', 'Norte'),
    (7,  50.000, 0.1200, 'ATIVA', 'Norte'),
    (7,  75.000, 0.1150, 'ATIVA', 'Centro'),
    (7,  30.000, 0.1300, 'ATIVA', 'Sul'),
    (7,  60.000, 0.1050, 'ATIVA',  NULL),
    (10, 40.000, 0.1250, 'ATIVA', 'Centro'),
    (10, 80.000, 0.1350, 'ATIVA', 'Norte'),
    (10, 25.000, 0.1200, 'ATIVA', 'Sul'),
    (10, 55.000, 0.1400, 'ATIVA', NULL),
    (10, 20.000, 0.1100, 'ATIVA', 'Norte'),
    (8,  35.000, 0.1300, 'ATIVA', 'Norte'),
    (8,  45.000, 0.1450, 'ATIVA', 'Centro'),
    (8,  15.000, 0.1600, 'ATIVA', 'Sul'),
    (8,  90.000, 0.1550, 'ATIVA', NULL),
    (4,  25.000, 0.1700, 'ATIVA', 'Norte'),
    (4,  50.000, 0.1800, 'ATIVA', 'Centro'),
    (4,  30.000, 0.1650, 'ATIVA', 'Sul'),
    (4,  20.000, 0.1750, 'ATIVA', NULL),
    (4,  65.000, 0.1600, 'ATIVA', 'Norte'),
    (4,  10.000, 0.1550, 'ATIVA', 'Centro');

-- Ordens de compra (10) — Fernando (id=6) tem saldo=0, serve para testar erro
INSERT INTO OrdensCompra (comprador_id, quantidade_kwh, preco_maximo, estado, regiao) VALUES
    (1,  20.000, 0.1300, 'PENDENTE', 'Norte'),
    (2,  15.000, 0.1400, 'PENDENTE', 'Centro'),
    (3,  10.000, 0.1500, 'PENDENTE', 'Sul'),
    (4,  25.000, 0.1200, 'PENDENTE',  NULL),
    (5,   5.000, 0.1400, 'PENDENTE', 'Norte'),
    (1,  50.000, 0.1600, 'PENDENTE', 'Centro'),
    (2,  30.000, 0.1700, 'PENDENTE',  NULL),
    (3,  40.000, 0.1800, 'PENDENTE', 'Norte'),
    (6,  10.000, 0.1500, 'PENDENTE', 'Norte'),
    (9,   8.000, 0.1300, 'PENDENTE', 'Sul');


-- -------------------------------------------------------------
-- 05-seed-massivo.sql
-- -------------------------------------------------------------

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

    RAISE NOTICE 'Leituras:         %', v_leituras;
    RAISE NOTICE 'Ofertas de venda: %', v_ofertas;
    RAISE NOTICE 'Ordens de compra: %', v_ordens;
    RAISE NOTICE 'Leituras anomalas:%', v_anomalias;
    RAISE NOTICE 'Contadores em MANUTENCAO: %', v_manutencao;
END;
$$;