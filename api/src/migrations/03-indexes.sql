-- Utilizadores

-- Email já tem UNIQUE constraint (index implícito), sem necessidade de criar
-- Índice parcial em utilizadores com saldo positivo (útil para validação de compra)
CREATE INDEX idx_utilizadores_saldo
    ON Utilizadores (saldo)
    WHERE saldo > 0;

-- Índice em data_criacao para queries de auditoria temporal
CREATE INDEX idx_utilizadores_data_criacao
    ON Utilizadores (data_criacao DESC);


-- Contadores

-- FK lookup: buscar contadores de um utilizador (usado em quase todos os pedidos)
CREATE INDEX idx_contadores_utilizador_id
    ON Contadores (utilizador_id);

-- Filtro por estado (ATIVO / MANUTENCAO)
CREATE INDEX idx_contadores_estado
    ON Contadores (estado);

-- Filtro por regiao
CREATE INDEX idx_contadores_regiao
    ON Contadores (regiao);


-- Leituras (tabela PARTICIONADA — índices propagam para todas as partições)

-- GIN index para queries JSONB (temperatura > 80, presença de erro_codigo)
-- OBRIGATÓRIO — referenciado no relatório e na query de anomalias do admin
CREATE INDEX idx_leituras_dados_audit_gin
    ON Leituras USING GIN (dados_audit);

-- Índice composto para queries por contador num período (exploita partition pruning)
-- Cobre a query: WHERE contador_id = $1 AND data_hora BETWEEN $2 AND $3
CREATE INDEX idx_leituras_contador_data
    ON Leituras (contador_id, data_hora DESC);

-- Índice em data_hora para range scans e partition pruning
CREATE INDEX idx_leituras_data_hora
    ON Leituras (data_hora DESC);

-- Índice específico para extração numérica de temperatura no JSONB
-- Acelera queries que castam dados_audit->>'temperatura' para numeric
CREATE INDEX idx_leituras_temperatura
    ON Leituras ((( dados_audit->>'temperatura')::numeric))
    WHERE dados_audit ? 'temperatura';


-- OfertasVenda

-- FK lookup: ofertas de um vendedor
CREATE INDEX idx_ofertas_vendedor_id
    ON OfertasVenda (vendedor_id);

-- Índice composto para listagem de ofertas ativas ordenadas por preço (query principal do mercado)
-- Cobre: WHERE estado='ATIVA' ORDER BY preco_unitario ASC
CREATE INDEX idx_ofertas_ativas_preco
    ON OfertasVenda (preco_unitario ASC, data_criacao ASC)
    WHERE estado = 'ATIVA';

-- Índice parcial composto para matching engine e filtro por região
-- Cobre: WHERE estado='ATIVA' AND regiao=$1 ORDER BY preco_unitario ASC
CREATE INDEX idx_ofertas_ativas_regiao_preco
    ON OfertasVenda (regiao, preco_unitario ASC, data_criacao ASC)
    WHERE estado = 'ATIVA';

-- Índice em data_criacao para ordenação temporal
CREATE INDEX idx_ofertas_data_criacao
    ON OfertasVenda (data_criacao DESC);


-- OrdensCompra

-- FK lookup: ordens de um comprador
CREATE INDEX idx_ordens_comprador_id
    ON OrdensCompra (comprador_id);

-- Índice composto para matching engine (ordens pendentes por data FIFO)
-- Cobre: WHERE estado='PENDENTE' ORDER BY data_criacao ASC
CREATE INDEX idx_ordens_pendentes_data
    ON OrdensCompra (data_criacao ASC)
    WHERE estado = 'PENDENTE';

-- Índice parcial composto para matching com filtro por região
CREATE INDEX idx_ordens_pendentes_regiao
    ON OrdensCompra (regiao, preco_maximo DESC, data_criacao ASC)
    WHERE estado = 'PENDENTE';


-- Transacoes

-- Índice composto por comprador + data (queries do histórico do comprador)
CREATE INDEX idx_transacoes_comprador_data
    ON Transacoes (comprador_id, data_transacao DESC);

-- Índice composto por vendedor + data (queries do histórico do vendedor)
CREATE INDEX idx_transacoes_vendedor_data
    ON Transacoes (vendedor_id, data_transacao DESC);

-- FK lookup
CREATE INDEX idx_transacoes_oferta_id
    ON Transacoes (oferta_id);

CREATE INDEX idx_transacoes_ordem_id
    ON Transacoes (ordem_id);

-- Índice em data_transacao para queries temporais (admin)
CREATE INDEX idx_transacoes_data
    ON Transacoes (data_transacao DESC);

-- Índice em tipo_transacao (DIRETA / MATCHED) para filtros analíticos
CREATE INDEX idx_transacoes_tipo
    ON Transacoes (tipo_transacao);
