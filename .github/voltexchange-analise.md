# VoltExchange - Análise Detalhada do Projeto
## Base de Dados II - Sistema de Mercado de Energia P2P

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Modelo de Dados](#modelo-de-dados)
4. [Lógica de Servidor (PL/pgSQL)](#lógica-de-servidor-plpgsql)
5. [API Spring Boot](#api-spring-boot)
6. [Configuração Docker](#configuração-docker)
7. [Segurança](#segurança)
8. [Performance e Otimização](#performance-e-otimização)
9. [Checkpoints e Entregas](#checkpoints-e-entregas)
10. [Plano de Implementação](#plano-de-implementação)

---

## 🎯 Visão Geral

### Objetivo do Projeto
Desenvolver o backend completo para a plataforma **VoltExchange**, um mercado P2P de energia onde prosumers (produtores domésticos com painéis solares) podem vender excedentes de energia a vizinhos.

### Tecnologias Obrigatórias
- **SGBD**: PostgreSQL (servidor institucional da escola)
- **API**: Spring Boot (Java)
- **Containerização**: Docker (desenvolvimento local)
- **Deploy**: Serviço Cloud (Vercel, Render, Railway)

### Critérios de Avaliação
- ✅ Integridade de dados (ACID)
- ✅ Gestão eficiente de milhões de leituras
- ✅ Segurança (SQL Injection, encriptação)
- ✅ Performance (índices, particionamento)
- ✅ Lógica de negócio em PL/pgSQL

---

## 🏗️ Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTE WEB/MOBILE                     │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP/REST
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    API SPRING BOOT                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Controllers  │  │  Services    │  │  Security    │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
└────────────────────────┬────────────────────────────────────┘
                         │ JDBC/JPA
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              POSTGRESQL (Servidor da Escola)                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  STORED PROCEDURES                                      │ │
│  │  • sp_MatchingEngine                                    │ │
│  │  • sp_ExecutarCompraDireta                             │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  TRIGGERS                                               │ │
│  │  • trg_DetectarAnomalias                               │ │
│  │  • trg_ProtegerUtilizadores                            │ │
│  │  • trg_AutoMatching (opcional - excelência)            │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  TABELAS                                                │ │
│  │  Utilizadores | Contadores | Leituras (particionada)   │ │
│  │  OfertasVenda | OrdensCompra | Transacoes             │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Modelo de Dados

### 1️⃣ Tabela: Utilizadores
Armazena informação dos utilizadores (prosumers e consumidores).

```sql
CREATE TABLE Utilizadores (
    UtilizadorID SERIAL PRIMARY KEY,
    Nome VARCHAR(200) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,  -- bcrypt/Argon2
    Saldo NUMERIC(12, 2) DEFAULT 0.00 CHECK (Saldo >= 0),
    DataCriacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UltimoAcesso TIMESTAMP
);

-- Índices
CREATE INDEX idx_utilizadores_email ON Utilizadores(Email);
CREATE INDEX idx_utilizadores_saldo ON Utilizadores(Saldo) WHERE Saldo > 0;
```

**Campos Importantes:**
- `PasswordHash`: Nunca guardar passwords em texto limpo
- `Saldo`: Controlo financeiro para transações
- `Email`: Único para autenticação

---

### 2️⃣ Tabela: Contadores
Contadores de energia associados a cada utilizador.

```sql
CREATE TABLE Contadores (
    ContadorID SERIAL PRIMARY KEY,
    UtilizadorID INTEGER NOT NULL,
    NumeroSerie VARCHAR(50) UNIQUE NOT NULL,
    Estado VARCHAR(20) DEFAULT 'ATIVO' CHECK (Estado IN ('ATIVO', 'MANUTENCAO')),
    DataInstalacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Regiao VARCHAR(100),  -- Para matching de proximidade
    FOREIGN KEY (UtilizadorID) REFERENCES Utilizadores(UtilizadorID)
);

-- Índices
CREATE INDEX idx_contadores_utilizador ON Contadores(UtilizadorID);
CREATE INDEX idx_contadores_estado ON Contadores(Estado);
CREATE INDEX idx_contadores_regiao ON Contadores(Regiao);
```

**Campos Importantes:**
- `Estado`: Controlado por trigger quando há anomalias
- `Regiao`: Critério de matching (proximidade geográfica)

---

### 3️⃣ Tabela: Leituras (Particionada)
**CRÍTICA**: Milhões de registos - requer particionamento e otimização.

```sql
-- Tabela pai (particionada por range de data)
CREATE TABLE Leituras (
    LeituraID BIGSERIAL,
    ContadorID INTEGER NOT NULL,
    DataHora TIMESTAMP NOT NULL,
    KWh_Leitura NUMERIC(10, 3) NOT NULL CHECK (KWh_Leitura >= 0),
    DadosAudit JSONB,  -- {"temperatura": 45, "voltagem": 230, "erro_codigo": null}
    PRIMARY KEY (LeituraID, DataHora),
    FOREIGN KEY (ContadorID) REFERENCES Contadores(ContadorID)
) PARTITION BY RANGE (DataHora);

-- Criar partições mensais (exemplo para 2025-2026)
CREATE TABLE Leituras_2025_01 PARTITION OF Leituras
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE Leituras_2025_02 PARTITION OF Leituras
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- ... criar partições para todos os meses necessários

CREATE TABLE Leituras_2026_12 PARTITION OF Leituras
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- Índices em JSONB para pesquisas de anomalias
CREATE INDEX idx_leituras_dados_audit ON Leituras USING GIN (DadosAudit);
CREATE INDEX idx_leituras_contador_data ON Leituras(ContadorID, DataHora DESC);

-- Índice específico para anomalias de temperatura
CREATE INDEX idx_leituras_temperatura ON Leituras ((DadosAudit->>'temperatura'));
```

**Campos Importantes:**
- `DadosAudit`: JSONB permite estrutura flexível para logs técnicos
- **Critérios de Anomalia**:
  - `temperatura > 80` OU
  - `erro_codigo` não nulo

**Query para Anomalias:**
```sql
-- Pesquisa otimizada com índice GIN
SELECT L.LeituraID, L.ContadorID, L.DataHora, L.DadosAudit
FROM Leituras L
WHERE (DadosAudit->>'temperatura')::numeric > 80
   OR DadosAudit ? 'erro_codigo';
```

---

### 4️⃣ Tabela: OfertasVenda
Ofertas de energia colocadas por prosumers.

```sql
CREATE TABLE OfertasVenda (
    OfertaID SERIAL PRIMARY KEY,
    VendedorID INTEGER NOT NULL,
    QuantidadeKWh NUMERIC(10, 3) NOT NULL CHECK (QuantidadeKWh > 0),
    PrecoUnitario NUMERIC(8, 4) NOT NULL CHECK (PrecoUnitario > 0),
    Estado VARCHAR(20) DEFAULT 'ATIVA' CHECK (Estado IN ('ATIVA', 'VENDIDA', 'CANCELADA')),
    DataCriacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    DataExpiracao TIMESTAMP,
    Regiao VARCHAR(100),  -- Para matching de proximidade
    FOREIGN KEY (VendedorID) REFERENCES Utilizadores(UtilizadorID)
);

-- Índices para Matching Engine
CREATE INDEX idx_ofertas_estado_preco ON OfertasVenda(Estado, PrecoUnitario)
    WHERE Estado = 'ATIVA';
CREATE INDEX idx_ofertas_regiao ON OfertasVenda(Regiao) WHERE Estado = 'ATIVA';
CREATE INDEX idx_ofertas_data ON OfertasVenda(DataCriacao) WHERE Estado = 'ATIVA';
```

**Seed Obrigatório**: Mínimo 1.000 registos (Checkpoint 1)

---

### 5️⃣ Tabela: OrdensCompra
Ordens de compra (intenção futura) para o matching engine.

```sql
CREATE TABLE OrdensCompra (
    OrdemID SERIAL PRIMARY KEY,
    CompradorID INTEGER NOT NULL,
    QuantidadeKWh NUMERIC(10, 3) NOT NULL CHECK (QuantidadeKWh > 0),
    PrecoMaximo NUMERIC(8, 4) NOT NULL CHECK (PrecoMaximo > 0),
    Estado VARCHAR(20) DEFAULT 'PENDENTE' CHECK (Estado IN ('PENDENTE', 'CONCLUIDA', 'CANCELADA')),
    DataCriacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Regiao VARCHAR(100),  -- Preferência de proximidade
    FOREIGN KEY (CompradorID) REFERENCES Utilizadores(UtilizadorID)
);

-- Índices para Matching Engine
CREATE INDEX idx_ordens_estado_preco ON OrdensCompra(Estado, PrecoMaximo DESC)
    WHERE Estado = 'PENDENTE';
CREATE INDEX idx_ordens_regiao ON OrdensCompra(Regiao) WHERE Estado = 'PENDENTE';
CREATE INDEX idx_ordens_data ON OrdensCompra(DataCriacao) WHERE Estado = 'PENDENTE';
```

---

### 6️⃣ Tabela: Transacoes
Registo histórico de todas as transações completadas.

```sql
CREATE TABLE Transacoes (
    TransacaoID SERIAL PRIMARY KEY,
    OfertaID INTEGER,  -- Nullable (pode ser ordem matched)
    OrdemID INTEGER,   -- Nullable
    CompradorID INTEGER NOT NULL,
    VendedorID INTEGER NOT NULL,
    QuantidadeKWh NUMERIC(10, 3) NOT NULL,
    PrecoUnitario NUMERIC(8, 4) NOT NULL,
    ValorTotal NUMERIC(12, 2) NOT NULL,
    DataTransacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TipoTransacao VARCHAR(20) CHECK (TipoTransacao IN ('DIRETA', 'MATCHED')),
    FOREIGN KEY (OfertaID) REFERENCES OfertasVenda(OfertaID),
    FOREIGN KEY (OrdemID) REFERENCES OrdensCompra(OrdemID),
    FOREIGN KEY (CompradorID) REFERENCES Utilizadores(UtilizadorID),
    FOREIGN KEY (VendedorID) REFERENCES Utilizadores(UtilizadorID)
);

-- Índices para auditoria e análise
CREATE INDEX idx_transacoes_comprador ON Transacoes(CompradorID, DataTransacao DESC);
CREATE INDEX idx_transacoes_vendedor ON Transacoes(VendedorID, DataTransacao DESC);
CREATE INDEX idx_transacoes_data ON Transacoes(DataTransacao DESC);
```

---

## 🔧 Lógica de Servidor (PL/pgSQL)

### 1️⃣ Stored Procedure: sp_MatchingEngine

**Objetivo**: Motor de matching automático que processa ordens pendentes.

**Critérios de Matching (por ordem de prioridade)**:
1. **Preço**: `PrecoMaximo_Ordem >= PrecoUnitario_Oferta`
2. **Proximidade**: Mesma região (preferencial)
3. **Antiguidade**: Data de criação mais antiga (FIFO)

```sql
CREATE OR REPLACE PROCEDURE sp_MatchingEngine()
LANGUAGE plpgsql
AS $$
DECLARE
    v_ordem RECORD;
    v_oferta RECORD;
    v_quantidade_match NUMERIC;
    v_valor_total NUMERIC;
BEGIN
    -- Percorrer todas as ordens pendentes (FIFO)
    FOR v_ordem IN 
        SELECT * FROM OrdensCompra 
        WHERE Estado = 'PENDENTE' 
        ORDER BY DataCriacao ASC
    LOOP
        -- Procurar oferta compatível
        -- Prioridade 1: Mesma região + preço compatível
        SELECT * INTO v_oferta
        FROM OfertasVenda
        WHERE Estado = 'ATIVA'
          AND PrecoUnitario <= v_ordem.PrecoMaximo
          AND Regiao = v_ordem.Regiao
          AND QuantidadeKWh >= v_ordem.QuantidadeKWh
        ORDER BY PrecoUnitario ASC, DataCriacao ASC
        LIMIT 1;
        
        -- Se não encontrou na mesma região, procurar em qualquer região
        IF NOT FOUND THEN
            SELECT * INTO v_oferta
            FROM OfertasVenda
            WHERE Estado = 'ATIVA'
              AND PrecoUnitario <= v_ordem.PrecoMaximo
              AND QuantidadeKWh >= v_ordem.QuantidadeKWh
            ORDER BY PrecoUnitario ASC, DataCriacao ASC
            LIMIT 1;
        END IF;
        
        -- Se encontrou match, processar transação
        IF FOUND THEN
            v_quantidade_match := v_ordem.QuantidadeKWh;
            v_valor_total := v_quantidade_match * v_oferta.PrecoUnitario;
            
            -- Iniciar transação ACID
            BEGIN
                -- Debitar comprador
                UPDATE Utilizadores 
                SET Saldo = Saldo - v_valor_total
                WHERE UtilizadorID = v_ordem.CompradorID;
                
                -- Creditar vendedor
                UPDATE Utilizadores 
                SET Saldo = Saldo + v_valor_total
                WHERE UtilizadorID = v_oferta.VendedorID;
                
                -- Atualizar estado da oferta
                UPDATE OfertasVenda
                SET Estado = 'VENDIDA',
                    QuantidadeKWh = QuantidadeKWh - v_quantidade_match
                WHERE OfertaID = v_oferta.OfertaID;
                
                -- Se quantidade residual, manter ativa
                IF (v_oferta.QuantidadeKWh - v_quantidade_match) > 0 THEN
                    UPDATE OfertasVenda
                    SET Estado = 'ATIVA'
                    WHERE OfertaID = v_oferta.OfertaID;
                END IF;
                
                -- Atualizar estado da ordem
                UPDATE OrdensCompra
                SET Estado = 'CONCLUIDA'
                WHERE OrdemID = v_ordem.OrdemID;
                
                -- Registar transação
                INSERT INTO Transacoes (
                    OfertaID, OrdemID, CompradorID, VendedorID,
                    QuantidadeKWh, PrecoUnitario, ValorTotal, TipoTransacao
                ) VALUES (
                    v_oferta.OfertaID, v_ordem.OrdemID,
                    v_ordem.CompradorID, v_oferta.VendedorID,
                    v_quantidade_match, v_oferta.PrecoUnitario,
                    v_valor_total, 'MATCHED'
                );
                
                RAISE NOTICE 'Match executado: Ordem % com Oferta %', 
                    v_ordem.OrdemID, v_oferta.OfertaID;
                    
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'Erro ao processar match: %', SQLERRM;
                    ROLLBACK;
            END;
        END IF;
    END LOOP;
    
    COMMIT;
END;
$$;
```

---

### 2️⃣ Stored Procedure: sp_ExecutarCompraDireta

**Objetivo**: Compra imediata com garantia ACID.

```sql
CREATE OR REPLACE PROCEDURE sp_ExecutarCompraDireta(
    p_oferta_id INTEGER,
    p_comprador_id INTEGER,
    p_quantidade NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_oferta RECORD;
    v_valor_total NUMERIC;
    v_saldo_comprador NUMERIC;
BEGIN
    -- Bloquear oferta para evitar race conditions
    SELECT * INTO v_oferta
    FROM OfertasVenda
    WHERE OfertaID = p_oferta_id
    FOR UPDATE;
    
    -- Validações
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Oferta não encontrada: %', p_oferta_id;
    END IF;
    
    IF v_oferta.Estado != 'ATIVA' THEN
        RAISE EXCEPTION 'Oferta não está ativa: %', v_oferta.Estado;
    END IF;
    
    IF v_oferta.QuantidadeKWh < p_quantidade THEN
        RAISE EXCEPTION 'Quantidade insuficiente. Disponível: %, Solicitado: %',
            v_oferta.QuantidadeKWh, p_quantidade;
    END IF;
    
    -- Calcular valor
    v_valor_total := p_quantidade * v_oferta.PrecoUnitario;
    
    -- Verificar saldo do comprador
    SELECT Saldo INTO v_saldo_comprador
    FROM Utilizadores
    WHERE UtilizadorID = p_comprador_id
    FOR UPDATE;
    
    IF v_saldo_comprador < v_valor_total THEN
        RAISE EXCEPTION 'Saldo insuficiente. Necessário: %, Disponível: %',
            v_valor_total, v_saldo_comprador;
    END IF;
    
    -- Executar transação ACID
    BEGIN
        -- Debitar comprador
        UPDATE Utilizadores
        SET Saldo = Saldo - v_valor_total
        WHERE UtilizadorID = p_comprador_id;
        
        -- Creditar vendedor
        UPDATE Utilizadores
        SET Saldo = Saldo + v_valor_total
        WHERE UtilizadorID = v_oferta.VendedorID;
        
        -- Atualizar oferta
        UPDATE OfertasVenda
        SET QuantidadeKWh = QuantidadeKWh - p_quantidade,
            Estado = CASE 
                WHEN (QuantidadeKWh - p_quantidade) = 0 THEN 'VENDIDA'
                ELSE 'ATIVA'
            END
        WHERE OfertaID = p_oferta_id;
        
        -- Registar transação
        INSERT INTO Transacoes (
            OfertaID, CompradorID, VendedorID,
            QuantidadeKWh, PrecoUnitario, ValorTotal, TipoTransacao
        ) VALUES (
            p_oferta_id, p_comprador_id, v_oferta.VendedorID,
            p_quantidade, v_oferta.PrecoUnitario, v_valor_total, 'DIRETA'
        );
        
        RAISE NOTICE 'Compra direta executada com sucesso. Transação ID: %',
            currval('transacoes_transacaoid_seq');
            
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Erro na transação: %', SQLERRM;
            ROLLBACK;
    END;
    
    COMMIT;
END;
$$;
```

---

### 3️⃣ Trigger 1: Detecção de Anomalias

**Objetivo**: Alterar estado do contador para 'MANUTENCAO' quando detectar anomalias.

```sql
CREATE OR REPLACE FUNCTION fn_DetectarAnomalias()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_temperatura NUMERIC;
    v_tem_erro BOOLEAN;
BEGIN
    -- Extrair valores do JSONB
    v_temperatura := (NEW.DadosAudit->>'temperatura')::NUMERIC;
    v_tem_erro := (NEW.DadosAudit ? 'erro_codigo');
    
    -- Verificar critérios de anomalia
    IF v_temperatura > 80 OR v_tem_erro THEN
        -- Atualizar estado do contador
        UPDATE Contadores
        SET Estado = 'MANUTENCAO'
        WHERE ContadorID = NEW.ContadorID
          AND Estado = 'ATIVO';
        
        RAISE NOTICE 'Anomalia detectada no contador %: Temp=%, Erro=%',
            NEW.ContadorID, v_temperatura, v_tem_erro;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_DetectarAnomalias
AFTER INSERT ON Leituras
FOR EACH ROW
EXECUTE FUNCTION fn_DetectarAnomalias();
```

---

### 4️⃣ Trigger 2: Proteção de Utilizadores

**Objetivo**: Impedir remoção de utilizadores com saldo ou transações recentes.

```sql
CREATE OR REPLACE FUNCTION fn_ProtegerUtilizadores()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_tem_transacoes BOOLEAN;
BEGIN
    -- Verificar saldo positivo
    IF OLD.Saldo > 0 THEN
        RAISE EXCEPTION 'Não é possível remover utilizador com saldo positivo: %',
            OLD.Saldo;
    END IF;
    
    -- Verificar transações recentes (últimos 30 dias)
    SELECT EXISTS (
        SELECT 1 FROM Transacoes
        WHERE (CompradorID = OLD.UtilizadorID OR VendedorID = OLD.UtilizadorID)
          AND DataTransacao > CURRENT_TIMESTAMP - INTERVAL '30 days'
    ) INTO v_tem_transacoes;
    
    IF v_tem_transacoes THEN
        RAISE EXCEPTION 'Não é possível remover utilizador com transações recentes';
    END IF;
    
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_ProtegerUtilizadores
BEFORE DELETE ON Utilizadores
FOR EACH ROW
EXECUTE FUNCTION fn_ProtegerUtilizadores();
```

---

### 5️⃣ Trigger (Opcional - Excelência): Auto-Matching

**Objetivo**: Disparar matching automaticamente ao inserir ordem/oferta.

```sql
CREATE OR REPLACE FUNCTION fn_AutoMatching()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Chamar matching engine de forma assíncrona
    -- (pg_background ou NOTIFY para worker externo)
    CALL sp_MatchingEngine();
    RETURN NEW;
END;
$$;

-- Trigger para novas ordens
CREATE TRIGGER trg_AutoMatching_Ordens
AFTER INSERT ON OrdensCompra
FOR EACH ROW
WHEN (NEW.Estado = 'PENDENTE')
EXECUTE FUNCTION fn_AutoMatching();

-- Trigger para novas ofertas
CREATE TRIGGER trg_AutoMatching_Ofertas
AFTER INSERT ON OfertasVenda
FOR EACH ROW
WHEN (NEW.Estado = 'ATIVA')
EXECUTE FUNCTION fn_AutoMatching();
```

---

## 🌐 API Spring Boot

### Estrutura do Projeto

```
voltexchange-api/
├── src/main/java/com/voltexchange/
│   ├── VoltExchangeApplication.java
│   ├── config/
│   │   ├── SecurityConfig.java
│   │   ├── DatabaseConfig.java
│   │   └── CorsConfig.java
│   ├── controller/
│   │   ├── AuthController.java
│   │   ├── MeterController.java
│   │   ├── MarketController.java
│   │   └── AdminController.java
│   ├── dto/
│   │   ├── RegisterRequest.java
│   │   ├── LoginRequest.java
│   │   ├── ReadingRequest.java
│   │   ├── BuyRequest.java
│   │   └── OrderRequest.java
│   ├── entity/
│   │   ├── Utilizador.java
│   │   ├── Contador.java
│   │   ├── Leitura.java
│   │   ├── OfertaVenda.java
│   │   ├── OrdemCompra.java
│   │   └── Transacao.java
│   ├── repository/
│   │   ├── UtilizadorRepository.java
│   │   ├── ContadorRepository.java
│   │   ├── LeituraRepository.java
│   │   ├── OfertaVendaRepository.java
│   │   ├── OrdemCompraRepository.java
│   │   └── TransacaoRepository.java
│   ├── service/
│   │   ├── AuthService.java
│   │   ├── MeterService.java
│   │   ├── MarketService.java
│   │   └── AdminService.java
│   └── security/
│       ├── JwtTokenProvider.java
│       ├── JwtAuthenticationFilter.java
│       └── UserDetailsServiceImpl.java
├── src/main/resources/
│   ├── application.properties
│   └── application-prod.properties
└── pom.xml
```

---

### Configuração - pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
    </parent>
    
    <groupId>com.voltexchange</groupId>
    <artifactId>voltexchange-api</artifactId>
    <version>1.0.0</version>
    <name>VoltExchange API</name>
    
    <properties>
        <java.version>17</java.version>
    </properties>
    
    <dependencies>
        <!-- Spring Boot Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <!-- Spring Data JPA -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        
        <!-- PostgreSQL Driver -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        
        <!-- Spring Security -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        
        <!-- JWT -->
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>0.11.5</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>0.11.5</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>0.11.5</version>
            <scope>runtime</scope>
        </dependency>
        
        <!-- BCrypt -->
        <dependency>
            <groupId>org.springframework.security</groupId>
            <artifactId>spring-security-crypto</artifactId>
        </dependency>
        
        <!-- Validation -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <!-- Lombok (opcional) -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        
        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

---

### Configuração - application.properties

```properties
# Application
spring.application.name=VoltExchange API
server.port=8080

# Database - Desenvolvimento Local (Docker)
spring.datasource.url=jdbc:postgresql://localhost:5432/voltexchange
spring.datasource.username=postgres
spring.datasource.password=postgres
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA/Hibernate
spring.jpa.hibernate.ddl-auto=none
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect

# JWT
jwt.secret=VoltExchange2026SecretKeyMuitoSegura123456789
jwt.expiration=86400000

# Logging
logging.level.com.voltexchange=DEBUG
logging.level.org.springframework.security=DEBUG
```

---

### Exemplo: AuthController

```java
package com.voltexchange.controller;

import com.voltexchange.dto.LoginRequest;
import com.voltexchange.dto.RegisterRequest;
import com.voltexchange.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {
    
    private final AuthService authService;
    
    public AuthController(AuthService authService) {
        this.authService = authService;
    }
    
    /**
     * POST /api/auth/register
     * Regista novo utilizador
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }
    
    /**
     * POST /api/auth/login
     * Autentica utilizador e retorna JWT token
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }
}
```

---

### Exemplo: MarketController

```java
package com.voltexchange.controller;

import com.voltexchange.dto.BuyRequest;
import com.voltexchange.dto.OrderRequest;
import com.voltexchange.service.MarketService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/market")
@CrossOrigin(origins = "*")
public class MarketController {
    
    private final MarketService marketService;
    
    public MarketController(MarketService marketService) {
        this.marketService = marketService;
    }
    
    /**
     * POST /api/market/buy
     * Compra direta de oferta
     */
    @PostMapping("/buy")
    public ResponseEntity<?> buy(
        @Valid @RequestBody BuyRequest request,
        @AuthenticationPrincipal UserDetails userDetails
    ) {
        return ResponseEntity.ok(
            marketService.executarCompraDireta(request, userDetails.getUsername())
        );
    }
    
    /**
     * POST /api/market/order
     * Criar ordem de compra futura
     */
    @PostMapping("/order")
    public ResponseEntity<?> createOrder(
        @Valid @RequestBody OrderRequest request,
        @AuthenticationPrincipal UserDetails userDetails
    ) {
        return ResponseEntity.ok(
            marketService.criarOrdemCompra(request, userDetails.getUsername())
        );
    }
    
    /**
     * POST /api/market/match
     * Disparar matching engine manualmente (obrigatório para testes)
     */
    @PostMapping("/match")
    public ResponseEntity<?> triggerMatching() {
        marketService.executarMatching();
        return ResponseEntity.ok("Matching engine executado com sucesso");
    }
    
    /**
     * GET /api/market/offers
     * Listar ofertas ativas
     */
    @GetMapping("/offers")
    public ResponseEntity<?> listOffers() {
        return ResponseEntity.ok(marketService.listarOfertasAtivas());
    }
}
```

---

### Segurança: Prepared Statements

**CRÍTICO**: Usar sempre JPA/JDBC com parâmetros - nunca concatenar strings.

```java
// ✅ CORRETO - Prepared Statement
@Query("SELECT u FROM Utilizador u WHERE u.email = :email")
Optional<Utilizador> findByEmail(@Param("email") String email);

// ✅ CORRETO - Native Query com parâmetros
@Query(value = "SELECT * FROM Leituras WHERE ContadorID = ?1 AND DataHora > ?2", 
       nativeQuery = true)
List<Leitura> findByContadorAndDate(Integer contadorId, LocalDateTime data);

// ❌ ERRADO - SQL Injection vulnerável
String sql = "SELECT * FROM Utilizadores WHERE email = '" + email + "'";
```

---

### Chamar Stored Procedures

```java
@Repository
public interface MarketRepository extends JpaRepository<Transacao, Integer> {
    
    // Chamar sp_ExecutarCompraDireta
    @Procedure(procedureName = "sp_ExecutarCompraDireta")
    void executarCompraDireta(
        @Param("p_oferta_id") Integer ofertaId,
        @Param("p_comprador_id") Integer compradorId,
        @Param("p_quantidade") BigDecimal quantidade
    );
    
    // Chamar sp_MatchingEngine
    @Procedure(procedureName = "sp_MatchingEngine")
    void executarMatchingEngine();
}
```

---

## 🐳 Configuração Docker

### Estrutura de Ficheiros

```
voltexchange/
├── docker-compose.yml
├── postgres/
│   ├── Dockerfile
│   └── init-scripts/
│       ├── 01-ddl.sql
│       ├── 02-logic.sql
│       └── 03-seed.sql
└── api/
    └── Dockerfile
```

---

### docker-compose.yml

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    build: ./postgres
    container_name: voltexchange-db
    environment:
      POSTGRES_DB: voltexchange
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./postgres/init-scripts:/docker-entrypoint-initdb.d
    networks:
      - voltexchange-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Spring Boot API
  api:
    build: ./api
    container_name: voltexchange-api
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/voltexchange
      SPRING_DATASOURCE_USERNAME: postgres
      SPRING_DATASOURCE_PASSWORD: postgres
    ports:
      - "8080:8080"
    networks:
      - voltexchange-network
    restart: unless-stopped

volumes:
  postgres-data:

networks:
  voltexchange-network:
    driver: bridge
```

---

### postgres/Dockerfile

```dockerfile
FROM postgres:16-alpine

# Copiar scripts de inicialização
COPY init-scripts/ /docker-entrypoint-initdb.d/

# Instalar extensões necessárias
RUN apk add --no-cache postgresql-contrib
```

---

### api/Dockerfile

```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app
COPY pom.xml .
COPY src ./src

RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine

WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

### Comandos Docker

```bash
# Iniciar ambiente completo
docker-compose up -d

# Ver logs
docker-compose logs -f api

# Parar ambiente
docker-compose down

# Limpar tudo (incluindo volumes)
docker-compose down -v

# Reconstruir após alterações
docker-compose up -d --build

# Aceder ao PostgreSQL
docker exec -it voltexchange-db psql -U postgres -d voltexchange
```

---

## 🔒 Segurança

### 1. Prepared Statements (Anti SQL Injection)

**Obrigatório**: Todas as queries devem usar parâmetros.

```java
// Spring Data JPA - automático com @Query
@Query("SELECT u FROM Utilizador u WHERE u.email = :email")
Optional<Utilizador> findByEmail(@Param("email") String email);

// JDBC Template
jdbcTemplate.query(
    "SELECT * FROM Leituras WHERE ContadorID = ? AND DataHora > ?",
    new Object[]{contadorId, dataHora},
    new LeituraRowMapper()
);
```

---

### 2. Hashing de Passwords

**Obrigatório**: Usar BCrypt ou Argon2.

```java
@Service
public class AuthService {
    
    private final PasswordEncoder passwordEncoder;
    
    public AuthService(PasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }
    
    public void register(RegisterRequest request) {
        // Hash da password antes de guardar
        String hashedPassword = passwordEncoder.encode(request.getPassword());
        
        Utilizador utilizador = new Utilizador();
        utilizador.setNome(request.getNome());
        utilizador.setEmail(request.getEmail());
        utilizador.setPasswordHash(hashedPassword);
        
        utilizadorRepository.save(utilizador);
    }
    
    public String login(LoginRequest request) {
        Utilizador user = utilizadorRepository.findByEmail(request.getEmail())
            .orElseThrow(() -> new RuntimeException("Utilizador não encontrado"));
        
        // Verificar password
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Password incorreta");
        }
        
        return jwtTokenProvider.generateToken(user.getEmail());
    }
}
```

**Configuração BCrypt:**

```java
@Configuration
public class SecurityConfig {
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12); // Força 12
    }
}
```

---

### 3. JWT Authentication

```java
@Component
public class JwtTokenProvider {
    
    @Value("${jwt.secret}")
    private String jwtSecret;
    
    @Value("${jwt.expiration}")
    private long jwtExpiration;
    
    public String generateToken(String email) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpiration);
        
        return Jwts.builder()
            .setSubject(email)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .signWith(SignatureAlgorithm.HS512, jwtSecret)
            .compact();
    }
    
    public String getEmailFromToken(String token) {
        Claims claims = Jwts.parser()
            .setSigningKey(jwtSecret)
            .parseClaimsJws(token)
            .getBody();
        
        return claims.getSubject();
    }
    
    public boolean validateToken(String token) {
        try {
            Jwts.parser().setSigningKey(jwtSecret).parseClaimsJws(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
```

---

## ⚡ Performance e Otimização

### 1. Particionamento da Tabela Leituras

**Estratégia**: Partition by RANGE em `DataHora` (mensal).

**Vantagens**:
- Queries mais rápidas (só lê partições relevantes)
- Gestão de dados históricos facilitada
- Melhor performance em VACUUM/ANALYZE

**Script de Criação de Partições Automático**:

```sql
-- Função para criar partições automaticamente
CREATE OR REPLACE FUNCTION criar_particoes_leituras(
    data_inicio DATE,
    data_fim DATE
)
RETURNS VOID AS $$
DECLARE
    mes DATE;
    nome_particao TEXT;
    data_inicio_mes DATE;
    data_fim_mes DATE;
BEGIN
    mes := DATE_TRUNC('month', data_inicio);
    
    WHILE mes < data_fim LOOP
        nome_particao := 'Leituras_' || TO_CHAR(mes, 'YYYY_MM');
        data_inicio_mes := mes;
        data_fim_mes := mes + INTERVAL '1 month';
        
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I PARTITION OF Leituras
             FOR VALUES FROM (%L) TO (%L)',
            nome_particao, data_inicio_mes, data_fim_mes
        );
        
        RAISE NOTICE 'Partição criada: %', nome_particao;
        mes := mes + INTERVAL '1 month';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Criar partições para 2025-2026
SELECT criar_particoes_leituras('2025-01-01', '2027-01-01');
```

---

### 2. Índices Críticos

```sql
-- Índices para Leituras (JSONB)
CREATE INDEX idx_leituras_dados_audit ON Leituras USING GIN (DadosAudit);
CREATE INDEX idx_leituras_temperatura 
    ON Leituras ((DadosAudit->>'temperatura')::NUMERIC)
    WHERE (DadosAudit->>'temperatura')::NUMERIC > 80;

-- Índices para Matching Engine
CREATE INDEX idx_ofertas_matching 
    ON OfertasVenda(Estado, PrecoUnitario, DataCriacao)
    WHERE Estado = 'ATIVA';

CREATE INDEX idx_ordens_matching 
    ON OrdensCompra(Estado, PrecoMaximo DESC, DataCriacao)
    WHERE Estado = 'PENDENTE';

-- Índices de proximidade
CREATE INDEX idx_ofertas_regiao ON OfertasVenda(Regiao) WHERE Estado = 'ATIVA';
CREATE INDEX idx_ordens_regiao ON OrdensCompra(Regiao) WHERE Estado = 'PENDENTE';
```

---

### 3. Análise de Performance

```sql
-- Ver tamanho das tabelas
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Analisar query plan (EXPLAIN ANALYZE)
EXPLAIN ANALYZE
SELECT * FROM Leituras
WHERE (DadosAudit->>'temperatura')::NUMERIC > 80
  AND DataHora > '2025-01-01';

-- Ver índices utilizados
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_indexes
JOIN pg_class ON pg_class.relname = indexname
WHERE schemaname = 'public';
```

---

## 📅 Checkpoints e Entregas

### Checkpoint 1 - 8 de Abril (Estrutura e Dados)

**Obrigatório**:
- ✅ Acesso ao servidor PostgreSQL da escola validado
- ✅ Todas as tabelas do Anexo A criadas
- ✅ **Seeding**:
  - Tabela `Leituras`: **mínimo 500.000 registos**
  - Tabela `OfertasVenda`: **mínimo 1.000 registos**

**Script de Seeding**:

```sql
-- Seed Utilizadores (1000 registos)
INSERT INTO Utilizadores (Nome, Email, PasswordHash, Saldo)
SELECT 
    'User ' || i,
    'user' || i || '@voltexchange.com',
    '$2a$12$hashedpassword', -- BCrypt hash
    ROUND((RANDOM() * 10000)::NUMERIC, 2)
FROM generate_series(1, 1000) AS i;

-- Seed Contadores (1000 registos)
INSERT INTO Contadores (UtilizadorID, NumeroSerie, Estado, Regiao)
SELECT 
    i,
    'SN-' || LPAD(i::TEXT, 10, '0'),
    CASE WHEN RANDOM() < 0.95 THEN 'ATIVO' ELSE 'MANUTENCAO' END,
    (ARRAY['Norte', 'Centro', 'Sul', 'Lisboa', 'Porto'])[1 + FLOOR(RANDOM() * 5)]
FROM generate_series(1, 1000) AS i;

-- Seed Leituras (500.000 registos)
INSERT INTO Leituras (ContadorID, DataHora, KWh_Leitura, DadosAudit)
SELECT 
    1 + (i % 1000),
    TIMESTAMP '2025-01-01' + (i * INTERVAL '1 minute'),
    ROUND((RANDOM() * 100)::NUMERIC, 3),
    jsonb_build_object(
        'temperatura', ROUND((20 + RANDOM() * 70)::NUMERIC, 2),
        'voltagem', ROUND((220 + RANDOM() * 20)::NUMERIC, 2),
        'erro_codigo', CASE WHEN RANDOM() < 0.02 THEN 'ERR_' || FLOOR(RANDOM() * 100) ELSE NULL END
    )
FROM generate_series(1, 500000) AS i;

-- Seed OfertasVenda (1000 registos)
INSERT INTO OfertasVenda (VendedorID, QuantidadeKWh, PrecoUnitario, Estado, DataCriacao, Regiao)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    ROUND((RANDOM() * 100)::NUMERIC, 3),
    ROUND((0.10 + RANDOM() * 0.20)::NUMERIC, 4),
    (ARRAY['ATIVA', 'VENDIDA', 'CANCELADA'])[1 + FLOOR(RANDOM() * 3)],
    TIMESTAMP '2025-01-01' + (RANDOM() * INTERVAL '90 days'),
    (ARRAY['Norte', 'Centro', 'Sul', 'Lisboa', 'Porto'])[1 + FLOOR(RANDOM() * 5)]
FROM generate_series(1, 1000) AS i;
```

---

### Checkpoint 2 - 13 de Maio (Lógica e API)

**Obrigatório**:
- ✅ Stored Procedures funcionais:
  - `sp_MatchingEngine`
  - `sp_ExecutarCompraDireta`
- ✅ Triggers implementados:
  - Detecção de anomalias
  - Proteção de utilizadores
- ✅ API alojada (Vercel/Render/Railway)
- ✅ API comunicando com BD da escola
- ✅ **Demonstração de segurança**:
  - Tentativa de SQL Injection falhada
  - Passwords encriptadas

**Teste de SQL Injection**:

```bash
# Tentativa de ataque (deve falhar)
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@test.com OR 1=1--",
    "password": "anything"
  }'

# Resposta esperada: Erro de autenticação (não SQL Injection)
```

---

### Entrega Final

**Ficheiro ZIP contendo**:

1. **Código Fonte**:
   - `api/` (Spring Boot - sem node_modules ou target/)
   - `docker-compose.yml`
   - `README.md`

2. **Scripts SQL**:
   - `ddl.sql` (CREATE TABLE, índices, partições)
   - `logic.sql` (Stored Procedures, Triggers, Functions)
   - `seed.sql` (INSERT de dados de teste)

3. **Relatório Técnico (PDF)**:
   - Diagrama ER (Entidade-Relacionamento)
   - Justificação de Índices
   - Justificação de Particionamento
   - Planos de Execução (EXPLAIN ANALYZE)
   - URL da API em produção
   - Credenciais de teste

---

## 📝 Plano de Implementação

### Fase 1: Setup Inicial (Semana 1)

**Objetivo**: Ambiente de desenvolvimento funcional.

```bash
# 1. Criar estrutura de pastas
mkdir -p voltexchange/{postgres/init-scripts,api}
cd voltexchange

# 2. Criar docker-compose.yml
# (copiar configuração acima)

# 3. Criar projeto Spring Boot
cd api
mvn archetype:generate \
  -DgroupId=com.voltexchange \
  -DartifactId=voltexchange-api \
  -DarchetypeArtifactId=maven-archetype-quickstart

# 4. Iniciar PostgreSQL
docker-compose up -d postgres

# 5. Testar conexão
psql -h localhost -U postgres -d voltexchange
```

---

### Fase 2: Modelo de Dados (Semana 1-2)

**Objetivo**: Criar todas as tabelas, índices e partições.

**Checklist**:
- [ ] Criar script `ddl.sql` com todas as tabelas
- [ ] Implementar particionamento em `Leituras`
- [ ] Criar todos os índices (incluindo GIN para JSONB)
- [ ] Validar foreign keys e constraints
- [ ] Testar criação com Docker

**Comando**:
```bash
docker exec -i voltexchange-db psql -U postgres -d voltexchange < postgres/init-scripts/01-ddl.sql
```

---

### Fase 3: Lógica de Servidor (Semana 2-3)

**Objetivo**: Implementar Stored Procedures e Triggers.

**Checklist**:
- [ ] `sp_MatchingEngine` (completa)
- [ ] `sp_ExecutarCompraDireta` (ACID)
- [ ] Trigger detecção de anomalias
- [ ] Trigger proteção de utilizadores
- [ ] (Opcional) Trigger auto-matching
- [ ] Testar cada procedure individualmente

**Teste Manual**:
```sql
-- Testar sp_ExecutarCompraDireta
CALL sp_ExecutarCompraDireta(1, 10, 5.0);

-- Verificar resultado
SELECT * FROM Transacoes ORDER BY TransacaoID DESC LIMIT 1;
```

---

### Fase 4: Seeding de Dados (Semana 3)

**Objetivo**: Popular BD com dados de teste (Checkpoint 1).

**Checklist**:
- [ ] 1.000 utilizadores
- [ ] 1.000 contadores
- [ ] **500.000 leituras**
- [ ] **1.000 ofertas de venda**
- [ ] 100 ordens de compra
- [ ] Validar distribuição de dados

**Validação**:
```sql
-- Verificar contagens
SELECT 
    'Utilizadores' AS tabela, COUNT(*) AS registos FROM Utilizadores
UNION ALL
SELECT 'Contadores', COUNT(*) FROM Contadores
UNION ALL
SELECT 'Leituras', COUNT(*) FROM Leituras
UNION ALL
SELECT 'OfertasVenda', COUNT(*) FROM OfertasVenda;

-- Verificar anomalias
SELECT COUNT(*) FROM Leituras
WHERE (DadosAudit->>'temperatura')::NUMERIC > 80
   OR DadosAudit ? 'erro_codigo';
```

---

### Fase 5: API Spring Boot (Semana 3-4)

**Objetivo**: Desenvolver backend REST completo.

**Ordem de Implementação**:

1. **Configuração Base**:
   - [ ] SecurityConfig (BCrypt, JWT)
   - [ ] DatabaseConfig (DataSource, JPA)
   - [ ] CorsConfig

2. **Autenticação**:
   - [ ] Entity: Utilizador
   - [ ] Repository: UtilizadorRepository
   - [ ] Service: AuthService
   - [ ] Controller: AuthController
   - [ ] Testar: `POST /api/auth/register` e `/login`

3. **Leituras de Contadores**:
   - [ ] Entity: Leitura, Contador
   - [ ] Repository: LeituraRepository
   - [ ] Service: MeterService
   - [ ] Controller: MeterController
   - [ ] Testar: `POST /api/meters/readings`

4. **Mercado de Energia**:
   - [ ] Entities: OfertaVenda, OrdemCompra, Transacao
   - [ ] Repository: MarketRepository
   - [ ] Service: MarketService
   - [ ] Controller: MarketController
   - [ ] Testar: `POST /api/market/buy`, `/order`, `/match`

5. **Administração**:
   - [ ] Service: AdminService
   - [ ] Controller: AdminController
   - [ ] Testar: `GET /api/admin/anomalies`

**Teste de Endpoints**:
```bash
# Registo
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "João Silva",
    "email": "joao@test.com",
    "password": "senha123"
  }'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@test.com",
    "password": "senha123"
  }'
```

---

### Fase 6: Segurança (Semana 4)

**Objetivo**: Validar segurança (Checkpoint 2).

**Checklist**:
- [ ] Todas as queries usam Prepared Statements
- [ ] Passwords com BCrypt (força 12+)
- [ ] JWT implementado corretamente
- [ ] Testar SQL Injection (deve falhar)
- [ ] Testar autenticação sem token (deve falhar)
- [ ] CORS configurado corretamente

---

### Fase 7: Deploy em Cloud (Semana 5)

**Objetivo**: API acessível publicamente.

**Opções de Deploy**:

#### Opção 1: Railway.app
```bash
# 1. Criar conta em railway.app
# 2. Instalar CLI
npm install -g @railway/cli

# 3. Login
railway login

# 4. Deploy
railway up
```

#### Opção 2: Render.com
```bash
# 1. Conectar repositório GitHub
# 2. Criar Web Service
# 3. Configurar variáveis de ambiente
# 4. Deploy automático
```

**Variáveis de Ambiente (Produção)**:
```properties
SPRING_DATASOURCE_URL=jdbc:postgresql://servidor-escola:5432/voltexchange
SPRING_DATASOURCE_USERNAME=grupoX
SPRING_DATASOURCE_PASSWORD=***
JWT_SECRET=***
```

---

### Fase 8: Testes e Otimização (Semana 5-6)

**Objetivo**: Validar performance e corrigir bugs.

**Checklist Performance**:
- [ ] EXPLAIN ANALYZE em queries críticas
- [ ] Índices sendo utilizados
- [ ] Particionamento funcionando
- [ ] Matching engine < 2 segundos
- [ ] Compra direta < 500ms

**Queries de Teste**:
```sql
-- Teste de performance: Anomalias
EXPLAIN ANALYZE
SELECT * FROM Leituras
WHERE (DadosAudit->>'temperatura')::NUMERIC > 80
LIMIT 100;

-- Teste de performance: Matching
EXPLAIN ANALYZE
SELECT * FROM OfertasVenda
WHERE Estado = 'ATIVA'
  AND PrecoUnitario <= 0.15
ORDER BY PrecoUnitario ASC, DataCriacao ASC
LIMIT 10;
```

---

### Fase 9: Documentação (Semana 6)

**Objetivo**: Relatório técnico completo.

**Estrutura do Relatório**:

1. **Introdução**
   - Descrição do sistema
   - Tecnologias utilizadas

2. **Modelo de Dados**
   - Diagrama ER
   - Dicionário de dados
   - Justificação de escolhas

3. **Lógica de Negócio**
   - Descrição dos Stored Procedures
   - Descrição dos Triggers
   - Fluxograma do Matching Engine

4. **Performance**
   - Estratégia de particionamento
   - Justificação de índices
   - Planos de execução (EXPLAIN ANALYZE)
   - Testes de carga

5. **Segurança**
   - Prepared Statements
   - Encriptação de passwords
   - Testes de SQL Injection

6. **API**
   - Arquitetura
   - Endpoints documentados
   - Exemplos de requests/responses

7. **Deploy**
   - URL em produção
   - Credenciais de teste
   - Instruções de uso

---

## 🎯 Dicas para Nota Máxima

### 1. Implementar Trigger de Auto-Matching (Excelência)
Sistema reativo que dispara matching automaticamente.

### 2. Documentação Exemplar
- Diagrama ER profissional (Draw.io, Lucidchart)
- Comentários em código SQL
- README detalhado

### 3. Testes Automatizados
```java
@SpringBootTest
class MarketServiceTest {
    
    @Test
    void testCompraDireta() {
        // Implementar testes unitários
    }
}
```

### 4. Monitoring e Logs
```java
@Slf4j
@Service
public class MarketService {
    
    public void executarCompraDireta(BuyRequest request) {
        log.info("Iniciando compra direta: ofertaId={}", request.getOfertaId());
        // ...
    }
}
```

### 5. Otimização Avançada
- Connection pooling (HikariCP)
- Cache (Redis para ofertas ativas)
- Rate limiting na API

---

## 📚 Recursos Úteis

### Documentação Oficial
- [PostgreSQL 16 Docs](https://www.postgresql.org/docs/16/)
- [Spring Boot 3 Docs](https://spring.io/projects/spring-boot)
- [Spring Security](https://spring.io/projects/spring-security)
- [JWT.io](https://jwt.io/)

### Ferramentas
- **pgAdmin**: Interface gráfica para PostgreSQL
- **Postman**: Testar API REST
- **DBeaver**: Cliente SQL multiplataforma
- **Docker Desktop**: Gestão de containers

### Tutoriais
- [Spring Boot + PostgreSQL](https://www.baeldung.com/spring-boot-postgresql-docker)
- [JWT Authentication](https://www.bezkoder.com/spring-boot-jwt-authentication/)
- [PostgreSQL Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html)

---

## ✅ Checklist Final

### Antes da Entrega
- [ ] Todos os checkpoints cumpridos
- [ ] API deployada e funcional
- [ ] BD no servidor da escola operacional
- [ ] Código bem comentado
- [ ] Scripts SQL organizados
- [ ] Relatório PDF completo
- [ ] Diagrama ER incluído
- [ ] Testes de segurança documentados
- [ ] URLs e credenciais fornecidos

### Defesa do Projeto
- [ ] Explicar arquitetura do sistema
- [ ] Demonstrar matching engine
- [ ] Explicar escolha de índices
- [ ] Mostrar planos de execução
- [ ] Defender decisões técnicas
- [ ] Demonstrar conhecimento de código

---

## 📞 Suporte

Para dúvidas sobre o projeto:
- **Docente**: Gonçalo Marques
- **Plataforma**: E-learning da escola
- **Horário de Dúvidas**: (consultar calendário)

---

**Boa sorte com o projeto VoltExchange! 🚀⚡**
