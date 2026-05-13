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
        RAISE EXCEPTION 'Quantidade solicitada (% kWh) excede o disponível (% kWh) na oferta %.',
            p_quantidade, v_oferta.quantidade_kwh, p_oferta_id;
    END IF;

    IF p_comprador_id = v_oferta.vendedor_id THEN
        RAISE EXCEPTION 'Comprador e vendedor não podem ser o mesmo utilizador.';
    END IF;

    v_valor_total := ROUND(p_quantidade * v_oferta.preco_unitario, 2);

    SELECT saldo
    INTO v_comprador_saldo
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

    RAISE NOTICE 'Compra direta concluída: oferta=%, comprador=%, vendedor=%, qty=% kWh, valor=€%',
        p_oferta_id, p_comprador_id, v_oferta.vendedor_id, p_quantidade, v_valor_total;
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
