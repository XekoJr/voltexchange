# 📊 Progresso do Projeto VoltExchange

> **Última atualização**: 4 Abril 2026
> **Status Geral**: 🟢 Core completo — A preparar CP1 (8 Abril) e documentação final

---

## 📈 Visão Geral do Progresso

| Categoria | Progresso | Status |
|-----------|-----------|--------|
| 🗄️ Base de Dados | 100% | 🟢 Completa |
| 🌐 API Express.js (Node) | 100% | 🟢 Completa |
| 🐳 Infraestrutura Docker | 100% | 🟢 Completa |
| 🔐 Segurança | 90% | 🟢 Implementada (faltam testes documentados) |
| 🚀 Deploy Cloud | 0% | 🔴 Não Iniciado |
| 📝 Documentação / Relatório | 10% | 🔴 Por fazer |

**Total Geral**: ⚡ **75%** completo

> ⚠️ **CP1 em 4 dias (8 Abril)** — foco em: servidor da escola + testes + Postman

---

## 🗄️ BASE DE DADOS — 100% ✅

### 01-schema.sql — Tabelas ✅
- [x] `Utilizadores` — id, nome, email UNIQUE, password_hash, saldo, constraints CHECK
- [x] `Contadores` — id, utilizador_id FK, numero_serie UNIQUE, estado, regiao
- [x] `Leituras` — BIGSERIAL, PARTITION BY RANGE (data_hora), dados_audit JSONB
- [x] `OfertasVenda` — id, vendedor_id FK, quantidade_kwh, preco_unitario, estado, regiao, data_expiracao
- [x] `OrdensCompra` — id, comprador_id FK, quantidade_kwh, preco_maximo, estado, regiao
- [x] `Transacoes` — id, oferta_id FK, ordem_id FK, comprador_id FK, vendedor_id FK, tipo_transacao
- [x] Todas as Foreign Keys com ON DELETE RESTRICT / ON UPDATE CASCADE
- [x] Todos os CHECK constraints (saldo >= 0, kwh > 0, comprador != vendedor, estados válidos)
- [x] DROP TABLE IF EXISTS CASCADE no topo (idempotente)

### 02-partitions.sql — Partições ✅
- [x] 12 partições mensais 2025 (Leituras_2025_01 … Leituras_2025_12)
- [x] 12 partições mensais 2026 (Leituras_2026_01 … Leituras_2026_12)
- [x] Bug de overflow corrigido (intervalo 126s garante max data_hora ≤ 2026-12-31)

### 03-indexes.sql — Índices ✅ (22 índices)
- [x] `idx_utilizadores_saldo` — parcial (WHERE saldo > 0)
- [x] `idx_utilizadores_data_criacao`
- [x] `idx_contadores_utilizador_id` — FK lookup
- [x] `idx_contadores_estado`, `idx_contadores_regiao`
- [x] `idx_leituras_dados_audit_gin` — **GIN** para queries JSONB (temperatura, erro_codigo)
- [x] `idx_leituras_contador_data` — composto (contador_id, data_hora DESC) para period queries
- [x] `idx_leituras_data_hora` — range scans e partition pruning
- [x] `idx_leituras_temperatura` — extração numérica de temperatura do JSONB
- [x] `idx_ofertas_estado_preco` — composto para matching engine (filtro ATIVA + preço)
- [x] `idx_ofertas_regiao_ativa` — parcial (WHERE estado='ATIVA')
- [x] `idx_ofertas_vendedor_id`, `idx_ofertas_data_criacao`
- [x] `idx_ordens_estado_preco` — composto para matching engine (filtro PENDENTE + preço)
- [x] `idx_ordens_regiao_pendente` — parcial (WHERE estado='PENDENTE')
- [x] `idx_ordens_comprador_id`, `idx_ordens_data_criacao`
- [x] `idx_transacoes_comprador_data`, `idx_transacoes_vendedor_data`
- [x] `idx_transacoes_oferta_id`, `idx_transacoes_ordem_id`
- [x] `idx_transacoes_data`, `idx_transacoes_tipo`

### 04-procedures.sql — Stored Procedures ✅
- [x] **sp_ExecutarCompraDireta** (p_oferta_id, p_comprador_id, p_quantidade)
  - SELECT FOR UPDATE na oferta (bloqueio pessimista — ACID)
  - Validações: oferta ATIVA, quantidade disponível, saldo suficiente
  - Débito comprador, crédito vendedor, INSERT em Transacoes (tipo='DIRETA')
  - RAISE EXCEPTION com mensagens descritivas
- [x] **sp_MatchingEngine** ()
  - Loop por OrdensCompra PENDENTES ORDER BY data_criacao (FIFO)
  - Matching por: estado='ATIVA', preco <= preco_maximo, regiao compatível (NULL aceita tudo)
  - SELECT FOR UPDATE na oferta escolhida
  - Lógica de quantidade parcial (LEAST)
  - UPDATE saldos, estados, quantidades + INSERT em Transacoes (tipo='MATCHED')
  - RAISE NOTICE com logs de cada match

### 05-triggers.sql — Triggers ✅ (4 triggers)
- [x] **fn_DetectarAnomalias** / **trg_DetectarAnomalias** — AFTER INSERT ON Leituras
  - Extrai temperatura do JSONB; se > 80°C → MANUTENCAO
  - Verifica presença de erro_codigo não nulo → MANUTENCAO
  - RAISE NOTICE com detalhes da leitura anómala
  - Propaga a todas as partições (PostgreSQL 13+)
- [x] **fn_ProtegerUtilizadores** / **trg_ProtegerUtilizadores** — BEFORE DELETE ON Utilizadores
  - Bloqueia delete se saldo > 0
  - Bloqueia delete se transações nos últimos 30 dias
  - RAISE EXCEPTION com mensagem descritiva
- [x] **fn_AutoMatching** / **trg_AutoMatching_Ordem** — AFTER INSERT ON OrdensCompra
- [x] **trg_AutoMatching_Oferta** — AFTER INSERT ON OfertasVenda

### 06-seed-mini.sql — Dados de Teste ✅
- [x] 10 utilizadores (saldos de 0 a 1000€, password: `senha123` bcryptjs)
- [x] 10 contadores (3 regiões: Norte, Centro, Sul)
- [x] 40 leituras normais + 10 anómalas (5 temperatura > 80°C + 5 erro_codigo)
- [x] 20 ofertas de venda (preços 0.10-0.18 €/kWh)
- [x] 10 ordens de compra (pares compatíveis + 1 Fernando saldo=0 para testar falha)
- [x] Triggers desactivados durante seed, reactivados no final

### 07-seed-massivo.sql — Big Data ✅
- [x] **500.000 leituras** via generate_series (10 contadores × 50k, 2025-01 a 2026-12)
- [x] Distribuição JSONB: 80% normais, 15% temperatura>80, 5% erro_codigo
- [x] **1.000 ofertas de venda** (vendedores 7,8,9,10; estados 70/20/10%)
- [x] **500 ordens de compra** (compradores 1-5; estados 60/30/10%)
- [x] UPDATE manual de anomalias (trigger desactivado durante carga)
- [x] DO block de verificação final com RAISE NOTICE dos totais

### 08-views.sql — Vistas ✅ (5 vistas)
- [x] **vw_anomalias_detalhadas** — leituras anómalas com contexto de contador/utilizador + tipo_anomalia
- [x] **vw_mercado_ativo** — ofertas ATIVA com nome/email do vendedor
- [x] **vw_transacoes_detalhadas** — histórico completo com nomes de comprador e vendedor
- [x] **vw_consumo_mensal** — kWh agregado por contador e mês (explora partições)
- [x] **vw_resumo_utilizadores** — saldo, nº contadores, total gasto/recebido por utilizador

---

## 🌐 API EXPRESS.JS — 100% ✅

> ⚠️ A API foi migrada de **Spring Boot → Express.js (Node.js)** — o PROGRESSO.md anterior estava desatualizado.

### Infraestrutura
- [x] `api/Dockerfile` — Node 20 Alpine, `npm install --omit=dev`
- [x] `api/src/app.js` — Express + CORS + dotenv + rotas + error handlers
- [x] `api/src/config/database.js` — pg Pool (lê DB_HOST/PORT/NAME/USER/PASSWORD do env)
- [x] `api/src/middleware/auth.js` — Bearer JWT validation via jsonwebtoken

### Endpoints
| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| GET | `/api/health` | — | Health check |
| POST | `/api/auth/register` | — | Registo (bcryptjs strength 12) + JWT |
| POST | `/api/auth/login` | — | Login + JWT |
| GET | `/api/meters` | JWT | Listar contadores do utilizador |
| POST | `/api/meters/:id/readings` | JWT | Submeter leitura (valida ownership) |
| GET | `/api/meters/:id/readings?inicio=&fim=` | JWT | Leituras por período (explora partições) |
| GET | `/api/market/offers?regiao=` | JWT | Listar ofertas ATIVA (filtro opcional) |
| POST | `/api/market/offers` | JWT | Criar oferta de venda |
| POST | `/api/market/offers/:id/buy` | JWT | Compra direta (chama sp_ExecutarCompraDireta) |
| POST | `/api/market/order` | JWT | Criar ordem de compra |
| POST | `/api/market/match` | JWT | Disparar sp_MatchingEngine |
| GET | `/api/admin/anomalies` | JWT | Anomalias JSONB + contadores MANUTENCAO |
| GET | `/api/admin/transactions` | JWT | Histórico de transações |

### Segurança implementada
- [x] Passwords com bcryptjs (strength 12) — hash armazenado, nunca plaintext
- [x] JWT Bearer tokens (jsonwebtoken) — validação em todos os endpoints protegidos
- [x] Parameterized queries em todo o código (`$1, $2, …`) — sem SQL injection
- [x] Ownership check: leituras e contadores validados contra utilizador autenticado
- [x] Mensagens de erro não expõem stack traces (error handler global)
- [ ] Testes de segurança documentados (SQL injection, token inválido, token expirado)

---

## 🐳 INFRAESTRUTURA DOCKER — 100% ✅

- [x] `docker-compose.yml` — 100% env-var driven (sem hardcoded credentials)
- [x] `.env` — 1 ficheiro único para tudo (PORT, DB_*, JWT_SECRET)
- [x] Healthcheck corrigido: `pg_isready -U ${DB_USER} -d ${DB_NAME}`
- [x] Build context correto: `./api` (Node.js, não Spring Boot)
- [x] Todos os 8 scripts SQL montados em `/docker-entrypoint-initdb.d/` em ordem
- [x] `docker compose up --build` funciona limpo (verificado em logs)
- [x] DB sobe com 500.050 leituras, 1.020 ofertas, 510 ordens (verificado)

---

## 🔐 SEGURANÇA — 90% ✅

- [x] BCrypt strength 12 (bcryptjs)
- [x] JWT Bearer tokens com expiração 24h
- [x] Parameterized queries (sem SQL injection possível)
- [x] Validação de ownership em contadores
- [x] Variáveis de ambiente para JWT_SECRET e credenciais DB
- [x] `docker-compose.yml` sem credenciais hardcoded
- [x] `.env` no `.gitignore`
- [ ] Testes de segurança executados e documentados
- [ ] CORS restrito (actualmente `*`, deve ser domínio de produção antes de deploy)

---

## 🚀 DEPLOY — 0% ❌

- [ ] Executar migrações no servidor da escola (CP1 — 8 Abril!)
- [ ] Testar API contra servidor da escola
- [ ] Escolher plataforma cloud (Railway / Render recomendado)
- [ ] Configurar variáveis de ambiente em produção
- [ ] Deploy da API realizado
- [ ] Endpoints testados em produção

---

## 📝 DOCUMENTAÇÃO — 10% ⚠️

- [x] `VoltExchange.postman_collection.json` — existe no repositório
- [x] `.github/voltexchange-analise.md` — análise inicial
- [ ] README.md atualizado (actualmente diz Spring Boot e 22% progresso — desatualizado)
- [ ] Postman collection completa com exemplos de request/response e pre-request script para JWT
- [ ] Diagrama ER (Draw.io / Lucidchart)
- [ ] EXPLAIN ANALYZE antes/depois dos índices documentado
- [ ] Relatório técnico PDF (OBRIGATÓRIO CP2)

---

## 🎯 CHECKPOINTS

### Checkpoint 1 — 8 Abril 2026 (em 4 dias!) ⚠️
- [ ] Executar todos os scripts SQL no servidor da escola
- [x] 500.000+ leituras em Docker local (verificado)
- [x] Stored procedures funcionais (verificado)
- [x] Triggers funcionais (verificado)
- [x] API com auth funcional (verificado — "VoltExchange API running on port 3000")
- [ ] API testada com servidor da escola
- [ ] Postman collection com todos os fluxos testados

### Checkpoint 2 — 13 Maio 2026
- [ ] API deployed em cloud
- [ ] Todos os endpoints funcionais em produção
- [ ] Testes de segurança documentados
- [ ] Relatório técnico PDF completo
- [ ] Postman collection exportada e documentada
- [ ] Defesa preparada (ambos os elementos)

---

## 📦 ESTRUTURA ACTUAL DO REPOSITÓRIO

```
voltexchange/
├── .env                          ✅ variáveis de ambiente (gitignored)
├── docker-compose.yml            ✅ 100% env-var driven
├── docker-compose.yml.example    ✅ template para novos devs
├── VoltExchange.postman_collection.json  ✅ existe
├── README.md                     ⚠️ desatualizado (diz Spring Boot)
├── api/
│   ├── Dockerfile                ✅ Node 20 Alpine
│   ├── package.json              ✅ express, pg, bcryptjs, jsonwebtoken, dotenv
│   └── src/
│       ├── app.js                ✅ Express app completa
│       ├── config/database.js    ✅ pg Pool
│       ├── middleware/auth.js    ✅ JWT middleware
│       ├── routes/
│       │   ├── auth.js           ✅ register + login
│       │   ├── meters.js         ✅ contadores + leituras
│       │   ├── market.js         ✅ ofertas + ordens + match
│       │   └── admin.js          ✅ anomalias + transações
│       └── migrations/
│           ├── 01-schema.sql     ✅
│           ├── 02-partitions.sql ✅
│           ├── 03-indexes.sql    ✅ 22 índices
│           ├── 04-procedures.sql ✅ 2 stored procedures
│           ├── 05-triggers.sql   ✅ 4 triggers (incl. auto-matching)
│           ├── 06-seed-mini.sql  ✅ ~100 registos
│           ├── 07-seed-massivo.sql ✅ 500.000+ leituras
│           └── 08-views.sql      ✅ 5 vistas
└── .github/
    ├── PROGRESSO.md              ✅ (este ficheiro)
    ├── plano-4-semanas.md        ✅
    └── voltexchange-analise.md   ✅
```