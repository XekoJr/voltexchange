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
    
    -- Constraints
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

CREATE TABLE Leituras (
    leitura_id BIGSERIAL,
    contador_id INTEGER NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    kwh_leitura NUMERIC(10, 3) NOT NULL,
    dados_audit JSONB,
    
    -- Primary Key
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
