# 📊 Progresso do Projeto VoltExchange

> **Última atualização**: 14 Março 2026  
> **Status Geral**: 🟡 Em Desenvolvimento - Fase 1 (Setup & Fundações)

---

## 📈 Visão Geral do Progresso

| Categoria | Progresso | Status |
|-----------|-----------|--------|
| 🗄️ Base de Dados | 35% | 🟡 Em Progresso |
| 🌐 API Spring Boot | 85% | 🟢 Quase Completa |
| 🔐 Segurança | 0% | 🔴 Não Iniciado |
| 🚀 Deploy | 0% | 🔴 Não Iniciado |
| 📝 Documentação | 15% | 🟡 Em Progresso |

**Total Geral**: ⚡ **58%** completo

---

## 🗄️ BASE DE DADOS (30% completo)

### 📋 1. Estrutura de Tabelas

#### Tabela: Utilizadores
- [x] Estrutura da tabela criada
- [x] Primary Key definida
- [x] Constraints CHECK (saldo >= 0)
- [x] Constraint de validação de email
- [x] Campo único (email)
- [ ] Comentários COMMENT ON TABLE/COLUMN
- [ ] Índice em email
- [ ] Índice parcial em saldo
- [ ] Índice em data_criacao

#### Tabela: Contadores
- [x] Estrutura da tabela criada
- [x] Primary Key definida
- [x] Foreign Key para Utilizadores
- [x] Campo numero_serie UNIQUE
- [x] Campo regiao adicionado
- [x] Constraint CHECK para estados válidos
- [ ] Comentários COMMENT ON TABLE/COLUMN
- [ ] Índice em utilizador_id
- [ ] Índice em estado
- [ ] Índice em regiao
- [ ] Índice em numero_serie

#### Tabela: Leituras (PARTICIONADA)
- [x] Estrutura da tabela criada
- [x] Primary Key composta (leitura_id, data_hora)
- [x] Foreign Key para Contadores
- [x] Campo dados_audit JSONB
- [x] PARTITION BY RANGE declarado
- [x] **Partições criadas (2025-01 a 2026-12)** ✅
- [ ] Comentários COMMENT ON TABLE/COLUMN
- [ ] Índice GIN em dados_audit ⚠️
- [ ] Índice em (contador_id, data_hora)
- [ ] Índice em data_hora
- [ ] Índice específico para temperatura

#### Tabela: OfertasVenda
- [x] Estrutura da tabela criada
- [x] Primary Key definida
- [x] Foreign Key para Utilizadores
- [x] Campo regiao adicionado
- [x] Campo data_expiracao
- [x] Constraints CHECK (quantidade > 0, preco > 0)
- [x] Constraint CHECK para estados válidos
- [ ] Comentários COMMENT ON TABLE/COLUMN
- [ ] Índice composto para matching (estado, preco, data)
- [ ] Índice em vendedor_id
- [ ] Índice parcial em regiao (WHERE estado='ATIVA')
- [ ] Índice em data_criacao

#### Tabela: OrdensCompra
- [x] Estrutura da tabela criada
- [x] Primary Key definida
- [x] Foreign Key para Utilizadores
- [x] Campo regiao adicionado
- [x] Constraints CHECK (quantidade > 0, preco > 0)
- [x] Constraint CHECK para estados válidos
- [ ] Comentários COMMENT ON TABLE/COLUMN
- [ ] Índice composto para matching (estado, preco_maximo, data)
- [ ] Índice em comprador_id
- [ ] Índice parcial em regiao (WHERE estado='PENDENTE')
- [ ] Índice em data_criacao

#### Tabela: Transacoes
- [x] Estrutura da tabela criada
- [x] Primary Key definida
- [x] Foreign Keys (oferta_id, ordem_id, comprador_id, vendedor_id)
- [x] Campo tipo_transacao
- [x] Constraints CHECK (valores positivos)
- [x] Constraint CHECK (comprador != vendedor)
- [ ] Comentários COMMENT ON TABLE/COLUMN
- [ ] Índice em (comprador_id, data_transacao)
- [ ] Índice em (vendedor_id, data_transacao)
- [ ] Índice em oferta_id
- [ ] Índice em ordem_id
- [ ] Índice em data_transacao
- [ ] Índice em tipo_transacao

---

### ⚙️ 2. Lógica de Servidor (PL/pgSQL)

#### Stored Procedure: sp_ExecutarCompraDireta
- [ ] Assinatura da procedure criada
- [ ] Lógica de bloqueio (SELECT ... FOR UPDATE)
- [ ] Validação: oferta existe e está ATIVA
- [ ] Validação: quantidade disponível
- [ ] Validação: saldo do comprador
- [ ] Débito do saldo do comprador
- [ ] Crédito do saldo do vendedor
- [ ] Atualização da oferta
- [ ] Inserção em Transacoes
- [ ] Tratamento de exceções
- [ ] Mensagens de erro descritivas
- [ ] Testado via psql

#### Stored Procedure: sp_MatchingEngine
- [ ] Assinatura da procedure criada
- [ ] Loop por ordens PENDENTES
- [ ] Query de matching (preço, região, data)
- [ ] Lógica de matching ACID
- [ ] Atualização de estados
- [ ] Inserção em Transacoes
- [ ] Tratamento de exceções
- [ ] Logging com RAISE NOTICE
- [ ] Testado via psql

#### Trigger: trg_DetectarAnomalias
- [ ] Função fn_DetectarAnomalias criada
- [ ] Extração de temperatura do JSONB
- [ ] Verificação de erro_codigo
- [ ] UPDATE estado contador para 'MANUTENCAO'
- [ ] Logging de anomalias
- [ ] Trigger AFTER INSERT criado
- [ ] Testado com dados reais

#### Trigger: trg_ProtegerUtilizadores
- [ ] Função fn_ProtegerUtilizadores criada
- [ ] Verificação de saldo > 0
- [ ] Verificação de transações recentes (30 dias)
- [ ] Bloqueio de DELETE com RAISE EXCEPTION
- [ ] Mensagens de erro descritivas
- [ ] Trigger BEFORE DELETE criado
- [ ] Testado com dados reais

#### 🏆 Trigger: trg_AutoMatching (EXCELÊNCIA)
- [ ] Função fn_AutoMatching criada
- [ ] Chamada assíncrona do sp_MatchingEngine
- [ ] Trigger em OrdensCompra criado
- [ ] Trigger em OfertasVenda criado
- [ ] Testado com dados reais

---

### 🗂️ 3. Dados (Seeding)

#### Seed Mínimo (~100 registos)
- [ ] Script 02-seed-mini.sql criado
- [ ] 10 utilizadores de teste
- [ ] 10 contadores
- [ ] 50 leituras (com dados normais e anómalos)
- [ ] 20 ofertas de venda
- [ ] 10 ordens de compra
- [ ] 5 transações de exemplo

#### Seed Massivo (Checkpoint 1)
- [ ] Script 03-seed-massivo.sql criado
- [ ] 500.000+ leituras com generate_series
- [ ] 1.000+ ofertas de venda
- [ ] Distribuição realista por região
- [ ] Dados variados para matching
- [ ] Testado no servidor da escola

---

### 📊 4. Performance e Otimização

#### Criação de Índices
- [ ] Script de índices separado criado
- [ ] Todos os índices aplicados
- [ ] Índices GIN testados
- [ ] Índices parciais testados

#### Análise de Performance
- [ ] EXPLAIN ANALYZE - Anomalias JSONB (ANTES)
- [ ] EXPLAIN ANALYZE - Anomalias JSONB (DEPOIS)
- [ ] EXPLAIN ANALYZE - Query matching (ANTES)
- [ ] EXPLAIN ANALYZE - Query matching (DEPOIS)
- [ ] EXPLAIN ANALYZE - Transações por utilizador (ANTES)
- [ ] EXPLAIN ANALYZE - Transações por utilizador (DEPOIS)
- [ ] Documentação dos resultados

---

## 🌐 API SPRING BOOT (85% completo)

### 🏗️ 1. Configuração Inicial

#### Projeto e Dependências
- [x] Projeto Spring Boot criado (Gradle)
- [x] Dependências: spring-web, spring-data-jpa
- [x] Dependências: spring-security
- [x] Dependências: postgresql, jjwt, lombok
- [x] application.properties configurado (local)
- [x] Configuração JWT (secret e expiration)
- [x] Configuração JPA (ddl-auto=none, show-sql=true)
- [ ] application-prod.properties configurado
- [ ] docker-compose.yml criado

#### Estrutura de Pastas
- [x] Package config/ criado (SecurityConfig, CorsConfig, GlobalExceptionHandler)
- [x] Package controller/ criado (Auth, Meter, Market, Admin)
- [x] Package dto/ criado (7 DTOs com validações)
- [x] Package entity/ criado (6 entities completas)
- [x] Package repository/ criado (6 repositories com queries)
- [x] Package security/ criado (JWT completo)
- [x] Package service/ criado (4 services)

---

### 💾 2. Camada de Entidades (Entity)

#### Entidade: Utilizador
- [x] Classe criada e anotada (@Entity)
- [x] Mapeamento de todos os campos
- [x] Relacionamentos (@OneToMany)
- [x] Validações (@NotNull, @Email)
- [x] @PrePersist para dataCriacao
- [x] Lombok (@Getter, @Setter, @Builder)

#### Entidade: Contador
- [x] Classe criada e anotada
- [x] Mapeamento de todos os campos
- [x] Relacionamento com Utilizador (@ManyToOne)
- [x] Relacionamento com Leituras (@OneToMany)
- [x] @PrePersist para dataInstalacao

#### Entidade: Leitura
- [x] Classe criada e anotada
- [x] Mapeamento de leitura_id AUTO INCREMENT
- [x] Mapeamento JSONB correto (@JdbcTypeCode SqlTypes.JSON)
- [x] Relacionamento com Contador (@ManyToOne)
- [x] Campo dataHora para particionamento
- [x] Map<String, Object> para dadosAudit

#### Entidade: OfertaVenda
- [x] Classe criada e anotada
- [x] Mapeamento de todos os campos
- [x] Relacionamento com Utilizador (vendedor)
- [x] @PrePersist para dataCriacao
- [x] Estado como String (validado na BD)

#### Entidade: OrdemCompra
- [x] Classe criada e anotada
- [x] Mapeamento de todos os campos
- [x] Relacionamento com Utilizador (comprador)
- [x] @PrePersist para dataCriacao
- [x] Estado como String (validado na BD)

#### Entidade: Transacao
- [x] Classe criada e anotada
- [x] Mapeamento de todos os campos
- [x] Relacionamentos (oferta, ordem, comprador, vendedor)
- [x] @PrePersist para dataTransacao
- [x] TipoTransacao como String

---

### 📦 3. Camada de Repositórios (Repository)

- [x] UtilizadorRepository criado (extends JpaRepository)
- [x] Método findByEmail
- [x] Método existsByEmail
- [x] ContadorRepository criado
- [x] Métodos findByUtilizadorUtilizadorId, findByNumeroSerie, findByEstado
- [x] LeituraRepository criado
- [x] Query JSONB nativa para anomalias (temperatura > 80 OU erro_codigo)
- [x] Query findByContadorAndPeriodo para aproveitar partições
- [x] OfertaVendaRepository criado
- [x] Queries para ofertas ativas com filtros (estado, região, preço)
- [x] OrdemCompraRepository criado
- [x] Query para ordens pendentes ordenadas por data
- [x] TransacaoRepository criado
- [x] Queries por comprador/vendedor ordenadas por data DESC

---

### ⚙️ 4. Camada de Serviços (Service)

#### AuthService
- [x] Classe criada e anotada (@Service)
- [x] Método register (com BCrypt strength 12)
- [x] Método login (com geração de JWT)
- [x] Validação duplicação email (existsByEmail)
- [x] Validação de credenciais (BCrypt.matches)
- [x] Atualização ultimo_acesso no login
- [x] Tratamento de exceções com mensagens amigáveis

#### MeterService
- [x] Classe criada e anotada
- [x] Método registarLeitura (com validação contador pertence ao user)
- [x] Método listarLeiturasPorPeriodo (aproveita partições)
- [x] Método listarContadoresDoUtilizador
- [x] Validação de permissões (contador pertence ao utilizador)
- [x] @Transactional configurado

#### MarketService
- [x] Classe criada e anotada
- [x] Método listarOfertasAtivas (com filtro opcional por região)
- [x] Método criarOferta
- [x] Método criarOrdemCompra
- [x] Método executarCompraDireta (chama sp_ExecutarCompraDireta via SimpleJdbcCall)
- [x] Método executarMatching (chama sp_MatchingEngine via SimpleJdbcCall)
- [x] @PostConstruct para inicializar SimpleJdbcCall
- [x] Uso correto de @Transactional
- [x] Tratamento de exceções da BD (PSQLException)

#### AdminService
- [x] Classe criada e anotada
- [x] Método listarAnomalias (query JSONB com índice GIN)
- [x] Método listarContadoresEmManutencao
- [x] Método listarTransacoes (histórico completo)
- [x] @Transactional(readOnly = true) para queries

---

### 🎮 5. Camada de Controllers (Controller)

#### AuthController
- [x] Classe criada e anotada (@RestController)
- [x] POST /api/auth/register
- [x] POST /api/auth/login
- [x] Validação de DTOs com @Valid
- [x] Status HTTP corretos (201 Created, 200 OK)
- [x] Endpoints públicos (sem JWT)

#### MeterController
- [x] Classe criada e anotada
- [x] POST /api/meters/{contadorId}/readings
- [x] GET /api/meters/{id}/readings?inicio=...&fim=...
- [x] GET /api/meters (listar contadores do user)
- [x] Proteção com JWT (@AuthenticationPrincipal)
- [x] Validação de DTOs
- [x] Parâmetros de query com @DateTimeFormat

#### MarketController
- [x] Classe criada e anotada
- [x] GET /api/market/offers (com filtro opcional regiao)
- [x] POST /api/market/offers (criar oferta)
- [x] POST /api/market/offers/{ofertaId}/buy (compra direta)
- [x] POST /api/market/order (criar ordem)
- [x] POST /api/market/match (disparar matching manual) ⚠️ OBRIGATÓRIO
- [x] Proteção com JWT
- [x] Validação de DTOs
- [x] Logging com SLF4J

#### AdminController
- [x] Classe criada e anotada
- [x] GET /api/admin/anomalies (query JSONB)
- [x] GET /api/admin/transactions (histórico completo)
- [x] Proteção com JWT
- [x] Documentação Javadoc nos endpoints

---

### 🔐 6. Segurança (Security)

#### JwtTokenProvider
- [x] Classe criada
- [x] Método generateToken (email como subject)
- [x] Método validateToken (detecta expiração e tokens inválidos)
- [x] Método getEmailFromToken (extrai subject)
- [x] Chave secreta via @Value (jwt.secret)
- [x] Tempo de expiração configurável (jwt.expiration)
- [x] Algoritmo HS256 com Keys.hmacShaKeyFor

#### JwtAuthenticationFilter
- [x] Classe criada (extends OncePerRequestFilter)
- [x] Extração de token do header Authorization
- [x] Validação do token antes de processar
- [x] Carregamento de UserDetails via UserDetailsService
- [x] Configuração do SecurityContext
- [x] Tratamento de tokens inválidos/expirados
- [x] Logging de autenticações

#### UserDetailsServiceImpl
- [x] Classe criada (implements UserDetailsService)
- [x] Método loadUserByUsername (busca por email)
- [x] Conversão Utilizador → UserDetails
- [x] Tratamento de usuário não encontrado (UsernameNotFoundException)

#### SecurityConfig
- [x] Classe criada (@Configuration, @EnableWebSecurity)
- [x] BCryptPasswordEncoder com strength 12 ⚠️ OBRIGATÓRIO
- [x] SecurityFilterChain configurado
- [x] Endpoints públicos definidos (/api/auth/**)
- [x] Endpoints protegidos (anyRequest().authenticated())
- [x] Filtro JWT registrado (addFilterBefore)
- [x] CSRF desabilitado (API REST stateless)
- [x] Session management STATELESS

#### CorsConfig
- [x] Classe criada (@Configuration)
- [x] CorsFilter configurado
- [x] AllowedOrigins configurado (atualmente "*" para dev)
- [x] AllowedMethods (GET, POST, PUT, DELETE, OPTIONS)
- [x] AllowedHeaders completamente abertas para dev

---

### 📝 7. DTOs (Data Transfer Objects)

- [x] RegisterRequest (nome, email, password) com @NotBlank, @Email, @Size
- [x] LoginRequest (email, password) com @NotBlank, @Email
- [x] AuthResponse (token, email, nome)
- [x] ReadingRequest (kwhLeitura, dadosAudit) com @NotNull, @Positive
- [x] BuyRequest (quantidade) com @NotNull, @Positive
- [x] OfferRequest (quantidadeKwh, precoUnitario, regiao) com validações
- [x] OrderRequest (quantidadeKwh, precoMaximo, regiao) com validações
- [x] Todas as validações com @Valid, @NotNull, @Email, @Positive, @Size

---

### ⚠️ 8. Tratamento de Exceções

- [x] GlobalExceptionHandler criado (@RestControllerAdvice)
- [x] Tratamento de MethodArgumentNotValidException (validação @Valid)
- [x] Tratamento de RuntimeException (erros de negócio e stored procedures)
- [x] Tratamento de Exception genérica (evita expor detalhes internos)
- [x] Mensagens de erro padronizadas (JSON com timestamp, status, erro)
- [x] Log de exceções com SLF4J
- [ ] Tratamento específico de PSQLException (não parece necessário - RuntimeException captura)
- [ ] Tratamento de AccessDeniedException (não implementado - sem roles)

---

### ✅ 9. Testes

#### Testes Locais
- [ ] Conexão à BD validada (SELECT 1)
- [ ] Endpoint de health criado
- [ ] Registo de utilizador testado
- [ ] Login testado
- [ ] Token JWT validado
- [ ] Inserção de leitura testada
- [ ] Compra direta testada
- [ ] Matching testado

#### Testes de Segurança
- [ ] SQL Injection tentado (deve falhar)
- [ ] Acesso sem token (401)
- [ ] Token expirado (401)
- [ ] Token inválido (401)
- [ ] BCrypt >= 12 confirmado

---

## 🚀 DEPLOY E INFRAESTRUTURA

### Docker (Desenvolvimento Local)
- [ ] docker-compose.yml criado
- [ ] Serviço PostgreSQL configurado
- [ ] Volumes para persistência
- [ ] Adminer/pgAdmin configurado
- [ ] Testado localmente

### Servidor da Escola
- [ ] Credenciais solicitadas
- [ ] Acesso validado
- [ ] DDL executado no servidor
- [ ] Seed inicial carregado

### Deploy Cloud (API)
- [ ] Plataforma escolhida (Railway/Render/Vercel)
- [ ] Variáveis de ambiente configuradas
- [ ] Conexão com servidor da escola testada
- [ ] API online e acessível
- [ ] Endpoints testados em produção

---

## 📚 DOCUMENTAÇÃO

### Scripts SQL
- [x] 01-schema.sql (tabelas) ✅
- [x] 02-partitions.sql (partições Leituras) ✅
- [ ] 03-indexes.sql (índices)
- [ ] 04-procedures.sql (stored procedures)
- [ ] 05-triggers.sql (triggers)
- [ ] 06-seed-mini.sql (dados teste)
- [ ] 07-seed-massivo.sql (checkpoint 1)
- [ ] 08-tests.sql (testes procedures/triggers)

### Documentação API
- [ ] README.md do projeto
- [ ] Postman Collection criada
- [ ] Exemplos de requests/responses
- [ ] Instruções de setup local
- [ ] Instruções de deploy

### Relatório Técnico (PDF)
- [ ] Diagrama ER desenhado
- [ ] Descrição das tabelas
- [ ] Justificação de índices
- [ ] Resultados EXPLAIN ANALYZE
- [ ] Descrição do particionamento
- [ ] Descrição das procedures
- [ ] Descrição dos triggers
- [ ] Plano de execução matching engine
- [ ] Testes de segurança documentados
- [ ] Screenshots da aplicação

---

## 🎯 CHECKPOINTS

### Checkpoint 1 (8 Abril 2026)
- [ ] DDL executado no servidor da escola
- [ ] 500.000+ leituras carregadas
- [ ] 1.000+ ofertas carregadas
- [ ] Stored procedures funcionais
- [ ] API com autenticação funcional
- [ ] Demonstração preparada

### Checkpoint 2 (13 Maio 2026)
- [ ] API deployed em cloud
- [ ] Todos os endpoints funcionais
- [ ] Testes de segurança realizados
- [ ] Relatório técnico completo
- [ ] Postman collection entregue
- [ ] Defesa preparada

---

## 📦 ENTREGA FINAL

### Organização do ZIP
- [ ] Pasta api/ (código Spring Boot limpo)
- [ ] Pasta sql/ (todos os scripts organizados)
- [ ] Pasta relatorio/ (PDF + diagrama ER)
- [ ] README.md na raiz
- [ ] .gitignore configurado
- [ ] Sem node_modules, .class, target/

### Defesa
- [ ] Ambos os elementos conseguem explicar BD
- [ ] Ambos os elementos conseguem explicar API
- [ ] Demo ao vivo preparada
- [ ] Respostas a perguntas técnicas preparadas

---

## 🎖️ CRITÉRIOS DE EXCELÊNCIA

- [ ] Trigger de Auto-Matching implementado
- [ ] EXPLAIN ANALYZE documentado detalhadamente
- [ ] Diagrama ER profissional (Draw.io/Lucidchart)
- [ ] Testes de SQL Injection documentados com prints
- [ ] Código comentado e organizado
- [ ] Views criadas para queries comuns
- [ ] Logs estruturados na API
- [ ] Tratamento de edge cases
- [ ] Performance documentada

---

**📊 Próximas Prioridades:**

1. 🔴 **URGENTE P2**: Criar índices de performance (`03-indexes.sql`) - 3h
2. 🔴 **URGENTE P2**: Criar sp_ExecutarCompraDireta (`04-procedures.sql` parte 1) - 3h - BLOQUEADOR CP1
3. 🔴 **URGENTE P1**: Criar sp_MatchingEngine (`04-procedures.sql` parte 2) - 3h - BLOQUEADOR CP1
4. 🔴 **URGENTE P1**: Criar triggers (`05-triggers.sql`) - 3h - BLOQUEADOR CP1
5. 🟠 **IMPORTANTE P1**: Criar seed inicial (`06-seed-mini.sql`) - 2h
6. 🟠 **IMPORTANTE P1**: Docker Compose (Semana 2) - 2h
7. 🟡 **MÉDIO P1**: Testes locais e Postman Collection (Semana 2) - 6h
8. 🟢 **BAIXO P2**: Seed massivo (Semana 3) - 5h

---

## 🎯 RESUMO DO QUE FALTA

### ✅ **API Spring Boot - 85% COMPLETA**
- ✅ Todas as 6 Entities implementadas
- ✅ Todos os 6 Repositories com queries customizadas
- ✅ Todos os 4 Services (Auth, Meter, Market, Admin)
- ✅ Todos os 4 Controllers com endpoints completos
- ✅ Segurança completa (JWT + BCrypt 12)
- ✅ GlobalExceptionHandler funcional
- ✅ 7 DTOs com validações
- ❌ Falta (P1): sp_MatchingEngine, triggers, seed-mini, docker-compose, testes

### ⚠️ **Base de Dados - 35% COMPLETA**
- ✅ Schema completo (6 tabelas com constraints)
- ✅ Partições criadas (24 partições mensais)
- ❌ **CRÍTICO (P2)**: Falta sp_ExecutarCompraDireta (ACID)
- ❌ **CRÍTICO (P1)**: Falta sp_MatchingEngine (ACID)
- ❌ **CRÍTICO (P1)**: Falta trg_DetectarAnomalias
- ❌ Falta trg_ProtegerUtilizadores
- ❌ Falta índices (GIN, B-tree, parciais)
- ❌ Falta seeding massivo (500k+ leituras)

---

## 👥 Divisão de Trabalho

### Pessoa 1 - API Spring Boot + Triggers/Seed
- ✅ Entities, Repositories, Services (COMPLETO)
- ✅ Controllers e DTOs (COMPLETO)
- ✅ Segurança (JWT + BCrypt) (COMPLETO)
- Stored Procedure: sp_MatchingEngine (Semana 1)
- Triggers: trg_DetectarAnomalias + trg_ProtegerUtilizadores (Semana 1)
- Seed inicial (06-seed-mini.sql) (Semana 1)
- Docker Compose + Testes (Semana 2)
- Postman Collection (Semana 2)
- application-prod.properties (Semana 3)
- Deploy em cloud (Semana 4)

### Pessoa 2 - Base de Dados PostgreSQL
- ✅ Schema das tabelas (COMPLETO)
- ✅ Partições (COMPLETO)
- Índices de performance (03-indexes.sql) (Semana 1)
- Stored Procedure: sp_ExecutarCompraDireta (Semana 1)
- Seeding massivo (07-seed-massivo.sql) (Semana 3)
- Validações e otimizações EXPLAIN ANALYZE (Semana 3)
