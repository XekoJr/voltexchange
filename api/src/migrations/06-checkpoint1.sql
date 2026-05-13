-- Exercicio 1: Trigger de Protecao Financeira
CREATE OR REPLACE FUNCTION fn_ProtegerUtilizadores()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_ofertas_ativas INTEGER;
BEGIN
    -- Regra 1: bloquear se saldo positivo
    IF OLD.saldo > 0 THEN
        RAISE EXCEPTION
            'Nao e possivel eliminar o utilizador % — tem saldo positivo de €%. Efectue o levantamento primeiro.',
            OLD.utilizador_id, OLD.saldo;
    END IF;

    -- Regra 2: bloquear se tem ofertas ATIVAS
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
    -- Verificar se o utilizador existe
    IF NOT EXISTS (
        SELECT 1 FROM Utilizadores WHERE utilizador_id = p_utilizador_id
    ) THEN
        RAISE EXCEPTION 'Utilizador % nao encontrado.', p_utilizador_id;
    END IF;

    -- Colocar todos os contadores em MANUTENCAO
    UPDATE Contadores
    SET estado = 'MANUTENCAO'
    WHERE utilizador_id = p_utilizador_id;

    -- Cancelar todas as ofertas ATIVAS
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




-- TESTES
-- 1
DELETE FROM Utilizadores WHERE utilizador_id = 1;

-- 2
CALL sp_QuarentenaUtilizador(7);


SELECT contador_id, estado FROM Contadores WHERE utilizador_id = 7;
SELECT oferta_id, estado FROM OfertasVenda WHERE vendedor_id = 7;