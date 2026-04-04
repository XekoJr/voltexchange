# 📅 Plano Actualizado — VoltExchange

> **Projeto**: BD II — Sistema de Mercado de Energia P2P
> **Data**: 4 Abril 2026
> **CP1**: 8 Abril 2026 (em 4 dias)
> **CP2**: 13 Maio 2026

---

## ✅ O QUE ESTÁ FEITO (resumo)

### Base de Dados — 100% ✅
| Script | Conteúdo | Estado |
|--------|----------|--------|
| 01-schema.sql | 6 tabelas + constraints + FKs | ✅ Testado em Docker |
| 02-partitions.sql | 24 partições mensais 2025-2026 | ✅ Testado em Docker |
| 03-indexes.sql | 22 índices (GIN, parciais, compostos) | ✅ Testado em Docker |
| 04-procedures.sql | sp_ExecutarCompraDireta + sp_MatchingEngine | ✅ Testado em Docker |
| 05-triggers.sql | 4 triggers (anomalias + proteção + auto-matching) | ✅ Testado em Docker |
| 06-seed-mini.sql | 10 utilizadores, 50 leituras, 20 ofertas, 10 ordens | ✅ Testado em Docker |
| 07-seed-massivo.sql | 500.000 leituras + 1.000 ofertas + 500 ordens | ✅ Testado em Docker |
| 08-views.sql | 5 vistas (anomalias, mercado, transações, consumo, resumo) | ✅ Testado em Docker |

### API Express.js — 100% ✅
> A API foi completamente reescrita em **Node.js (Express)** — Spring Boot abandonado.

- ✅ 13 endpoints funcionais (auth, meters, market, admin, health)
- ✅ JWT Bearer + bcryptjs strength 12
- ✅ Parameterized queries (anti-SQL injection)
- ✅ Docker build funcional (`docker compose up --build`)
- ✅ `.env` único para toda a configuração

---

## 🔴 PRIORIDADE MÁXIMA — CP1 em 4 dias (8 Abril)

### Tarefa 1 — Executar no Servidor da Escola ⚠️ BLOQUEADOR
```
Hoje / amanhã (5-6 Abril)
```
1. Obter credenciais do servidor PostgreSQL da escola (se ainda não tens)
2. Executar os scripts **em ordem**:
   ```bash
   psql -h HOST -U USER -d voltexchange -f 01-schema.sql
   psql -h HOST -U USER -d voltexchange -f 02-partitions.sql
   psql -h HOST -U USER -d voltexchange -f 03-indexes.sql
   psql -h HOST -U USER -d voltexchange -f 04-procedures.sql
   psql -h HOST -U USER -d voltexchange -f 05-triggers.sql
   psql -h HOST -U USER -d voltexchange -f 06-seed-mini.sql
   psql -h HOST -U USER -d voltexchange -f 07-seed-massivo.sql
   psql -h HOST -U USER -d voltexchange -f 08-views.sql
   ```
3. Validar:
   - [ ] `SELECT COUNT(*) FROM leituras;` → 500050
   - [ ] `SELECT COUNT(*) FROM ofertasvenda;` → 1020
   - [ ] `SELECT COUNT(*) FROM contadores WHERE estado='MANUTENCAO';` → 10
   - [ ] `CALL sp_ExecutarCompraDireta(1, 1, 5.0);` → deve funcionar ou dar erro descritivo
   - [ ] `CALL sp_MatchingEngine();` → deve processar matches
- **Tempo estimado**: 2h

### Tarefa 2 — Testar API Local Completa (Postman) ⚠️ BLOQUEADOR
```
6-7 Abril
```
Fluxo obrigatório a demonstrar no CP1:
1. [ ] `POST /api/auth/register` → receber JWT
2. [ ] `POST /api/auth/login` → receber JWT
3. [ ] `GET /api/meters` → listar contadores
4. [ ] `POST /api/meters/:id/readings` → submeter leitura (normal + anómala)
5. [ ] `GET /api/meters/:id/readings?inicio=2025-01-01&fim=2025-12-31` → leituras do período
6. [ ] `GET /api/market/offers` → listar ofertas
7. [ ] `POST /api/market/offers` → criar oferta
8. [ ] `POST /api/market/offers/:id/buy` → compra direta
9. [ ] `POST /api/market/order` → criar ordem
10. [ ] `POST /api/market/match` → matching engine
11. [ ] `GET /api/admin/anomalies` → ver anomalias e contadores em MANUTENCAO
12. [ ] `GET /api/admin/transactions` → ver histórico
- **Tempo estimado**: 3h

### Tarefa 3 — Postman Collection Documentada
```
7 Abril
```
A collection `VoltExchange.postman_collection.json` já existe — garantir que tem:
- [ ] Pre-request script que guarda o JWT automaticamente em variável de ambiente
- [ ] Exemplos de request e response em cada endpoint
- [ ] Pelo menos 1 caso de erro documentado por endpoint (ex: 401, 400)
- **Tempo estimado**: 2h

---

## 🟠 SEMANA 2-3 (9-27 Abril) — Deploy + Testes de Segurança

### Tarefa 4 — Deploy Cloud ⚠️ OBRIGATÓRIO CP2
Plataformas recomendadas (gratuitas):
- **Railway** (mais simples, suporta Node.js directamente)
- **Render** (alternativa)

Passos:
- [ ] Criar conta Railway / Render
- [ ] Conectar repositório GitHub
- [ ] Configurar variáveis de ambiente (PORT, DB_HOST apontando para escola, DB_*, JWT_SECRET)
- [ ] Fazer deploy
- [ ] Testar todos os endpoints em produção
- **Tempo estimado**: 3h

### Tarefa 5 — Testes de Segurança Documentados
- [ ] SQL Injection: tentar `email = "' OR 1=1 --"` → deve retornar 400/401
- [ ] Acesso sem token → deve retornar 401
- [ ] Token expirado → deve retornar 401
- [ ] Token de outro utilizador a aceder ao contador alguém → deve retornar 403
- [ ] Confirmar BCrypt: `SELECT password_hash FROM utilizadores LIMIT 1;` → deve começar com `$2b$12$`
- [ ] Documentar com prints / curl output
- **Tempo estimado**: 2h

### Tarefa 6 — EXPLAIN ANALYZE
Importante para o relatório:
- [ ] Antes dos índices: simular com `SET enable_indexscan = off;`
- [ ] Query de anomalias JSONB (GIN index)
- [ ] Query de leituras por período com e sem partition pruning
- [ ] Query do matching engine (composite indexes)
- [ ] Exportar resultados e incluir no relatório
- **Tempo estimado**: 2h

### Tarefa 7 — README.md Actualizado
O `README.md` actual diz "Spring Boot" e "22% progresso" — está completamente desatualizado:
- [ ] Reescrever com arquitectura actual (Node.js + Express)
- [ ] Instruções `docker compose up --build`
- [ ] Lista de endpoints
- [ ] Credenciais de teste (alice@voltexchange.com / senha123)
- **Tempo estimado**: 1h

---

## 🟡 SEMANA 4 (28 Abril – 13 Maio) — Relatório + Defesa

### Tarefa 8 — Diagrama ER
- [ ] Desenhar em Draw.io ou Lucidchart
- [ ] Todas as 6 tabelas, PKs, FKs, cardinalidades
- [ ] Exportar como PNG para o relatório
- **Tempo estimado**: 2h

### Tarefa 9 — Relatório Técnico PDF ⚠️ OBRIGATÓRIO CP2
Estrutura sugerida:
1. Introdução e objectivos
2. Arquitectura do sistema (diagrama)
3. Modelo de dados (ER + descrição das tabelas)
4. Particionamento: justificação + impacto de performance
5. Índices: cada índice com tipo, propósito e resultado EXPLAIN ANALYZE
6. Stored Procedures: lógica + fluxo de execução
7. Triggers: lógica + casos de teste
8. API REST: endpoints, segurança (JWT + BCrypt), anti-injection
9. Critérios de excelência: auto-matching, views, seed massivo
10. Conclusões
- **Tempo estimado**: 6h

### Tarefa 10 — Preparação da Defesa
- [ ] Ambos conseguem explicar cada tabela e porquê as choices de design
- [ ] Ambos conseguem explicar as stored procedures linha a linha
- [ ] Ambos conseguem explicar o particionamento e partition pruning
- [ ] Ambos conseguem executar uma demo ao vivo (Postman + psql)
- [ ] Perguntas difíceis preparadas: "Porquê Express em vez de Spring Boot?", "O que acontece a um INSERT fora das partições?"
- **Tempo estimado**: 3h

---

## 📊 Resumo de Tempos

| Tarefa | Quando | Tempo Est. | Estado |
|--------|--------|------------|--------|
| 1 — Servidor da escola | 5-6 Abril | 2h | ❌ |
| 2 — Testes Postman CP1 | 6-7 Abril | 3h | ❌ |
| 3 — Postman collection documentada | 7 Abril | 2h | ⚠️ Parcial |
| 4 — Deploy Cloud | 9-15 Abril | 3h | ❌ |
| 5 — Testes de Segurança | 15-20 Abril | 2h | ❌ |
| 6 — EXPLAIN ANALYZE | 15-20 Abril | 2h | ❌ |
| 7 — README.md | 20 Abril | 1h | ❌ |
| 8 — Diagrama ER | 28+ Abril | 2h | ❌ |
| 9 — Relatório PDF | 1-10 Maio | 6h | ❌ |
| 10 — Defesa | 10-13 Maio | 3h | ❌ |
| **TOTAL** | | **26h** | |

---

## 🏆 Critérios de Excelência — JÁ IMPLEMENTADOS ✅

Os seguintes bónus já estão feitos e devem ser **destacados no relatório e na defesa**:

- ✅ **Trigger de Auto-Matching** — `trg_AutoMatching_Ordem` e `trg_AutoMatching_Oferta` disparam `sp_MatchingEngine` automaticamente a cada novo INSERT
- ✅ **5 Views** — `vw_anomalias_detalhadas`, `vw_mercado_ativo`, `vw_transacoes_detalhadas`, `vw_consumo_mensal`, `vw_resumo_utilizadores`
- ✅ **Seed Massivo real** — 500.000 leituras com distribuição realista (80%/15%/5%)
- ✅ **Health check endpoint** — `GET /api/health`
- ✅ **Índices GIN em JSONB** — `idx_leituras_dados_audit_gin`
- ✅ **Índices parciais** — `idx_ofertas_regiao_ativa`, `idx_ordens_regiao_pendente`, `idx_utilizadores_saldo`
- ✅ **\echo logging nas migrações** — visibilidade de quais scripts correram
- ✅ **docker-compose.yml sem credenciais hardcoded** — 100% baseado em .env

---

## 🎯 Checklist CP1 (8 Abril)

- [ ] Servidor da escola: scripts executados
- [ ] Servidor da escola: 500.000+ leituras confirmadas
- [x] API funcional localmente
- [x] Auth endpoint funcional (JWT)
- [x] Stored procedures funcionais
- [x] Triggers funcionais
- [ ] Postman collection com fluxo completo testado
- [ ] Demo preparada (5 min): registo → login → leitura → anomalia → matching

## 🎯 Checklist CP2 (13 Maio)

- [ ] API deployed em cloud
- [ ] Todos os endpoints funcionais em produção
- [ ] Testes de segurança documentados
- [ ] Relatório técnico PDF completo
- [ ] Diagrama ER incluído
- [ ] EXPLAIN ANALYZE documentado
- [ ] Postman collection documentada e exportada
- [ ] Defesa preparada (ambos os elementos)