# 📅 Plano Atualizado — VoltExchange (Restantes 3.5 Semanas)

> **Projeto**: BD II — Sistema de Mercado de Energia P2P  
> **Progresso Atual**: 58% | **Status**: 🟢 Fase 2 em andamento  
> **Checkpoints**: CP1 → 8/Abril · CP2 → 13/Maio  
> **Data Atual**: 14 Março 2026

---

## ✅ O QUE JÁ ESTÁ FEITO

### Base de Dados (35%)
- ✅ Projeto Spring Boot criado e estruturado (Gradle)
- ✅ Todas as 6 tabelas criadas em `01-schema.sql`
- ✅ **24 partições criadas em `02-partitions.sql` (2025-2026)**
- ✅ Constraints, Foreign Keys e CHECKs implementados

### API Spring Boot (85%) ✨ QUASE COMPLETA!
- ✅ **Todas as 6 Entities completas** (Utilizador, Contador, Leitura, OfertaVenda, OrdemCompra, Transacao)
- ✅ **Todos os 6 Repositories com queries customizadas**
- ✅ **Todos os 4 Services** (AuthService, MeterService, MarketService, AdminService)
- ✅ **Todos os 4 Controllers** (Auth, Meter, Market, Admin)
- ✅ **Segurança completa**: JWT + BCrypt 12 + Spring Security
- ✅ **7 DTOs com validações** (@Valid, @NotNull, @Email, @Positive)
- ✅ GlobalExceptionHandler implementado
- ✅ CorsConfig configurado
- ✅ application.properties configurado
- ⚠️ **Falta apenas**: docker-compose.yml, application-prod.properties, testes

## 🎯 FOCO DAS PRÓXIMAS SEMANAS

| Semana | Prioridade | Responsável | Tempo Est. |
|--------|-----------|-------------|------------|
| **1** (restante) | 🔴 BD: Índices + Procedures + Triggers | Pessoa 2 | 14h |
| **2** | 🟠 API: Docker + Testes + Postman | Pessoa 1 | 8h |
| **3** | 🟠 Integração + Seed Massivo | Pessoa 1 + Pessoa 2 | 12h |
| **4** | 🟡 Deploy + Relatório + Defesa | Pessoa 1 + Pessoa 2 | 14h |

---

## 📋 SEMANA 1 (restante) — Completar Base de Dados

### 🔴 PRIORIDADE MÁXIMA (Pessoa 2)

#### 1. Índices de Performance ⚠️ CRÍTICO
```bash
Criar: migrations/03-indexes.sql
```
- [ ] Índice GIN em `Leituras.dados_audit`
- [ ] Índices compostos para matching engine
- [ ] Índices parciais (WHERE estado='ATIVA', WHERE estado='PENDENTE')
- [ ] Índices em todas as Foreign Keys
- [ ] Executar EXPLAIN ANALYZE ANTES
- [ ] Aplicar índices
- [ ] Executar EXPLAIN ANALYZE DEPOIS
- **Tempo estimado**: 3h

#### 2. Stored Procedures ⚠️ OBRIGATÓRIO CP1
```bash
Criar: migrations/04-procedures.sql
```
- [ ] `sp_ExecutarCompraDireta` completa
- [ ] `sp_MatchingEngine` completa
- [ ] Testar ambas com dados mock
- [ ] Documentar exceções
- **Tempo estimado**: 6h

#### 3. Triggers ⚠️ OBRIGATÓRIO CP1
```bash
Criar: migrations/05-triggers.sql
```
- [ ] Trigger `trg_DetectarAnomalias`
- [ ] Trigger `trg_ProtegerUtilizadores`
- [ ] Testar com casos reais
- **Tempo estimado**: 3h

#### 4. Seed Inicial
```bash
Criar: migrations/06-seed-mini.sql
```
- [ ] 10 utilizadores
- [ ] 10 contadores
- [ ] 50 leituras (normais + anômalas)
- [ ] 20 ofertas
- [ ] 10 ordens
- **Tempo estimado**: 2h

### 📝 Entregáveis da Semana 1 (Pessoa 2 → Pessoa 1)
- `03-indexes.sql` ✅
- `04-procedures.sql` ✅
- `05-triggers.sql` ✅
- `06-seed-mini.sql` ✅
- Documento: assinaturas e exemplos de uso das procedures

---

---

## 📋 SEMANA 2 — Docker + Testes + Validação

> ⚠️ **Checkpoint 1 (8/Abril)**: Tabelas criadas no servidor da escola + Procedures funcionais + API testada localmente

### 🟢 API JÁ COMPLETA - Apenas Testes e Docker (Pessoa 1)

ℹ️ **NOTA**: A API já está 85% implementada! Entities, Repositories, Services, Controllers e Security estão TODOS completos.

#### 1. Docker Compose ⚠️ PRIORITÁRIO
- [ ] `docker-compose.yml` com PostgreSQL
- [ ] Configuração de volumes para persistência
- [ ] pgAdmin/Adminer opcional
- [ ] Testar `docker-compose up`
- [ ] Validar conexão da API
- **Tempo estimado**: 2h

#### 2. Testes Locais Completos
- [ ] Testar registo de utilizador (POST /api/auth/register)
- [ ] Testar login e receber JWT (POST /api/auth/login)
- [ ] Testar inserção de leitura com token (POST /api/meters/{id}/readings)
- [ ] Testar listagem de leituras (GET /api/meters/{id}/readings?inicio=...&fim=...)
- [ ] Testar criação de oferta (POST /api/market/offers)
- [ ] Testar compra direta (POST /api/market/offers/{id}/buy) → REQUER procedures!
- [ ] Testar matching engine (POST /api/market/match) → REQUER procedures!
- [ ] Testar anomalias (GET /api/admin/anomalies)
- **Tempo estimado**: 4h

#### 3. Postman Collection 📋
- [ ] Criar collection com todos os endpoints
- [ ] Adicionar exemplos de request/response
- [ ] Script de auto-save do token JWT
- [ ] Exportar como JSON
- **Tempo estimado**: 2h

### ✅ Validação Semana 2
- [ ] Docker Compose funcional
- [ ] Consegue registar utilizador
- [ ] Consegue fazer login e receber JWT
- [ ] Consegue inserir leitura com token
- [ ] Consegue listar leituras de um contador
- [ ] Triggers funcionam (anomalias detectadas)
- [ ] Postman Collection exportada

### 🎯 Checkpoint 1 - Preparação (Fim Semana 2)
- [ ] Executar DDL + partitions + indexes + procedures + triggers no servidor da escola
- [ ] Carregar seed inicial no servidor
- [ ] API local funcional com Auth + Leituras
- [ ] Demonstração: registo → login → inserir leitura → detectar anomalia

---

## 📋 SEMANA 3 — Integração & Seed Massivo

### 🟢 API JÁ INTEGRADA - Apenas Testes End-to-End (Pessoa 1 + Pessoa 2)

ℹ️ **NOTA**: Os endpoints de mercado JÁ estão implementados! MarketService e MarketController completos com SimpleJdbcCall.

#### Pessoa 1 - Testes de Integração Completos
- [ ] Testar fluxo completo: registo → login → criar oferta → comprar → verificar saldo
- [ ] Testar matching engine processa ordens corretamente
- [ ] Validar saldos após transações (débito/crédito corretos)
- [ ] Validar estados das ofertas/ordens (ATIVA → PARCIAL → COMPLETA)
- [ ] Testar casos de erro (saldo insuficiente, oferta inativa)
- [ ] Query de anomalias retorna contadores em manutenção
- [ ] Procedures chamadas com sucesso via API
- **Tempo estimado**: 5h

#### Pessoa 2 - Seeding Massivo ⚠️ OBRIGATÓRIO CP1
```bash
Criar: migrations/07-seed-massivo.sql
```
- [ ] 500.000+ leituras com `generate_series`
- [ ] 1.000+ ofertas de venda
- [ ] Distribuição realista por regiões (Norte, Centro, Sul)
- [ ] Dados variados (datas entre 2025-2026, preços 0.08-0.20, estados)
- [ ] Leituras normais (80%) e anómalas (20%)
- [ ] Executar no servidor da escola
- [ ] Validar integridade referencial
- [ ] Medir tempo de inserção
- **Tempo estimado**: 5h

#### Pessoa 1 - application-prod.properties
- [ ] Configurar URL do servidor da escola
- [ ] Configurar credenciais (via variáveis de ambiente)
- [ ] Configurar logging para produção
- [ ] JWT secret forte (variável de ambiente)
- **Tempo estimado**: 1h

#### Pessoa 2 - Validações e Otimizações
- [ ] Validar performance com 500k+ leituras
- [ ] EXPLAIN ANALYZE nas queries críticas
- [ ] Documentar ganhos de performance dos índices
- [ ] Ajustar índices se necessário
- **Tempo estimado**: 1h

### ✅ Validação Semana 3
- [ ] 500.000+ leituras carregadas no servidor da escola
- [ ] Fluxo completo end-to-end funcional
- [ ] Matching engine processa múltiplas ordens corretamente
- [ ] Performance aceitável (queries < 1s)
- [ ] application-prod.properties configurado

---

## 📋 SEMANA 4 — Deploy, Seeding Massivo & Entrega Final

> ⚠️ **Checkpoint 2 (13/Maio)**: API online + Seeding massivo completo + Relatório + Defesa

### 🟡 FINALIZAÇÃO (Pessoa 1 + Pessoa 2)

#### Pessoa 2 - Seeding Massivo ⚠️ OBRIGATÓRIO CP2
```bash
Criar: migrations/07-seed-massivo.sql
```
- [ ] 500.000+ leituras com `generate_series`
- [ ] 1.000+ ofertas de venda
- [ ] Distribuição realista por regiões
- [ ] Dados variados (datas, preços, estados)
- [ ] Executar no servidor da escola
- [ ] Validar integridade referencial
- **Tempo estimado**: 4h

#### Pessoa 1 - Deploy em Cloud ⚠️ OBRIGATÓRIO CP2
- [ ] Escolher plataforma (Railway/Render)
- [ ] Configurar variáveis de ambiente
- [ ] `application-prod.properties` configurado
- [ ] Deploy realizado
- [ ] Conexão com servidor da escola testada
- [ ] Todos os endpoints testados em produção
- **Tempo estimado**: 3h

#### Pessoa 1 - Testes de Segurança ⚠️ OBRIGATÓRIO
- [ ] Tentar SQL Injection em todos os campos → deve falhar
- [ ] Testar acesso sem token → deve retornar 401
- [ ] Testar token expirado → deve retornar 401
- [ ] Confirmar BCrypt ≥ 12
- [ ] Documentar testes com prints
- **Tempo estimado**: 2h

#### Pessoa 1 + Pessoa 2 - Documentação ⚠️ OBRIGATÓRIO CP2

**Postman Collection**
- [ ] Criar collection com exemplos de todos os endpoints
- [ ] Adicionar exemplos de requests/responses
- [ ] Exportar como JSON
- **Tempo estimado**: 2h

**Relatório Técnico (PDF)**
- [ ] Diagrama ER profissional (Draw.io/Lucidchart)
- [ ] Descrição de todas as tabelas
- [ ] Justificação de cada índice (tipo e propósito)
- [ ] Resultados EXPLAIN ANALYZE (antes/depois)
- [ ] Descrição do particionamento (porquê e impacto)
- [ ] Descrição das procedures (lógica + fluxo)
- [ ] Descrição dos triggers (lógica + fluxo)
- [ ] Plano de execução do matching engine
- [ ] Screenshots dos testes de segurança
- [ ] Screenshots da aplicação funcionando
- **Tempo estimado**: 6h

**Scripts SQL Finais**
- [ ] Organizar todos os scripts na pasta `migrations/`
- [ ] Validar ordem de execução
- [ ] Testar sequência completa em BD limpa
- [ ] Adicionar comentários onde necessário
- **Tempo estimado**: 2h

#### Pessoa 1 + Pessoa 2 - Preparação da Defesa
- [ ] Ambos conseguem explicar estrutura da BD
- [ ] Ambos conseguem explicar procedures/triggers
- [ ] Ambos conseguem explicar arquitectura da API
- [ ] Ambos conseguem explicar segurança implementada
- [ ] Demo ao vivo preparada
- [ ] Respostas a perguntas técnicas preparadas
- **Tempo estimado**: 3h

### 🎯 Checkpoint 2 - Entrega Final (13 Maio)

#### Organização do ZIP
```
voltexchange-entrega.zip
├── api/                        
│   ├── src/                    (código Spring Boot)
│   ├── build.gradle
│   └── README.md
├── migrations/
│   ├── 01-schema.sql
│   ├── 02-partitions.sql
│   ├── 03-indexes.sql
│   ├── 04-procedures.sql
│   ├── 05-triggers.sql
│   ├── 06-seed-mini.sql
│   └── 07-seed-massivo.sql
├── docs/
│   ├── relatorio-tecnico.pdf
│   ├── diagrama-er.png
│   └── VoltExchange.postman_collection.json
├── README.md
└── .gitignore
```

#### Checklist Final
- [ ] Código limpo (sem node_modules, target/, .class)
- [ ] .gitignore configurado
- [ ] README.md completo com instruções
- [ ] Todos os scripts testados
- [ ] API deployed e online
- [ ] Postman collection testada
- [ ] Relatório completo
- [ ] Defesa preparada

---

## 🏆 CRITÉRIOS DE EXCELÊNCIA (Bonus)

Se houver tempo extra, implementar:

- [ ] **Trigger de Auto-Matching**: AFTER INSERT em OrdensCompra e OfertasVenda
- [ ] **Views úteis**: vw_OfertasAtivas, vw_TransacoesRecentes
- [ ] **Logs estruturados**: na API com níveis apropriados
- [ ] **Health check endpoint**: GET /api/health
- [ ] **Paginação**: em listagens longas
- [ ] **Filtros avançados**: nas queries de ofertas/ordens
- [ ] **Tratamento de edge cases**: saldo exato, quantidade parcial, etc.
- [ ] **Testes unitários**: alguns testes básicos

---

## 📊 RESUMO DE TEMPOS ESTIMADOS

| Semana | Pessoa 1 (API) | Pessoa 2 (BD) | Total |
|--------|----------------|---------------|-------|
| 1 | — | 14h | 14h |
| 2 | 8h | — | 8h |
| 3 | 6h | 6h | 12h |
| 4 | 5h | 9h | 14h |
| **TOTAL** | **19h** | **29h** | **48h** |

**Por pessoa**: ~24h (aprox. 6h/semana)

ℹ️ **NOTA**: Tempo reduzido face à estimativa inicial porque **85% da API já está implementada**!

---

## 🚨 ALERTAS E LEMBRETES

### ⚠️ CRÍTICO - Não esquecer:
1. ~~**Partições** da tabela Leituras~~ ✅ FEITO!
2. ~~**Entities, Repositories, Services, Controllers**~~ ✅ FEITO!
3. ~~**JWT + BCrypt 12**~~ ✅ FEITO!
4. **Índice GIN** no JSONB (obrigatório no relatório) ❌ FALTA
5. **Procedures** funcionais (obrigatório CP1) ❌ FALTA
6. **Triggers** funcionais (obrigatório CP1) ❌ FALTA
7. **500k leituras** no servidor da escola (obrigatório CP2) ❌ FALTA

### 💡 DICAS:
- Fazer commits frequentes
- Testar cada componente isoladamente antes de integrar
- Usar seed-mini para desenvolvimento, seed-massivo só no final
- Documentar à medida que desenvolve (não deixar para o fim)
- Ambas as pessoas devem entender TODO o projeto (não apenas "a sua parte")

---

## 📞 SINCRONIZAÇÕES SEMANAIS

| Dia | Objetivo |
|-----|----------|
| **Sexta S1** | Pessoa 2 entrega scripts SQL à Pessoa 1 |
| **Domingo S2** | Validar CP1 no servidor da escola |
| **Sexta S3** | Testes integração completos |
| **Terça S4** | Revisão final antes da entrega |

---

**Boa sorte! 🚀⚡**
