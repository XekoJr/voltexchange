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
    IF NEW.dados_audit ? 'temperatura' THEN
        v_temperatura := (NEW.dados_audit->>'temperatura')::numeric;
        IF v_temperatura > 80 THEN
            v_anomalia := TRUE;
            v_motivo   := v_motivo || format('temperatura crítica: %s°C; ', v_temperatura);
        END IF;
    END IF;

    v_erro_codigo := NEW.dados_audit->>'erro_codigo';
    IF v_erro_codigo IS NOT NULL THEN
        v_anomalia := TRUE;
        v_motivo   := v_motivo || format('erro_codigo: %s; ', v_erro_codigo);
    END IF;

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

DROP TRIGGER IF EXISTS trg_DetectarAnomalias ON Leituras;
CREATE TRIGGER trg_DetectarAnomalias
    AFTER INSERT ON Leituras
    FOR EACH ROW
    EXECUTE FUNCTION fn_DetectarAnomalias();


CREATE OR REPLACE FUNCTION fn_ProtegerUtilizadores()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_transacoes_recentes INTEGER;
BEGIN
    IF OLD.saldo > 0 THEN
        RAISE EXCEPTION
            'Não é possível eliminar o utilizador % (%) com saldo positivo de €%. Efectue o levantamento primeiro.',
            OLD.utilizador_id, OLD.email, OLD.saldo;
    END IF;

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

DROP TRIGGER IF EXISTS trg_ProtegerUtilizadores ON Utilizadores;
CREATE TRIGGER trg_ProtegerUtilizadores
    BEFORE DELETE ON Utilizadores
    FOR EACH ROW
    EXECUTE FUNCTION fn_ProtegerUtilizadores();


CREATE OR REPLACE FUNCTION fn_AutoMatching()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    CALL sp_MatchingEngine();
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_AutoMatching_Ordem ON OrdensCompra;
CREATE TRIGGER trg_AutoMatching_Ordem
    AFTER INSERT ON OrdensCompra
    FOR EACH STATEMENT
    EXECUTE FUNCTION fn_AutoMatching();

DROP TRIGGER IF EXISTS trg_AutoMatching_Oferta ON OfertasVenda;
CREATE TRIGGER trg_AutoMatching_Oferta
    AFTER INSERT ON OfertasVenda
    FOR EACH STATEMENT
    EXECUTE FUNCTION fn_AutoMatching();
