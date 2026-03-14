# ⚡ VoltExchange - Plataforma de Mercado P2P de Energia

> **Disciplina**: Base de Dados II  
> **Ano Letivo**: 2025/2026  
> **Progresso**: 22% | **Status**: 🟡 Fase 1 em andamento

---

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Arquitetura](#arquitetura)
- [Status do Projeto](#status-do-projeto)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Como Executar](#como-executar)
- [Documentação](#documentação)
- [Checkpoints](#checkpoints)

---

## 🎯 Visão Geral

**VoltExchange** é uma plataforma de mercado peer-to-peer (P2P) que permite:
- **Prosumers** (produtores domésticos com painéis solares) venderem excedentes de energia
- **Consumidores** comprarem energia diretamente de vizinhos
- **Matching automático** entre ordens de compra e ofertas de venda

### Tecnologias

- **Base de Dados**: PostgreSQL 16+
- **Backend API**: Spring Boot 3 (Java + Gradle)
- **Segurança**: JWT + BCrypt
- **Deploy**: Railway/Render + Servidor da Escola

---

## 🏗️ Arquitetura

```
┌──────────────┐
│   Cliente    │
└──────┬───────┘
       │ REST API
       ▼
┌──────────────────┐
│  Spring Boot API │
│  - Auth (JWT)    │
│  - Market        │
│  - Meters        │
│  - Admin         │
└────────┬─────────┘
         │ JDBC
         ▼
┌─────────────────────────┐
│  PostgreSQL (Escola)    │
│  - 6 Tabelas            │
│  - Leituras PARTIONADA  │
│  - Stored Procedures    │
│  - Triggers             │
└─────────────────────────┘
```

---

## 📊 Status do Projeto

### ✅ Concluído (22%)

- [x] Projeto Spring Boot criado e estruturado
- [x] 6 tabelas criadas (`01-schema.sql`)
- [x] **24 partições criadas (`02-partitions.sql`)** ✅
- [x] Constraints, Foreign Keys e CHECKs
- [x] application.properties configurado

### 🚧 Em Progresso

- [ ] Índices (GIN, B-tree, parciais) ⬅️ **PRÓXIMO**
- [ ] Stored Procedures (sp_ExecutarCompraDireta, sp_MatchingEngine)
- [ ] Triggers (DetectarAnomalias, ProtegerUtilizadores)

### ⏳ Pendente

- [ ] Entities completas
- [ ] Repositories e Services
- [ ] Controllers e DTOs
- [ ] Segurança (JWT + BCrypt)
- [ ] Seed massivo (500k leituras)
- [ ] Deploy em cloud

**Ver progresso detalhado**: [context/PROGRESSO.md](context/PROGRESSO.md)

---

## 📁 Estrutura do Repositório

```
voltexchange/
├── api/                           # Spring Boot API
│   ├── src/main/
│   │   ├── java/com/voltexchange/api/
│   │   │   ├── config/           # Segurança, CORS, Exception Handler
│   │   │   ├── controller/       # REST Controllers
│   │   │   ├── dto/              # Data Transfer Objects
│   │   │   ├── entity/           # JPA Entities
│   │   │   ├── repository/       # JPA Repositories
│   │   │   ├── security/         # JWT, Filters
│   │   │   └── service/          # Business Logic
│   │   └── resources/
│   │       ├── application.properties
│   │       └── application-prod.properties
│   ├── build.gradle
│   └── gradlew
│
├── migrations/                    # Scripts SQL
│   ├── 01-schema.sql             ✅ Tabelas criadas
│   ├── 02-partitions.sql         ✅ Partições criadas
│   ├── 03-indexes.sql            🚧 A criar
│   ├── 04-procedures.sql         🚧 A criar
│   ├── 05-triggers.sql           🚧 A criar
│   ├── 06-seed-mini.sql          ⏳ Pendente
│   └── 07-seed-massivo.sql       ⏳ Pendente
│
├── context/                       # Documentação do projeto
│   ├── PROGRESSO.md              # Checklist detalhado
│   ├── plano-4-semanas.md        # Plano atualizado
│   ├── requesitos.md             # Requisitos completos
│   └── voltexchange-analise.md   # Análise técnica
│
├── docker-compose.yml             ⏳ A criar
└── README.md                      ✅ Este ficheiro
```

---

## 🚀 Como Executar

### Pré-requisitos

- Java 17+
- PostgreSQL 16+
- Gradle 8+

### 1. Configurar Base de Dados

```bash
# Executar scripts na ordem:
psql -U postgres -d voltexchange -f migrations/01-schema.sql
psql -U postgres -d voltexchange -f migrations/02-partitions.sql
psql -U postgres -d voltexchange -f migrations/03-indexes.sql
# ... (quando criados)
```

### 2. Configurar API

```bash
cd api

# Editar application.properties com suas credenciais
nano src/main/resources/application.properties

# Executar
./gradlew bootRun
```

### 3. Testar

```bash
# Registar utilizador
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"nome":"João Silva","email":"joao@example.com","password":"senha123"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"joao@example.com","password":"senha123"}'
```

---

## 📚 Documentação

### Scripts SQL

| Ficheiro | Descrição | Status |
|----------|-----------|--------|
| `01-schema.sql` | Criação das 6 tabelas | ✅ |
| `02-partitions.sql` | Partições mensais Leituras (2025-2026) | ✅ |
| `03-indexes.sql` | Índices GIN, B-tree, parciais | 👉 **PRÓXIMO** |
| `04-procedures.sql` | sp_ExecutarCompraDireta + sp_MatchingEngine | 🚧 |
| `05-triggers.sql` | Detecção anomalias + Proteção utilizadores | 🚧 |
| `06-seed-mini.sql` | ~100 registos para testes | ⏳ |
| `07-seed-massivo.sql` | 500k+ leituras, 1k+ ofertas | ⏳ |

### Endpoints da API (Planeados)

#### Autenticação
- `POST /api/auth/register` - Registar utilizador
- `POST /api/auth/login` - Login (retorna JWT)

#### Leituras de Contadores
- `POST /api/meters/readings` - Inserir leitura
- `GET /api/meters/{id}/readings` - Listar leituras

#### Mercado
- `GET /api/market/offers` - Listar ofertas ativas
- `POST /api/market/offers` - Criar oferta de venda
- `POST /api/market/buy` - Comprar oferta (chama procedure)
- `POST /api/market/order` - Criar ordem de compra
- `POST /api/market/match` - Executar matching engine

#### Administração
- `GET /api/admin/anomalies` - Listar anomalias (JSONB query)
- `GET /api/admin/meters/maintenance` - Contadores em manutenção

---

## 🎯 Checkpoints

### Checkpoint 1 (8 Abril 2026)
**Objetivo**: Base de dados funcional + API com autenticação

- [ ] DDL executado no servidor da escola
- [ ] Todas as procedures funcionais
- [ ] 500.000+ leituras carregadas
- [ ] 1.000+ ofertas carregadas
- [ ] API com autenticação (JWT) funcional
- [ ] Endpoint de leituras funcional

### Checkpoint 2 (13 Maio 2026)
**Objetivo**: Sistema completo deployed

- [ ] API deployed em cloud (Railway/Render)
- [ ] Todos os endpoints funcionais
- [ ] Testes de segurança realizados (SQL Injection, etc.)
- [ ] Relatório técnico completo (PDF)
- [ ] Postman collection entregue
- [ ] Defesa preparada

---

## 👥 Equipa

- **Pessoa 1**: API Spring Boot (Backend + Segurança)
- **Pessoa 2**: Base de Dados PostgreSQL (Schema + Lógica)

**Nota**: Ambas as pessoas devem conseguir explicar TODO o projeto!

---

## 📖 Recursos Úteis

- [Plano Detalhado (4 Semanas)](context/plano-4-semanas.md)
- [Progresso Detalhado](context/PROGRESSO.md)
- [Requisitos Completos](context/requesitos.md)
- [Análise Técnica](context/voltexchange-analise.md)

---

## 🎓 Critérios de Excelência

Para nota máxima, implementar:
- ✅ Trigger de Auto-Matching
- ✅ EXPLAIN ANALYZE documentado
- ✅ Diagrama ER profissional
- ✅ Testes de SQL Injection documentados
- ✅ Código comentado e organizado

---

**Última atualização**: 14 Março 2026  
**Próximas prioridades**: ✅ Partições → 🔴 Índices → Procedures
