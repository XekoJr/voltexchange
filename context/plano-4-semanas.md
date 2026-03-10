# 📅 Plano de Desenvolvimento — VoltExchange (4 Semanas)

> **Projeto**: BD II — Sistema de Mercado de Energia P2P  
> **Grupo**: 2 elementos | **E1** = API Spring Boot · **E2** = Base de Dados PostgreSQL  
> **Checkpoints**: CP1 → 8/Abril · CP2 → 13/Maio

---

## 🗺️ Visão Geral das Fases

| Fase | Semana | Foco | Checkpoint |
|------|--------|------|------------|
| 1 | Semana 1 | Setup + DDL + Estrutura Base | — |
| 2 | Semana 2 | Core BD (Procedures/Triggers) + Core API (Auth + Leituras) | **CP1 (8/Abr)** |
| 3 | Semana 3 | Endpoints de Mercado + Integração Procedures | — |
| 4 | Semana 4 | Seeding massivo + Deploy Cloud + Testes + Documentação | **CP2 (13/Mai)** |

---

## 🔵 FASE 1 — Setup & Fundações
### Semana 1 · Trabalho paralelo, sem dependências

### E1 — API Spring Boot

**Objetivo**: Projeto funcional a correr localmente com ligação à BD.

- [x] Criar projeto Spring Boot 3 (Maven) com dependências: `spring-web`, `spring-data-jpa`, `spring-security`, `postgresql`, `jjwt`, `bcrypt`
- [x] Configurar `docker-compose.yml` com PostgreSQL local para desenvolvimento
- [x] Estruturar packages: `config/`, `entity/`, `repository/`, `service/`, `controller/`, `security/`
- [x] Configurar `SecurityConfig`, `DatabaseConfig` e `CorsConfig` (esqueletos)
- [ ] Validar conexão à BD com query simples (`SELECT 1`)

**Entrega para E2**: `docker-compose.yml` + esboço de `api_specs.md`

---

### E2 — Base de Dados PostgreSQL

**Objetivo**: Schema completo criado e validado localmente + acesso ao servidor da escola confirmado.

- [ ] Desenhar diagrama ER (Draw.io ou Lucidchart) com todas as 6 tabelas e relações
- [ ] Criar `01-ddl.sql`:
  - Tabelas: `Utilizadores`, `Contadores`, `Leituras` (particionada por mês), `OfertasVenda`, `OrdensCompra`, `Transacoes`
  - Adicionar coluna `Regiao` em `Contadores`, `OfertasVenda`, `OrdensCompra` (necessária para matching)
  - Constraints: `CHECK`, `UNIQUE`, `FK`
  - Partições mensais de Leituras (2025-01 a 2026-12)
  - Índices: GIN em `DadosAudit`, B-tree em colunas de filtragem frequente, índices parciais para `Estado = 'ATIVA'`
- [ ] Criar `02-seed-mini.sql` (~100 registos) para testes do E1
- [ ] Solicitar e validar acesso ao servidor da escola ✅
- [ ] Testar DDL localmente (Docker) e no servidor da escola

**Entrega para E1**: `01-ddl.sql` + `02-seed-mini.sql` + `procedure_specs.md` (assinaturas das procedures)

---

### 🤝 Sincronização Fim de Semana 1
- E2 entrega DDL + seed mini ao E1
- E1 confirma que consegue ligar a BD local com o DDL recebido
- Validar que ambos têm o servidor da escola acessível

---

## 🟡 FASE 2 — Lógica de Negócio & Core API
### Semana 2 · Desenvolvimento paralelo com ponto de integração no fim

> ⚠️ **Checkpoint 1 (8/Abril)**: Tabelas criadas no servidor da escola + 500k leituras + 1k ofertas

### E1 — API Spring Boot

**Objetivo**: Autenticação funcional + endpoint de leituras operacional.

- [ ] **Autenticação**
  - `Utilizador` entity + `UtilizadorRepository`
  - `AuthService` com BCrypt (força 12) para hashing
  - `JwtUtil` para geração e validação de tokens
  - `JwtAuthenticationFilter` + `UserDetailsServiceImpl`
  - `POST /api/auth/register` e `POST /api/auth/login`
  - Testar registo, login e rejeição de token inválido

- [ ] **Leituras de Contadores**
  - `Leitura` e `Contador` entities (com mapeamento JSONB)
  - `LeituraRepository` + `MeterService`
  - `POST /api/meters/readings` — inserção com payload JSONB em `DadosAudit`
  - `GET /api/meters/{id}/readings` — leituras com filtro de data
  - Garantir Prepared Statements em todas as queries (`$1`, `$2`, ...)

---

### E2 — Base de Dados PostgreSQL

**Objetivo**: Procedures e triggers implementados e testados via psql.

- [ ] **Stored Procedure: `sp_ExecutarCompraDireta`**
  - Parâmetros: `p_oferta_id`, `p_comprador_id`, `p_quantidade`
  - Lógica ACID: `SELECT ... FOR UPDATE`, verificar estado `'ATIVA'`, debitar comprador, creditar vendedor, registar em `Transacoes`, atualizar `OfertasVenda`
  - Lançar exceções com mensagens claras (saldo insuficiente, oferta inativa, etc.)
  - Testar via psql com `BEGIN / CALL / ROLLBACK`

- [ ] **Stored Procedure: `sp_MatchingEngine`**
  - Varrer `OrdensCompra` com estado `'PENDENTE'`
  - Para cada ordem, procurar `OfertasVenda` compatível: 1º preço (compra ≥ venda), 2º mesma região, 3º data mais antiga
  - Se match → gerar `Transacoes`, atualizar estados
  - Testar com dados de seed

- [ ] **Trigger 1: `trg_DetectarAnomalias`** (`AFTER INSERT ON Leituras`)
  - Se `temperatura > 80` OU `erro_codigo` não nulo → `UPDATE Contadores SET Estado = 'MANUTENCAO'`

- [ ] **Trigger 2: `trg_ProtegerUtilizadores`** (`BEFORE DELETE ON Utilizadores`)
  - Bloquear remoção se `Saldo > 0` ou transações recentes (ex: últimos 30 dias)

- [ ] **(Excelência) Trigger de Auto-Matching**: `AFTER INSERT` em `OrdensCompra` e `OfertasVenda` que dispara `sp_MatchingEngine` automaticamente

- [ ] **Checkpoint 1** — Carregar no servidor da escola:
  - Executar `01-ddl.sql`
  - Seeding: 500.000+ leituras (`generate_series`), 1.000 ofertas de venda

---

### 🤝 Sincronização Fim de Semana 2
- E2 entrega `03-procedures.sql` e `04-triggers.sql` ao E1
- E1 começa a integrar as procedures nos serviços
- Validar Checkpoint 1 no servidor da escola

---

## 🟠 FASE 3 — Endpoints de Mercado & Integração
### Semana 3 · Foco na integração e funcionalidades de mercado

### E1 — API Spring Boot

**Objetivo**: Todos os endpoints obrigatórios implementados e a chamar as procedures.

- [ ] **Endpoints de Mercado**
  - `GET /api/market/offers` — listar ofertas ativas (com filtros opcionais por região/preço)
  - `POST /api/market/buy` — chama `sp_ExecutarCompraDireta` via `@Procedure` ou `SimpleJdbcCall`
  - `POST /api/market/order` — inserção em `OrdensCompra`
  - `POST /api/market/match` — chama `sp_MatchingEngine` (obrigatório mesmo com trigger automático)

- [ ] **Endpoint de Administração**
  - `GET /api/admin/anomalies` — query JSONB otimizada (usar índice GIN): contadores em `'MANUTENCAO'` com dados anómalos

- [ ] Substituir qualquer SQL direto temporário pelas stored procedures recebidas do E2
- [ ] Validar Prepared Statements em todos os endpoints
- [ ] Tratar exceções da BD (mensagens de erro claras para o cliente)
- [ ] Testar fluxo completo: registo → login → criar oferta → comprar → verificar saldo

---

### E2 — Base de Dados PostgreSQL

**Objetivo**: Otimização, seeding massivo completo e servidor da escola estável.

- [ ] Validar e otimizar todos os scripts SQL (procedures + triggers) com dados reais
- [ ] Executar `EXPLAIN ANALYZE` nas queries críticas:
  - Pesquisa de anomalias JSONB
  - Query de matching (filtro por estado, preço e região)
  - Listagem de ofertas ativas
- [ ] Confirmar que os índices GIN e parciais estão a ser usados nos planos de execução
- [ ] Garantir seeding completo no servidor da escola (500k leituras, 1k ofertas, dados variados para matching funcionar)
- [ ] Criar `teste_procedures.sql` — script de testes isolados para cada procedure/trigger
- [ ] Documentar resultados dos `EXPLAIN ANALYZE` (guardar outputs para o relatório)

---

### 🤝 Sincronização Fim de Semana 3
- Testes end-to-end: E1 chama procedures via API contra servidor da escola
- Resolver bugs de integração (tipos de dados, nomes de parâmetros, etc.)
- Confirmar que matching engine funciona (criar ordens + ofertas compatíveis e verificar transações geradas)

---

## 🔴 FASE 4 — Deploy, Segurança & Entrega Final
### Semana 4 · Polimento, deploy e documentação

> ⚠️ **Checkpoint 2 (13/Maio)**: API online + Procedures funcionais + Demonstração de segurança

### E1 — API Spring Boot

**Objetivo**: API deployed, segura e documentada.

- [ ] **Deploy em Cloud**
  - Configurar variáveis de ambiente para produção (`DATASOURCE_URL`, `JWT_SECRET`, etc.)
  - Deploy em Railway ou Render com ligação ao servidor da escola
  - Testar todos os endpoints em produção

- [ ] **Testes de Segurança**
  - Tentar SQL Injection em todos os campos de input — deve falhar com Prepared Statements
  - Verificar que endpoints protegidos retornam `401` sem token JWT válido
  - Confirmar BCrypt com fator de custo ≥ 12

- [ ] **Qualidade do Código**
  - Logging adequado com `@Slf4j` nos serviços
  - Tratamento global de exceções (`@ControllerAdvice`)
  - Remover `node_modules` / `.class` files do ZIP de entrega

- [ ] Criar `postman_collection.json` com exemplos de todos os endpoints

---

### E2 — Base de Dados PostgreSQL

**Objetivo**: BD finalizada, documentada e relatório técnico completo.

- [ ] Criar `05-seed-massivo.sql` otimizado com `generate_series` (validar os 500k+ registos)
- [ ] Verificar integridade referencial completa no servidor da escola
- [ ] **Relatório Técnico (PDF)**:
  - Diagrama ER final
  - Justificação de cada índice criado e tipo escolhido (GIN vs B-tree vs parcial)
  - Resultados de `EXPLAIN ANALYZE` antes/depois de índices
  - Descrição do particionamento e por que por data
  - Descrição das procedures e triggers (fluxo + lógica)
  - Plano de execução do matching engine
- [ ] Confirmar que todos os scripts SQL estão organizados e comentados:
  - `ddl.sql`, `seed.sql`, `logic.sql`

---

### 🤝 Sincronização Final — Semana 4
- [ ] Validar Checkpoint 2: API online, procedures chamadas com sucesso, demo de SQL Injection falhada
- [ ] Testar fluxo completo de ponta a ponta em produção
- [ ] Organizar ZIP de entrega final:
  ```
  voltexchange-entrega.zip
  ├── api/                        (código Spring Boot, sem node_modules)
  ├── sql/
  │   ├── ddl.sql
  │   ├── seed.sql
  │   └── logic.sql
  └── relatorio/
      └── relatorio-tecnico.pdf
  ```
- [ ] Preparar defesa: cada elemento deve conseguir explicar **todo** o projeto, não apenas a sua parte

---

## 📋 Checklist de Entregas Cruzadas

| # | De | Para | O quê | Quando |
|---|----|------|-------|--------|
| 1 | E2 | E1 | `01-ddl.sql` + `02-seed-mini.sql` + `procedure_specs.md` | Fim Semana 1 |
| 2 | E1 | E2 | `docker-compose.yml` + `api_specs.md` | Fim Semana 1 |
| 3 | E2 | E1 | `03-procedures.sql` + `04-triggers.sql` | Fim Semana 2 |
| 4 | E1 | E2 | `postman_collection.json` para validação | Fim Semana 3 |
| 5 | E2 | E1 | Credenciais servidor da escola + `EXPLAIN ANALYZE` outputs | Semana 4 |

---

## 🚨 Plano B

| Problema | Solução |
|----------|---------|
| Procedures atrasam | E1 mantém SQL direto nas transactions; integra no final |
| Servidor da escola inacessível | Usar PostgreSQL no Docker + Railway com BD incluída |
| Deploy falha | Testar localmente com `ngrok` para demo temporária |
| Seeding demora muito | Usar `UNLOGGED TABLE` temporária, converter depois |

---

## 🎯 Critérios para Nota Máxima

- ✅ Trigger de Auto-Matching implementado (solução reativa/event-driven)
- ✅ `EXPLAIN ANALYZE` documentado com evidência de uso de índices
- ✅ Diagrama ER profissional no relatório
- ✅ Testes de SQL Injection documentados (evidência de segurança)
- ✅ Código comentado e organizado
- ✅ Ambos os elementos conseguem explicar qualquer parte do projeto na defesa
