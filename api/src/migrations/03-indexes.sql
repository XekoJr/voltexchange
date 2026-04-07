-- Utilizadores
CREATE INDEX idx_utilizadores_saldo
    ON Utilizadores (saldo) WHERE saldo > 0;

CREATE INDEX idx_utilizadores_data_criacao
    ON Utilizadores (data_criacao DESC);


-- Contadores
CREATE INDEX idx_contadores_utilizador_id
    ON Contadores (utilizador_id);

CREATE INDEX idx_contadores_estado
    ON Contadores (estado);

CREATE INDEX idx_contadores_regiao
    ON Contadores (regiao);


-- Leituras (indices propagam para todas as particoes)

-- GIN para queries JSONB (temperatura, erro_codigo)
CREATE INDEX idx_leituras_dados_audit_gin
    ON Leituras USING GIN (dados_audit);

-- Composto para queries por contador num periodo
CREATE INDEX idx_leituras_contador_data
    ON Leituras (contador_id, data_hora DESC);

CREATE INDEX idx_leituras_data_hora
    ON Leituras (data_hora DESC);

-- Extracao numerica de temperatura do JSONB
CREATE INDEX idx_leituras_temperatura
    ON Leituras ((( dados_audit->>'temperatura')::numeric))
    WHERE dados_audit ? 'temperatura';


-- OfertasVenda
CREATE INDEX idx_ofertas_vendedor_id
    ON OfertasVenda (vendedor_id);

-- Ofertas ativas ordenadas por preco (listagem do mercado)
CREATE INDEX idx_ofertas_ativas_preco
    ON OfertasVenda (preco_unitario ASC, data_criacao ASC)
    WHERE estado = 'ATIVA';

-- Matching engine com filtro por regiao
CREATE INDEX idx_ofertas_ativas_regiao_preco
    ON OfertasVenda (regiao, preco_unitario ASC, data_criacao ASC)
    WHERE estado = 'ATIVA';

CREATE INDEX idx_ofertas_data_criacao
    ON OfertasVenda (data_criacao DESC);


-- OrdensCompra
CREATE INDEX idx_ordens_comprador_id
    ON OrdensCompra (comprador_id);

-- Ordens pendentes FIFO para matching engine
CREATE INDEX idx_ordens_pendentes_data
    ON OrdensCompra (data_criacao ASC)
    WHERE estado = 'PENDENTE';

CREATE INDEX idx_ordens_pendentes_regiao
    ON OrdensCompra (regiao, preco_maximo DESC, data_criacao ASC)
    WHERE estado = 'PENDENTE';


-- Transacoes
CREATE INDEX idx_transacoes_comprador_data
    ON Transacoes (comprador_id, data_transacao DESC);

CREATE INDEX idx_transacoes_vendedor_data
    ON Transacoes (vendedor_id, data_transacao DESC);

CREATE INDEX idx_transacoes_oferta_id
    ON Transacoes (oferta_id);

CREATE INDEX idx_transacoes_ordem_id
    ON Transacoes (ordem_id);

CREATE INDEX idx_transacoes_data
    ON Transacoes (data_transacao DESC);

CREATE INDEX idx_transacoes_tipo
    ON Transacoes (tipo_transacao);
