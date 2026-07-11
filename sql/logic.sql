-- -------------------------------------------------------------
-- 06-checkpoint1.sql
-- -------------------------------------------------------------

-- Exercicio 1: Trigger de Protecao Financeira
CREATE OR REPLACE FUNCTION fn_ProtegerUtilizadores()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_ofertas_ativas INTEGER;
BEGIN
    IF OLD.saldo > 0 THEN
        RAISE EXCEPTION
            'Nao e possivel eliminar o utilizador % — tem saldo positivo de €%. Efectue o levantamento primeiro.',
            OLD.utilizador_id, OLD.saldo;
    END IF;

    SELECT COUNT(*) INTO v_ofertas_ativas
    FROM OfertasVenda
    WHERE vendedor_id = OLD.utilizador_id
      AND estado = 'ATIVA';

    IF v_ofertas_ativas > 0 THEN
        RAISE EXCEPTION
            'Nao e possivel eliminar o utilizador % — tem % oferta(s) ATIVA(s). Cancele-as primeiro.',
            OLD.utilizador_id, v_ofertas_ativas;
    END IF;

    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_ProtegerUtilizadores ON Utilizadores;
CREATE TRIGGER trg_ProtegerUtilizadores
    BEFORE DELETE ON Utilizadores
    FOR EACH ROW
    EXECUTE FUNCTION fn_ProtegerUtilizadores();


-- Exercicio 2: Stored Procedure - Utilizador em quarentena: bloqueia contadores e cancela ofertas.
CREATE OR REPLACE PROCEDURE sp_QuarentenaUtilizador(p_utilizador_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM Utilizadores WHERE utilizador_id = p_utilizador_id
    ) THEN
        RAISE EXCEPTION 'Utilizador % nao encontrado.', p_utilizador_id;
    END IF;

    UPDATE Contadores
    SET estado = 'MANUTENCAO'
    WHERE utilizador_id = p_utilizador_id;

    UPDATE OfertasVenda
    SET estado = 'CANCELADA'
    WHERE vendedor_id = p_utilizador_id
      AND estado = 'ATIVA';

    RAISE NOTICE 'Utilizador % colocado em quarentena.', p_utilizador_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao colocar utilizador % em quarentena — rollback efectuado. Detalhe: %',
            p_utilizador_id, SQLERRM;
END;
$$;

-- -------------------------------------------------------------
-- 07-procedures.sql
-- -------------------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_ExecutarCompraDireta(
    p_oferta_id    INTEGER,
    p_comprador_id INTEGER,
    p_quantidade   NUMERIC(10, 3)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_oferta          RECORD;
    v_comprador_saldo NUMERIC(12, 2);
    v_valor_total     NUMERIC(12, 2);
BEGIN

    SELECT *
    INTO v_oferta
    FROM OfertasVenda
    WHERE oferta_id = p_oferta_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Oferta % não encontrada.', p_oferta_id;
    END IF;

    IF v_oferta.estado != 'ATIVA' THEN
        RAISE EXCEPTION 'Oferta % não está ativa (estado atual: %).', p_oferta_id, v_oferta.estado;
    END IF;

    IF p_quantidade <= 0 THEN
        RAISE EXCEPTION 'Quantidade deve ser um valor positivo.';
    END IF;

    IF p_quantidade > v_oferta.quantidade_kwh THEN
        RAISE EXCEPTION 'Quantidade solicitada (% kWh) excede o disponível (% kWh).',
            p_quantidade, v_oferta.quantidade_kwh;
    END IF;

    IF p_comprador_id = v_oferta.vendedor_id THEN
        RAISE EXCEPTION 'Comprador e vendedor não podem ser o mesmo utilizador.';
    END IF;

    v_valor_total := ROUND(p_quantidade * v_oferta.preco_unitario, 2);

    SELECT saldo INTO v_comprador_saldo
    FROM Utilizadores
    WHERE utilizador_id = p_comprador_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Comprador % não encontrado.', p_comprador_id;
    END IF;

    IF v_comprador_saldo < v_valor_total THEN
        RAISE EXCEPTION 'Saldo insuficiente. Necessário: €%, disponível: €%.',
            v_valor_total, v_comprador_saldo;
    END IF;

    BEGIN
        UPDATE Utilizadores
        SET saldo = saldo - v_valor_total
        WHERE utilizador_id = p_comprador_id;

        UPDATE Utilizadores
        SET saldo = saldo + v_valor_total
        WHERE utilizador_id = v_oferta.vendedor_id;

        IF v_oferta.quantidade_kwh = p_quantidade THEN
            UPDATE OfertasVenda
            SET estado = 'VENDIDA', quantidade_kwh = 0
            WHERE oferta_id = p_oferta_id;
        ELSE
            UPDATE OfertasVenda
            SET quantidade_kwh = quantidade_kwh - p_quantidade
            WHERE oferta_id = p_oferta_id;
        END IF;

        INSERT INTO Transacoes (
            oferta_id, ordem_id, comprador_id, vendedor_id,
            quantidade_kwh, preco_unitario, valor_total, tipo_transacao
        ) VALUES (
            p_oferta_id, NULL, p_comprador_id, v_oferta.vendedor_id,
            p_quantidade, v_oferta.preco_unitario, v_valor_total, 'DIRETA'
        );

        RAISE NOTICE 'Compra concluída: oferta=%, comprador=%, vendedor=%, qty=% kWh, valor=€%',
            p_oferta_id, p_comprador_id, v_oferta.vendedor_id, p_quantidade, v_valor_total;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Transação revertida — erro: %', SQLERRM;
    END;

END;
$$;


CREATE OR REPLACE PROCEDURE sp_MatchingEngine()
LANGUAGE plpgsql
AS $$
DECLARE
    v_ordem             RECORD;
    v_oferta            RECORD;
    v_quantidade_rest   NUMERIC(10, 3);
    v_transfer_qty      NUMERIC(10, 3);
    v_valor_total       NUMERIC(12, 2);
    v_comprador_saldo   NUMERIC(12, 2);
    v_matches           INTEGER := 0;
BEGIN
    RAISE NOTICE 'sp_MatchingEngine iniciado...';

    FOR v_ordem IN
        SELECT *
        FROM OrdensCompra
        WHERE estado = 'PENDENTE'
        ORDER BY data_criacao ASC
    LOOP
        v_quantidade_rest := v_ordem.quantidade_kwh;

        RAISE NOTICE 'A processar ordem %: comprador=%, qty=% kWh, preco_max=€%, regiao=%',
            v_ordem.ordem_id, v_ordem.comprador_id, v_ordem.quantidade_kwh,
            v_ordem.preco_maximo, COALESCE(v_ordem.regiao, 'qualquer');

        FOR v_oferta IN
            SELECT *
            FROM OfertasVenda
            WHERE estado = 'ATIVA'
              AND preco_unitario <= v_ordem.preco_maximo
              AND (
                  v_ordem.regiao IS NULL
                  OR regiao IS NULL
                  OR regiao = v_ordem.regiao
              )
              AND vendedor_id != v_ordem.comprador_id
            ORDER BY preco_unitario ASC, data_criacao ASC
            FOR UPDATE
        LOOP
            EXIT WHEN v_quantidade_rest <= 0;

            IF v_oferta.estado != 'ATIVA' THEN
                CONTINUE;
            END IF;

            v_transfer_qty := LEAST(v_quantidade_rest, v_oferta.quantidade_kwh);
            v_valor_total  := ROUND(v_transfer_qty * v_oferta.preco_unitario, 2);

            SELECT saldo
            INTO v_comprador_saldo
            FROM Utilizadores
            WHERE utilizador_id = v_ordem.comprador_id
            FOR UPDATE;

            IF v_comprador_saldo < v_valor_total THEN
                RAISE NOTICE '  Saldo insuficiente para comprador % (tem €%, precisa €%). A ignorar oferta %.',
                    v_ordem.comprador_id, v_comprador_saldo, v_valor_total, v_oferta.oferta_id;
                CONTINUE;
            END IF;

            UPDATE Utilizadores
            SET saldo = saldo - v_valor_total
            WHERE utilizador_id = v_ordem.comprador_id;

            UPDATE Utilizadores
            SET saldo = saldo + v_valor_total
            WHERE utilizador_id = v_oferta.vendedor_id;

            IF v_oferta.quantidade_kwh <= v_transfer_qty THEN
                UPDATE OfertasVenda
                SET estado = 'VENDIDA', quantidade_kwh = 0
                WHERE oferta_id = v_oferta.oferta_id;
            ELSE
                UPDATE OfertasVenda
                SET quantidade_kwh = quantidade_kwh - v_transfer_qty
                WHERE oferta_id = v_oferta.oferta_id;
            END IF;

            INSERT INTO Transacoes (
                oferta_id, ordem_id, comprador_id, vendedor_id,
                quantidade_kwh, preco_unitario, valor_total, tipo_transacao
            ) VALUES (
                v_oferta.oferta_id, v_ordem.ordem_id,
                v_ordem.comprador_id, v_oferta.vendedor_id,
                v_transfer_qty, v_oferta.preco_unitario, v_valor_total, 'MATCHED'
            );

            v_quantidade_rest := v_quantidade_rest - v_transfer_qty;
            v_matches         := v_matches + 1;

            RAISE NOTICE '  Match: ordem % ↔ oferta % | vendedor=% | qty=% kWh | valor=€%',
                v_ordem.ordem_id, v_oferta.oferta_id, v_oferta.vendedor_id,
                v_transfer_qty, v_valor_total;
        END LOOP;

        IF v_quantidade_rest <= 0 THEN
            UPDATE OrdensCompra
            SET estado = 'CONCLUIDA'
            WHERE ordem_id = v_ordem.ordem_id;
            RAISE NOTICE '  Ordem % concluída.', v_ordem.ordem_id;
        ELSE
            UPDATE OrdensCompra
            SET quantidade_kwh = v_quantidade_rest
            WHERE ordem_id = v_ordem.ordem_id;
            RAISE NOTICE '  Ordem % parcialmente processada (resta % kWh).',
                v_ordem.ordem_id, v_quantidade_rest;
        END IF;
    END LOOP;

    RAISE NOTICE 'sp_MatchingEngine concluído. Total de matches realizados: %', v_matches;
END;
$$;


-- -------------------------------------------------------------
-- 08-triggers.sql
-- -------------------------------------------------------------

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
