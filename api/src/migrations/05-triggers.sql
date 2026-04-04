-- =============================================================================
-- VoltExchange — 05-triggers.sql
-- Triggers de automação e proteção de dados
-- =============================================================================

-- =============================================================================
-- trg_DetectarAnomalias
-- AFTER INSERT ON Leituras
--
-- Detecta automaticamente leituras anómalas e coloca o contador em MANUTENCAO.
-- Uma leitura é considerada anómala se:
--   a) temperatura > 80 (graus Celsius) nos dados de auditoria JSONB, OU
--   b) campo 'erro_codigo' existe e não é nulo nos dados de auditoria
--
-- Nota: funciona em tabelas particionadas (PostgreSQL 13+).
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_DetectarAnomalias()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_temperatura NUMERIC;
    v_erro_codigo TEXT;
    v_anomalia    BOOLEAN := FALSE;
    v_motivo      TEXT    := '';
BEGIN
    -- Extrair temperatura do JSONB (pode não existir)
    IF NEW.dados_audit ? 'temperatura' THEN
        v_temperatura := (NEW.dados_audit->>'temperatura')::numeric;
        IF v_temperatura > 80 THEN
            v_anomalia := TRUE;
            v_motivo   := v_motivo || format('temperatura crítica: %s°C; ', v_temperatura);
        END IF;
    END IF;

    -- Verificar presença de erro_codigo não nulo
    v_erro_codigo := NEW.dados_audit->>'erro_codigo';
    IF v_erro_codigo IS NOT NULL THEN
        v_anomalia := TRUE;
        v_motivo   := v_motivo || format('erro_codigo: %s; ', v_erro_codigo);
    END IF;

    -- Se anomalia detectada, colocar contador em MANUTENCAO
    IF v_anomalia THEN
        UPDATE Contadores
        SET estado = 'MANUTENCAO'
        WHERE contador_id = NEW.contador_id;

        RAISE NOTICE 'ANOMALIA DETECTADA — Contador % → MANUTENCAO | Leitura % | Motivo: %',
            NEW.contador_id, NEW.leitura_id, v_motivo;
    END IF;

    RETURN NEW;
END;
$$;

-- Trigger associado à tabela particionada Leituras
-- Propaga automaticamente para todas as partições existentes e futuras
CREATE TRIGGER trg_DetectarAnomalias
    AFTER INSERT ON Leituras
    FOR EACH ROW
    EXECUTE FUNCTION fn_DetectarAnomalias();


-- =============================================================================
-- trg_ProtegerUtilizadores
-- BEFORE DELETE ON Utilizadores
--
-- Impede a eliminação de utilizadores que:
--   a) Ainda têm saldo positivo na conta, OU
--   b) Tiveram transações nos últimos 30 dias
--
-- Garante integridade dos dados financeiros e histórico de transações.
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_ProtegerUtilizadores()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_transacoes_recentes INTEGER;
BEGIN
    -- Verificar saldo positivo
    IF OLD.saldo > 0 THEN
        RAISE EXCEPTION
            'Não é possível eliminar o utilizador % (%) com saldo positivo de €%. Efectue o levantamento primeiro.',
            OLD.utilizador_id, OLD.email, OLD.saldo;
    END IF;

    -- Verificar transações nos últimos 30 dias
    SELECT COUNT(*)
    INTO v_transacoes_recentes
    FROM Transacoes
    WHERE (comprador_id = OLD.utilizador_id OR vendedor_id = OLD.utilizador_id)
      AND data_transacao >= NOW() - INTERVAL '30 days';

    IF v_transacoes_recentes > 0 THEN
        RAISE EXCEPTION
            'Não é possível eliminar o utilizador % (%) com % transação(ões) nos últimos 30 dias.',
            OLD.utilizador_id, OLD.email, v_transacoes_recentes;
    END IF;

    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_ProtegerUtilizadores
    BEFORE DELETE ON Utilizadores
    FOR EACH ROW
    EXECUTE FUNCTION fn_ProtegerUtilizadores();


-- =============================================================================
-- trg_AutoMatching  [EXCELÊNCIA]
-- AFTER INSERT ON OrdensCompra | OfertasVenda
--
-- Dispara automaticamente o sp_MatchingEngine sempre que uma nova ordem ou
-- oferta é criada, sem necessidade de chamada manual à API.
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_AutoMatching()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    CALL sp_MatchingEngine();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_AutoMatching_Ordem
    AFTER INSERT ON OrdensCompra
    FOR EACH STATEMENT
    EXECUTE FUNCTION fn_AutoMatching();

CREATE TRIGGER trg_AutoMatching_Oferta
    AFTER INSERT ON OfertasVenda
    FOR EACH STATEMENT
    EXECUTE FUNCTION fn_AutoMatching();
