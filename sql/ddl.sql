-- -------------------------------------------------------------
-- 01-schema.sql
-- -------------------------------------------------------------
DROP TABLE IF EXISTS Transacoes CASCADE;
DROP TABLE IF EXISTS OrdensCompra CASCADE;
DROP TABLE IF EXISTS OfertasVenda CASCADE;
DROP TABLE IF EXISTS Leituras CASCADE;
DROP TABLE IF EXISTS Contadores CASCADE;
DROP TABLE IF EXISTS Utilizadores CASCADE;

CREATE TABLE Utilizadores (
    utilizador_id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    saldo NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimo_acesso TIMESTAMP,
    CONSTRAINT chk_utilizadores_saldo CHECK (saldo >= 0),
    CONSTRAINT chk_utilizadores_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE TABLE Contadores (
    contador_id SERIAL PRIMARY KEY,
    utilizador_id INTEGER NOT NULL,
    numero_serie VARCHAR(50) NOT NULL UNIQUE,
    estado VARCHAR(20) DEFAULT 'ATIVO' NOT NULL,
    data_instalacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    regiao VARCHAR(100),
    CONSTRAINT fk_contadores_utilizador
        FOREIGN KEY (utilizador_id)
        REFERENCES Utilizadores(utilizador_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_contadores_estado
        CHECK (estado IN ('ATIVO', 'MANUTENCAO'))
);

-- Tabela particionada por data_hora (RANGE)
CREATE TABLE Leituras (
    leitura_id BIGSERIAL,
    contador_id INTEGER NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    kwh_leitura NUMERIC(10, 3) NOT NULL,
    dados_audit JSONB,
    PRIMARY KEY (leitura_id, data_hora),
    CONSTRAINT fk_leituras_contador
        FOREIGN KEY (contador_id)
        REFERENCES Contadores(contador_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_leituras_kwh CHECK (kwh_leitura >= 0)
) PARTITION BY RANGE (data_hora);

CREATE TABLE OfertasVenda (
    oferta_id SERIAL PRIMARY KEY,
    vendedor_id INTEGER NOT NULL,
    quantidade_kwh NUMERIC(10, 3) NOT NULL,
    preco_unitario NUMERIC(8, 4) NOT NULL,
    estado VARCHAR(20) DEFAULT 'ATIVA' NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_expiracao TIMESTAMP,
    regiao VARCHAR(100),
    CONSTRAINT fk_ofertas_vendedor
        FOREIGN KEY (vendedor_id)
        REFERENCES Utilizadores(utilizador_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_ofertas_quantidade CHECK (quantidade_kwh >= 0),
    CONSTRAINT chk_ofertas_preco CHECK (preco_unitario > 0),
    CONSTRAINT chk_ofertas_estado CHECK (estado IN ('ATIVA', 'VENDIDA', 'CANCELADA')),
    CONSTRAINT chk_ofertas_expiracao CHECK (data_expiracao IS NULL OR data_expiracao > data_criacao)
);

CREATE TABLE OrdensCompra (
    ordem_id SERIAL PRIMARY KEY,
    comprador_id INTEGER NOT NULL,
    quantidade_kwh NUMERIC(10, 3) NOT NULL,
    preco_maximo NUMERIC(8, 4) NOT NULL,
    estado VARCHAR(20) DEFAULT 'PENDENTE' NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    regiao VARCHAR(100),
    CONSTRAINT fk_ordens_comprador
        FOREIGN KEY (comprador_id)
        REFERENCES Utilizadores(utilizador_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_ordens_quantidade CHECK (quantidade_kwh > 0),
    CONSTRAINT chk_ordens_preco CHECK (preco_maximo > 0),
    CONSTRAINT chk_ordens_estado CHECK (estado IN ('PENDENTE', 'CONCLUIDA', 'CANCELADA'))
);

CREATE TABLE Transacoes (
    transacao_id SERIAL PRIMARY KEY,
    oferta_id INTEGER,
    ordem_id INTEGER,
    comprador_id INTEGER NOT NULL,
    vendedor_id INTEGER NOT NULL,
    quantidade_kwh NUMERIC(10, 3) NOT NULL,
    preco_unitario NUMERIC(8, 4) NOT NULL,
    valor_total NUMERIC(12, 2) NOT NULL,
    data_transacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tipo_transacao VARCHAR(20),
    CONSTRAINT fk_transacoes_oferta
        FOREIGN KEY (oferta_id) REFERENCES OfertasVenda(oferta_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_transacoes_ordem
        FOREIGN KEY (ordem_id) REFERENCES OrdensCompra(ordem_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_transacoes_comprador
        FOREIGN KEY (comprador_id) REFERENCES Utilizadores(utilizador_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_transacoes_vendedor
        FOREIGN KEY (vendedor_id) REFERENCES Utilizadores(utilizador_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_transacoes_quantidade CHECK (quantidade_kwh > 0),
    CONSTRAINT chk_transacoes_preco CHECK (preco_unitario > 0),
    CONSTRAINT chk_transacoes_valor CHECK (valor_total > 0),
    CONSTRAINT chk_transacoes_tipo CHECK (tipo_transacao IN ('DIRETA', 'MATCHED')),
    CONSTRAINT chk_transacoes_diferentes CHECK (comprador_id != vendedor_id)
);


-- -------------------------------------------------------------
-- 02-partitions.sql
-- -------------------------------------------------------------

-- PARTITIONS 2025
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


-- PARTITIONS 2026
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


-- -------------------------------------------------------------
-- 03-indexes.sql
-- -------------------------------------------------------------

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
