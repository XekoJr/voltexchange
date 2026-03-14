-- ============================================================================
-- VOLTEXCHANGE - Script DDL (Data Definition Language)
-- Base de Dados II - Sistema de Mercado P2P de Energia
-- ============================================================================
-- Descrição: Criação completa da estrutura da base de dados
-- Autor: Grupo [NÚMERO]
-- Data: Março 2026
-- PostgreSQL: 16+
-- ============================================================================

-- Limpar base de dados existente
DROP TABLE IF EXISTS Transacoes CASCADE;
DROP TABLE IF EXISTS OrdensCompra CASCADE;
DROP TABLE IF EXISTS OfertasVenda CASCADE;
DROP TABLE IF EXISTS Leituras CASCADE;
DROP TABLE IF EXISTS Contadores CASCADE;
DROP TABLE IF EXISTS Utilizadores CASCADE;

-- ============================================================================
-- TABELA 1: Utilizadores
-- ============================================================================
-- Descrição: Armazena todos os utilizadores da plataforma (prosumers e consumidores)
-- Regras de Negócio:
--   - Email único (usado para login)
--   - Password sempre encriptada (BCrypt)
--   - Saldo nunca negativo
-- ============================================================================

CREATE TABLE Utilizadores (
    utilizador_id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    saldo NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimo_acesso TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_utilizadores_saldo CHECK (saldo >= 0),
    CONSTRAINT chk_utilizadores_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Comentários da tabela
COMMENT ON TABLE Utilizadores IS 'Utilizadores da plataforma VoltExchange';
COMMENT ON COLUMN Utilizadores.utilizador_id IS 'Identificador único do utilizador';
COMMENT ON COLUMN Utilizadores.email IS 'Email único para autenticação';
COMMENT ON COLUMN Utilizadores.password_hash IS 'Hash BCrypt da password (nunca texto limpo)';
COMMENT ON COLUMN Utilizadores.saldo IS 'Saldo disponível para transações (EUR)';

-- Índices para performance
CREATE INDEX idx_utilizadores_email ON Utilizadores(email);
CREATE INDEX idx_utilizadores_saldo ON Utilizadores(saldo) WHERE saldo > 0;
CREATE INDEX idx_utilizadores_datacriacao ON Utilizadores(data_criacao DESC);


-- ============================================================================
-- TABELA 2: Contadores
-- ============================================================================
-- Descrição: Contadores de energia associados a cada utilizador
-- Regras de Negócio:
--   - Cada contador tem número de série único
--   - Estado alterado automaticamente por trigger de anomalias
--   - Região usada para matching de proximidade
-- ============================================================================

CREATE TABLE Contadores (
    contador_id SERIAL PRIMARY KEY,
    utilizador_id INTEGER NOT NULL,
    numero_serie VARCHAR(50) NOT NULL UNIQUE,
    estado VARCHAR(20) DEFAULT 'ATIVO' NOT NULL,
    data_instalacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    regiao VARCHAR(100),
    
    -- Foreign Keys
    CONSTRAINT fk_contadores_utilizador 
        FOREIGN KEY (utilizador_id) 
        REFERENCES Utilizadores(utilizador_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_contadores_estado 
        CHECK (estado IN ('ATIVO', 'MANUTENCAO'))
);

-- Comentários da tabela
COMMENT ON TABLE Contadores IS 'Contadores de energia dos utilizadores';
COMMENT ON COLUMN Contadores.numero_serie IS 'Número de série único do contador (físico)';
COMMENT ON COLUMN Contadores.estado IS 'Estado operacional: ATIVO ou MANUTENCAO';
COMMENT ON COLUMN Contadores.regiao IS 'Região geográfica (para matching de proximidade)';

-- Índices para performance
CREATE INDEX idx_contadores_utilizador ON Contadores(utilizador_id);
CREATE INDEX idx_contadores_estado ON Contadores(estado);
CREATE INDEX idx_contadores_regiao ON Contadores(regiao);
CREATE INDEX idx_contadores_serie ON Contadores(numero_serie);


-- ============================================================================
-- TABELA 3: Leituras (PARTICIONADA)
-- ============================================================================
-- Descrição: Leituras de energia dos contadores (milhões de registos)
-- Estratégia: Particionamento por RANGE em DataHora (mensal)
-- Regras de Negócio:
--   - Particionamento obrigatório para performance
--   - DadosAudit em JSONB para flexibilidade
--   - Anomalias: temperatura > 80 OU erro_codigo não nulo
-- ============================================================================

CREATE TABLE Leituras (
    leitura_id BIGSERIAL,
    contador_id INTEGER NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    kwh_leitura NUMERIC(10, 3) NOT NULL,
    dados_audit JSONB,
    
    -- Primary Key composta (necessária para particionamento)
    PRIMARY KEY (leitura_id, data_hora),
    
    -- Foreign Key
    CONSTRAINT fk_leituras_contador 
        FOREIGN KEY (contador_id) 
        REFERENCES Contadores(contador_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_leituras_kwh CHECK (kwh_leitura >= 0)
    
) PARTITION BY RANGE (data_hora);

-- Comentários da tabela
COMMENT ON TABLE Leituras IS 'Leituras de energia dos contadores (particionada por mês)';
COMMENT ON COLUMN Leituras.dados_audit IS 'Dados técnicos em JSON: {temperatura, voltagem, erro_codigo}';
COMMENT ON COLUMN Leituras.kwh_leitura IS 'Quantidade de energia lida (kWh)';

-- ============================================================================
-- CRIAÇÃO DE PARTIÇÕES (2025-2026)
-- ============================================================================
-- Nota: Criar partições para 24 meses de operação
-- ============================================================================

-- Ano 2025
CREATE TABLE Leituras_2025_01 PARTITION OF Leituras
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE Leituras_2025_02 PARTITION OF Leituras
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE Leituras_2025_03 PARTITION OF Leituras
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

CREATE TABLE Leituras_2025_04 PARTITION OF Leituras
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

CREATE TABLE Leituras_2025_05 PARTITION OF Leituras
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

CREATE TABLE Leituras_2025_06 PARTITION OF Leituras
    FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

CREATE TABLE Leituras_2025_07 PARTITION OF Leituras
    FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

CREATE TABLE Leituras_2025_08 PARTITION OF Leituras
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE Leituras_2025_09 PARTITION OF Leituras
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE Leituras_2025_10 PARTITION OF Leituras
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE Leituras_2025_11 PARTITION OF Leituras
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE Leituras_2025_12 PARTITION OF Leituras
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- Ano 2026
CREATE TABLE Leituras_2026_01 PARTITION OF Leituras
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE Leituras_2026_02 PARTITION OF Leituras
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE Leituras_2026_03 PARTITION OF Leituras
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE Leituras_2026_04 PARTITION OF Leituras
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE Leituras_2026_05 PARTITION OF Leituras
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE Leituras_2026_06 PARTITION OF Leituras
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE TABLE Leituras_2026_07 PARTITION OF Leituras
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

CREATE TABLE Leituras_2026_08 PARTITION OF Leituras
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE Leituras_2026_09 PARTITION OF Leituras
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE TABLE Leituras_2026_10 PARTITION OF Leituras
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

CREATE TABLE Leituras_2026_11 PARTITION OF Leituras
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

CREATE TABLE Leituras_2026_12 PARTITION OF Leituras
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- Índices para Leituras (aplicam-se a todas as partições)
CREATE INDEX idx_leituras_contador_data ON Leituras(contador_id, data_hora DESC);
CREATE INDEX idx_leituras_datahora ON Leituras(data_hora DESC);

-- Índice GIN para pesquisas JSONB (anomalias)
CREATE INDEX idx_leituras_dados_audit ON Leituras USING GIN (dados_audit);

-- Índice específico para temperatura (anomalias)
CREATE INDEX idx_leituras_temperatura ON Leituras (((dados_audit->>'temperatura')::NUMERIC))
    WHERE ((dados_audit->>'temperatura')::NUMERIC) > 80;


-- ============================================================================
-- TABELA 4: OfertasVenda
-- ============================================================================
-- Descrição: Ofertas de energia colocadas por vendedores (prosumers)
-- Regras de Negócio:
--   - Matching engine usa índices em (Estado, PrecoUnitario)
--   - Região importante para proximidade geográfica
--   - DataExpiracao opcional (para ofertas temporárias)
-- ============================================================================

CREATE TABLE OfertasVenda (
    oferta_id SERIAL PRIMARY KEY,
    vendedor_id INTEGER NOT NULL,
    quantidade_kwh NUMERIC(10, 3) NOT NULL,
    preco_unitario NUMERIC(8, 4) NOT NULL,
    estado VARCHAR(20) DEFAULT 'ATIVA' NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_expiracao TIMESTAMP,
    regiao VARCHAR(100),
    
    -- Foreign Key
    CONSTRAINT fk_ofertas_vendedor 
        FOREIGN KEY (vendedor_id) 
        REFERENCES Utilizadores(utilizador_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_ofertas_quantidade CHECK (quantidade_kwh > 0),
    CONSTRAINT chk_ofertas_preco CHECK (preco_unitario > 0),
    CONSTRAINT chk_ofertas_estado CHECK (estado IN ('ATIVA', 'VENDIDA', 'CANCELADA')),
    CONSTRAINT chk_ofertas_expiracao CHECK (data_expiracao IS NULL OR data_expiracao > data_criacao)
);

-- Comentários da tabela
COMMENT ON TABLE OfertasVenda IS 'Ofertas de venda de energia colocadas por prosumers';
COMMENT ON COLUMN OfertasVenda.preco_unitario IS 'Preço por kWh (EUR)';
COMMENT ON COLUMN OfertasVenda.estado IS 'ATIVA (disponível), VENDIDA (concluída), CANCELADA';
COMMENT ON COLUMN OfertasVenda.regiao IS 'Região para matching de proximidade';

-- Índices críticos para Matching Engine
CREATE INDEX idx_ofertas_matching ON OfertasVenda(estado, preco_unitario ASC, data_criacao ASC)
    WHERE estado = 'ATIVA';

CREATE INDEX idx_ofertas_vendedor ON OfertasVenda(vendedor_id, estado);
CREATE INDEX idx_ofertas_regiao ON OfertasVenda(regiao) WHERE estado = 'ATIVA';
CREATE INDEX idx_ofertas_data ON OfertasVenda(data_criacao DESC);


-- ============================================================================
-- TABELA 5: OrdensCompra
-- ============================================================================
-- Descrição: Ordens de compra futura (para matching engine)
-- Regras de Negócio:
--   - Matching automático quando há oferta compatível
--   - Prioridade: preço → região → antiguidade (FIFO)
--   - PrecoMaximo: máximo que comprador aceita pagar
-- ============================================================================

CREATE TABLE OrdensCompra (
    ordem_id SERIAL PRIMARY KEY,
    comprador_id INTEGER NOT NULL,
    quantidade_kwh NUMERIC(10, 3) NOT NULL,
    preco_maximo NUMERIC(8, 4) NOT NULL,
    estado VARCHAR(20) DEFAULT 'PENDENTE' NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    regiao VARCHAR(100),
    
    -- Foreign Key
    CONSTRAINT fk_ordens_comprador 
        FOREIGN KEY (comprador_id) 
        REFERENCES Utilizadores(utilizador_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_ordens_quantidade CHECK (quantidade_kwh > 0),
    CONSTRAINT chk_ordens_preco CHECK (preco_maximo > 0),
    CONSTRAINT chk_ordens_estado CHECK (estado IN ('PENDENTE', 'CONCLUIDA', 'CANCELADA'))
);

-- Comentários da tabela
COMMENT ON TABLE OrdensCompra IS 'Ordens de compra futura para matching automático';
COMMENT ON COLUMN OrdensCompra.preco_maximo IS 'Preço máximo que comprador aceita pagar por kWh (EUR)';
COMMENT ON COLUMN OrdensCompra.estado IS 'PENDENTE (aguarda match), CONCLUIDA, CANCELADA';

-- Índices críticos para Matching Engine
CREATE INDEX idx_ordens_matching ON OrdensCompra(estado, preco_maximo DESC, data_criacao ASC)
    WHERE estado = 'PENDENTE';

CREATE INDEX idx_ordens_comprador ON OrdensCompra(comprador_id, estado);
CREATE INDEX idx_ordens_regiao ON OrdensCompra(regiao) WHERE estado = 'PENDENTE';
CREATE INDEX idx_ordens_data ON OrdensCompra(data_criacao DESC);


-- ============================================================================
-- TABELA 6: Transacoes
-- ============================================================================
-- Descrição: Histórico de todas as transações completadas
-- Regras de Negócio:
--   - OfertaID nullable (pode ser ordem matched sem oferta específica)
--   - Registo imutável (auditoria)
--   - TipoTransacao: DIRETA (compra imediata) ou MATCHED (via engine)
-- ============================================================================

CREATE TABLE Transacoes (
    transacao_id SERIAL PRIMARY KEY,
    oferta_id INTEGER,  -- Nullable
    ordem_id INTEGER,   -- Nullable (para matched transactions)
    comprador_id INTEGER NOT NULL,
    vendedor_id INTEGER NOT NULL,
    quantidade_kwh NUMERIC(10, 3) NOT NULL,
    preco_unitario NUMERIC(8, 4) NOT NULL,
    valor_total NUMERIC(12, 2) NOT NULL,
    data_transacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tipo_transacao VARCHAR(20),
    
    -- Foreign Keys
    CONSTRAINT fk_transacoes_oferta 
        FOREIGN KEY (oferta_id) 
        REFERENCES OfertasVenda(oferta_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_transacoes_ordem 
        FOREIGN KEY (ordem_id) 
        REFERENCES OrdensCompra(ordem_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_transacoes_comprador 
        FOREIGN KEY (comprador_id) 
        REFERENCES Utilizadores(utilizador_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_transacoes_vendedor 
        FOREIGN KEY (vendedor_id) 
        REFERENCES Utilizadores(utilizador_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_transacoes_quantidade CHECK (quantidade_kwh > 0),
    CONSTRAINT chk_transacoes_preco CHECK (preco_unitario > 0),
    CONSTRAINT chk_transacoes_valor CHECK (valor_total > 0),
    CONSTRAINT chk_transacoes_tipo CHECK (tipo_transacao IN ('DIRETA', 'MATCHED')),
    
    -- Validação: comprador != vendedor
    CONSTRAINT chk_transacoes_diferentes CHECK (comprador_id != vendedor_id)
);

-- Comentários da tabela
COMMENT ON TABLE Transacoes IS 'Histórico de transações completadas (imutável para auditoria)';
COMMENT ON COLUMN Transacoes.tipo_transacao IS 'DIRETA (compra imediata) ou MATCHED (via matching engine)';
COMMENT ON COLUMN Transacoes.valor_total IS 'Valor total da transação (EUR) = quantidade_kwh * preco_unitario';

-- Índices para auditoria e consultas
CREATE INDEX idx_transacoes_comprador ON Transacoes(comprador_id, data_transacao DESC);
CREATE INDEX idx_transacoes_vendedor ON Transacoes(vendedor_id, data_transacao DESC);
CREATE INDEX idx_transacoes_oferta ON Transacoes(oferta_id);
CREATE INDEX idx_transacoes_ordem ON Transacoes(ordem_id);
CREATE INDEX idx_transacoes_data ON Transacoes(data_transacao DESC);
CREATE INDEX idx_transacoes_tipo ON Transacoes(tipo_transacao);


-- ============================================================================
-- VIEWS ÚTEIS (Opcional mas recomendado)
-- ============================================================================

-- View: Ofertas ativas com informação do vendedor
CREATE OR REPLACE VIEW vw_OfertasAtivas AS
SELECT 
    o.oferta_id,
    o.vendedor_id,
    u.nome AS nome_vendedor,
    u.email AS email_vendedor,
    o.quantidade_kwh,
    o.preco_unitario,
    o.regiao,
    o.data_criacao,
    o.data_expiracao,
    (o.quantidade_kwh * o.preco_unitario) AS valor_total
FROM OfertasVenda o
JOIN Utilizadores u ON o.vendedor_id = u.utilizador_id
WHERE o.estado = 'ATIVA'
  AND (o.data_expiracao IS NULL OR o.data_expiracao > CURRENT_TIMESTAMP)
ORDER BY o.preco_unitario ASC, o.data_criacao ASC;

COMMENT ON VIEW vw_OfertasAtivas IS 'Ofertas ativas disponíveis para compra';

-- View: Ordens pendentes com informação do comprador
CREATE OR REPLACE VIEW vw_OrdensPendentes AS
SELECT 
    o.ordem_id,
    o.comprador_id,
    u.nome AS nome_comprador,
    u.email AS email_comprador,
    o.quantidade_kwh,
    o.preco_maximo,
    o.regiao,
    o.data_criacao,
    (o.quantidade_kwh * o.preco_maximo) AS valor_maximo
FROM OrdensCompra o
JOIN Utilizadores u ON o.comprador_id = u.utilizador_id
WHERE o.estado = 'PENDENTE'
ORDER BY o.preco_maximo DESC, o.data_criacao ASC;

COMMENT ON VIEW vw_OrdensPendentes IS 'Ordens de compra pendentes aguardando matching';

-- View: Anomalias detectadas nas leituras
CREATE OR REPLACE VIEW vw_Anomalias AS
SELECT 
    l.leitura_id,
    l.contador_id,
    c.numero_serie,
    c.utilizador_id,
    u.nome AS nome_utilizador,
    l.data_hora,
    l.kwh_leitura,
    (l.dados_audit->>'temperatura')::NUMERIC AS temperatura,
    l.dados_audit->>'erro_codigo' AS codigo_erro,
    l.dados_audit
FROM Leituras l
JOIN Contadores c ON l.contador_id = c.contador_id
JOIN Utilizadores u ON c.utilizador_id = u.utilizador_id
WHERE (l.dados_audit->>'temperatura')::NUMERIC > 80
   OR l.dados_audit ? 'erro_codigo'
ORDER BY l.data_hora DESC;

COMMENT ON VIEW vw_Anomalias IS 'Leituras com anomalias (temperatura > 80 ou erro_codigo presente)';


-- ============================================================================
-- ESTATÍSTICAS INICIAIS
-- ============================================================================
-- Executar ANALYZE para otimizar planeador de queries
ANALYZE Utilizadores;
ANALYZE Contadores;
ANALYZE Leituras;
ANALYZE OfertasVenda;
ANALYZE OrdensCompra;
ANALYZE Transacoes;


-- ============================================================================
-- SUMÁRIO DA ESTRUTURA
-- ============================================================================

-- Verificar criação de tabelas
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS tamanho
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verificar partições criadas
SELECT 
    parent.relname AS tabela_pai,
    child.relname AS particao,
    pg_get_expr(child.relpartbound, child.oid) AS condicao
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child ON pg_inherits.inhrelid = child.oid
WHERE parent.relname = 'leituras'
ORDER BY child.relname;

-- Verificar índices criados
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(pg_class.oid)) AS tamanho
FROM pg_indexes
JOIN pg_class ON pg_class.relname = indexname
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


-- ============================================================================
-- FIM DO SCRIPT DDL
-- ============================================================================
-- Próximos passos:
-- 1. Executar 02-logic.sql (Stored Procedures e Triggers)
-- 2. Executar 03-seed.sql (Dados de teste)
-- ============================================================================
