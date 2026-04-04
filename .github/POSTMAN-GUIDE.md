# 🧪 VoltExchange — Guia de Testes Postman

**Base URL:** `http://localhost:3000`  
**Pré-requisito:** `docker compose up --build` a correr (DB + API)

---

## 📋 Ordem de Execução Recomendada

Segue **esta ordem** — cada passo depende do anterior:

1. Health Check
2. Registar utilizador
3. Login → guardar token
4. Listar contadores (seed já criou)
5. Submeter leitura normal
6. Submeter leitura com anomalia
7. Ver anomalias (admin)
8. Criar oferta de venda
9. Listar ofertas
10. Criar ordem de compra
11. Executar matching engine
12. Compra direta
13. Ver transações (admin)
14. Testes de segurança

---

## ⚙️ Configuração Inicial no Postman

### Criar Environment "VoltExchange Local"

| Variable        | Initial Value              |
|-----------------|---------------------------|
| `base_url`      | `http://localhost:3000`   |
| `token`         | *(vazio — preenchido no login)* |
| `contador_id`   | `1`                       |
| `oferta_id`     | *(preenchido depois)*     |

### Header Authorization (para rotas protegidas)

Em cada request protegido, adiciona no tab **Authorization**:
- Type: `Bearer Token`
- Token: `{{token}}`

---

## 1️⃣ Health Check

**Verifica que a API está viva.**

| Campo   | Valor                  |
|---------|------------------------|
| Method  | `GET`                  |
| URL     | `{{base_url}}/api/health` |
| Auth    | Nenhuma                |

**✅ Resultado esperado — 200 OK:**
```json
{
    "status": "ok",
    "service": "VoltExchange API"
}
```

---

## 2️⃣ Registar Utilizador

| Campo   | Valor                       |
|---------|-----------------------------|
| Method  | `POST`                      |
| URL     | `{{base_url}}/api/auth/register` |
| Body    | `raw → JSON`                |

**Body:**
```json
{
    "nome": "João Teste",
    "email": "joao@teste.com",
    "password": "password123"
}
```

**✅ Resultado esperado — 201 Created:**
```json
{
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tipo": "Bearer",
    "email": "joao@teste.com",
    "nome": "João Teste"
}
```

> 💡 **Dica:** Podes guardar o token automaticamente com um **Tests** script:
> ```javascript
> const json = pm.response.json();
> pm.environment.set("token", json.token);
> ```

**❌ Resultado se email já existe — 400 Bad Request:**
```json
{
    "timestamp": "2026-04-04T...",
    "status": 400,
    "erro": "Email já registado"
}
```

---

## 3️⃣ Login

| Campo   | Valor                       |
|---------|-----------------------------|
| Method  | `POST`                      |
| URL     | `{{base_url}}/api/auth/login` |
| Body    | `raw → JSON`                |

**Body:**
```json
{
    "email": "joao@teste.com",
    "password": "password123"
}
```

**✅ Resultado esperado — 200 OK:**
```json
{
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tipo": "Bearer",
    "email": "joao@teste.com",
    "nome": "João Teste"
}
```

**Script no tab Tests** (guarda token automaticamente):
```javascript
const json = pm.response.json();
pm.environment.set("token", json.token);
console.log("Token guardado:", json.token.substring(0, 30) + "...");
```

**❌ Credenciais erradas — 401 Unauthorized:**
```json
{
    "timestamp": "2026-04-04T...",
    "status": 401,
    "erro": "Credenciais inválidas"
}
```

---

## 4️⃣ Listar Os Meus Contadores

| Campo   | Valor                       |
|---------|-----------------------------|
| Method  | `GET`                       |
| URL     | `{{base_url}}/api/meters`   |
| Auth    | Bearer `{{token}}`          |

**✅ Resultado esperado — 200 OK:**
```json
[
    {
        "contador_id": 1,
        "utilizador_id": 1,
        "numero_serie": "CNT-000001",
        "estado": "ATIVO",
        "regiao": "Norte",
        "data_instalacao": "2025-01-15T..."
    }
]
```

> ⚠️ Se o array vier **vazio** `[]`, é porque o utilizador recém-criado não tem contadores. Usa um utilizador do seed (IDs 1–10) que já tem contadores associados.  
> Regista-te com `user1@voltexchange.com` / `password123` e faz login novamente.

**Script Tests** para guardar o primeiro contador_id:
```javascript
const json = pm.response.json();
if (json.length > 0) {
    pm.environment.set("contador_id", json[0].contador_id);
}
```

**❌ Sem token — 401 Unauthorized:**
```json
{
    "timestamp": "2026-04-04T...",
    "status": 401,
    "erro": "Token não fornecido"
}
```

---

## 5️⃣ Submeter Leitura Normal

| Campo   | Valor                                               |
|---------|-----------------------------------------------------|
| Method  | `POST`                                              |
| URL     | `{{base_url}}/api/meters/{{contador_id}}/readings`  |
| Auth    | Bearer `{{token}}`                                  |
| Body    | `raw → JSON`                                        |

**Body (leitura normal — sem anomalia):**
```json
{
    "kwhLeitura": 45.7,
    "dadosAudit": {
        "temperatura": 35,
        "voltagem": 230,
        "frequencia": 50
    }
}
```

**✅ Resultado esperado — 201 Created:**
```json
{
    "mensagem": "Leitura registada com sucesso",
    "leituraId": 500051,
    "dataHora": "2026-04-04T14:32:10.123Z",
    "contadorId": 1
}
```

> O trigger `trg_DetectarAnomalias` **não dispara** (temperatura = 35 ≤ 80, sem `erro_codigo`).

---

## 6️⃣ Submeter Leitura com Anomalia

**Esta leitura deve activar o trigger e colocar o contador em MANUTENÇÃO.**

| Campo   | Valor                                               |
|---------|-----------------------------------------------------|
| Method  | `POST`                                              |
| URL     | `{{base_url}}/api/meters/{{contador_id}}/readings`  |
| Auth    | Bearer `{{token}}`                                  |
| Body    | `raw → JSON`                                        |

**Body (temperatura > 80 → anomalia):**
```json
{
    "kwhLeitura": 52.3,
    "dadosAudit": {
        "temperatura": 95,
        "voltagem": 228
    }
}
```

**✅ Resultado esperado — 201 Created:**
```json
{
    "mensagem": "Leitura registada com sucesso",
    "leituraId": 500052,
    "dataHora": "2026-04-04T14:33:05.456Z",
    "contadorId": 1
}
```

> ⚠️ **O trigger disparou em background!** Para confirmar, vai ao passo 7 e verifica que o contador aparece em `MANUTENCAO`.

**Alternativa — anomalia por `erro_codigo`:**
```json
{
    "kwhLeitura": 0.0,
    "dadosAudit": {
        "temperatura": 40,
        "erro_codigo": "ERR_SENSOR_FALHA",
        "mensagem": "Falha no sensor de corrente"
    }
}
```

---

## 7️⃣ Ver Anomalias (Admin)

| Campo   | Valor                             |
|---------|-----------------------------------|
| Method  | `GET`                             |
| URL     | `{{base_url}}/api/admin/anomalies` |
| Auth    | Bearer `{{token}}`                |

**✅ Resultado esperado — 200 OK:**
```json
{
    "totalAnomalias": 10,
    "contadoresEmManutencao": 1,
    "leituras": [
        {
            "leitura_id": 500052,
            "contador_id": 1,
            "data_hora": "2026-04-04T14:33:05.456Z",
            "dados_audit": {
                "temperatura": 95,
                "voltagem": 228
            }
        }
    ],
    "contadores": [
        {
            "contador_id": 1,
            "numero_serie": "CNT-000001",
            "regiao": "Norte",
            "estado": "MANUTENCAO"
        }
    ]
}
```

> O campo `contadoresEmManutencao` deve ser **≥ 1** após o passo 6.  
> O `totalAnomalias` viria do seed (leituras com temperatura > 80 criadas no `07-seed-massivo.sql`).

---

## 8️⃣ Criar Oferta de Venda

**Pré-requisito:** Estar autenticado como um utilizador com saldo (usa utilizador do seed).

| Campo   | Valor                       |
|---------|-----------------------------|
| Method  | `POST`                      |
| URL     | `{{base_url}}/api/market/offers` |
| Auth    | Bearer `{{token}}`          |
| Body    | `raw → JSON`                |

**Body:**
```json
{
    "quantidadeKwh": 100.0,
    "precoUnitario": 0.12,
    "regiao": "Norte"
}
```

**✅ Resultado esperado — 201 Created:**
```json
{
    "oferta_id": 1021,
    "vendedor_id": 1,
    "quantidade_kwh": "100.000",
    "preco_unitario": "0.1200",
    "estado": "ATIVA",
    "regiao": "Norte",
    "data_criacao": "2026-04-04T14:35:00.789Z"
}
```

**Script Tests** para guardar o oferta_id:
```javascript
const json = pm.response.json();
pm.environment.set("oferta_id", json.oferta_id);
```

---

## 9️⃣ Listar Ofertas Activas

| Campo   | Valor                              |
|---------|------------------------------------|
| Method  | `GET`                              |
| URL     | `{{base_url}}/api/market/offers`   |
| Auth    | Bearer `{{token}}`                 |
| Query   | `regiao=Norte` *(opcional)*        |

**URL com filtro de região:**
```
{{base_url}}/api/market/offers?regiao=Norte
```

**✅ Resultado esperado — 200 OK:**
```json
[
    {
        "oferta_id": 1,
        "vendedor_id": 2,
        "quantidade_kwh": "150.000",
        "preco_unitario": "0.0800",
        "estado": "ATIVA",
        "regiao": "Norte",
        "data_criacao": "2025-06-15T..."
    },
    {
        "oferta_id": 1021,
        "vendedor_id": 1,
        "quantidade_kwh": "100.000",
        "preco_unitario": "0.1200",
        "estado": "ATIVA",
        "regiao": "Norte",
        "data_criacao": "2026-04-04T..."
    }
]
```

> Array ordenado por `preco_unitario ASC` — oferta mais barata primeiro.

---

## 🔟 Criar Ordem de Compra

| Campo   | Valor                       |
|---------|-----------------------------|
| Method  | `POST`                      |
| URL     | `{{base_url}}/api/market/order` |
| Auth    | Bearer `{{token}}`          |
| Body    | `raw → JSON`                |

**Body:**
```json
{
    "quantidadeKwh": 50.0,
    "precoMaximo": 0.15,
    "regiao": "Norte"
}
```

**✅ Resultado esperado — 201 Created:**
```json
{
    "ordem_id": 511,
    "comprador_id": 1,
    "quantidade_kwh": "50.000",
    "preco_maximo": "0.1500",
    "estado": "PENDENTE",
    "regiao": "Norte",
    "data_criacao": "2026-04-04T14:36:00.000Z"
}
```

> O trigger `trg_AutoMatching_Ordens` dispara automaticamente ao inserir esta ordem e tenta fazer match com ofertas existentes.

---

## 1️⃣1️⃣ Executar Matching Engine (Manual)

**Obrigatório para avaliação** — mesmo com trigger automático, este endpoint deve funcionar.

| Campo   | Valor                        |
|---------|------------------------------|
| Method  | `POST`                       |
| URL     | `{{base_url}}/api/market/match` |
| Auth    | Bearer `{{token}}`           |
| Body    | Nenhum (vazio)               |

**✅ Resultado esperado — 200 OK:**
```json
{
    "mensagem": "Matching engine executado com sucesso"
}
```

> O `sp_MatchingEngine` varreu todas as ordens `PENDENTE` e tentou fazer match com ofertas `ATIVA`.  
> Verifica depois no passo 13 se novas transações foram criadas.

---

## 1️⃣2️⃣ Compra Direta (sp_ExecutarCompraDireta)

**Compra imediata de uma oferta específica.**

| Campo   | Valor                                              |
|---------|----------------------------------------------------|
| Method  | `POST`                                             |
| URL     | `{{base_url}}/api/market/offers/{{oferta_id}}/buy` |
| Auth    | Bearer `{{token}}`                                 |
| Body    | `raw → JSON`                                       |

**Body:**
```json
{
    "quantidade": 10.0
}
```

**✅ Resultado esperado — 200 OK:**
```json
{
    "mensagem": "Compra realizada com sucesso",
    "ofertaId": 1021,
    "quantidade": 10
}
```

**❌ Saldo insuficiente — 400 Bad Request:**
```json
{
    "timestamp": "2026-04-04T...",
    "status": 400,
    "erro": "Saldo insuficiente"
}
```

**❌ Oferta não disponível — 400 Bad Request:**
```json
{
    "timestamp": "2026-04-04T...",
    "status": 400,
    "erro": "Oferta não disponível ou já vendida"
}
```

> A SP garante **ACID**: bloqueia a linha (`SELECT FOR UPDATE`), verifica estado, debita saldo, credita vendedor, regista transação — tudo numa transação atómica.

---

## 1️⃣3️⃣ Ver Historial de Transações (Admin)

| Campo   | Valor                               |
|---------|-------------------------------------|
| Method  | `GET`                               |
| URL     | `{{base_url}}/api/admin/transactions` |
| Auth    | Bearer `{{token}}`                  |

**✅ Resultado esperado — 200 OK:**
```json
{
    "total": 512,
    "transacoes": [
        {
            "transacao_id": 512,
            "tipo_transacao": "DIRETA",
            "comprador_id": 1,
            "vendedor_id": 3,
            "quantidade_kwh": "10.000",
            "preco_unitario": "0.1200",
            "valor_total": "1.2000",
            "data_transacao": "2026-04-04T14:38:00.000Z"
        },
        {
            "transacao_id": 511,
            "tipo_transacao": "MATCHING",
            "comprador_id": 2,
            "vendedor_id": 5,
            "quantidade_kwh": "50.000",
            "preco_unitario": "0.0900",
            "valor_total": "4.5000",
            "data_transacao": "2026-04-04T14:37:00.000Z"
        }
    ]
}
```

---

## 🔐 Testes de Segurança (Obrigatórios para CP2)

### Teste A — SQL Injection deve falhar

**Login com payload de SQL Injection:**

| Campo   | Valor                       |
|---------|-----------------------------|
| Method  | `POST`                      |
| URL     | `{{base_url}}/api/auth/login` |
| Body    | `raw → JSON`                |

**Body:**
```json
{
    "email": "' OR '1'='1",
    "password": "qualquercoisa"
}
```

**✅ Resultado esperado (correto) — 401 Unauthorized:**
```json
{
    "timestamp": "2026-04-04T...",
    "status": 401,
    "erro": "Credenciais inválidas"
}
```

> ✅ **SQL Injection bloqueado** — a query usa `$1` (prepared statement), nunca concatenação de strings.

---

### Teste B — Sem Token deve falhar

| Campo   | Valor                       |
|---------|-----------------------------|
| Method  | `GET`                       |
| URL     | `{{base_url}}/api/meters`   |
| Auth    | Nenhuma (sem Bearer)        |

**✅ Resultado esperado — 401 Unauthorized:**
```json
{
    "timestamp": "2026-04-04T...",
    "status": 401,
    "erro": "Token não fornecido"
}
```

---

### Teste C — Token expirado / inválido

| Campo       | Valor                          |
|-------------|--------------------------------|
| Method      | `GET`                          |
| URL         | `{{base_url}}/api/meters`      |
| Auth Header | `Bearer tokeninvalidoqqqqq`    |

**✅ Resultado esperado — 401 Unauthorized:**
```json
{
    "timestamp": "2026-04-04T...",
    "status": 401,
    "erro": "Token inválido ou expirado"
}
```

---

### Teste D — Aceder contador de outro utilizador

Tenta submeter leitura para um `contador_id` que não pertence ao teu utilizador (ex: `/api/meters/999/readings` com um utilizador que só tem o contador 1):

**✅ Resultado esperado — 403 Forbidden:**
```json
{
    "timestamp": "2026-04-04T...",
    "status": 403,
    "erro": "Contador não pertence a este utilizador"
}
```

---

### Teste E — Rota inexistente (404)

| Campo   | Valor                            |
|---------|----------------------------------|
| Method  | `GET`                            |
| URL     | `{{base_url}}/api/naoexiste`     |

**✅ Resultado esperado — 404 Not Found:**
```json
{
    "timestamp": "2026-04-04T...",
    "status": 404,
    "erro": "Rota não encontrada"
}
```

---

## 📊 Tabela Resumo de Todos os Endpoints

| # | Method | Endpoint                                | Auth | Descrição                              |
|---|--------|-----------------------------------------|------|----------------------------------------|
| 1 | GET    | `/api/health`                           | ❌   | Health check                           |
| 2 | POST   | `/api/auth/register`                    | ❌   | Registar novo utilizador               |
| 3 | POST   | `/api/auth/login`                       | ❌   | Login → retorna JWT                    |
| 4 | GET    | `/api/meters`                           | ✅   | Listar contadores do utilizador        |
| 5 | POST   | `/api/meters/:id/readings`              | ✅   | Submeter leitura (activa trigger)      |
| 6 | GET    | `/api/meters/:id/readings?inicio=&fim=` | ✅   | Histórico de leituras por período      |
| 7 | GET    | `/api/admin/anomalies`                  | ✅   | Listar anomalias (query GIN JSONB)     |
| 8 | GET    | `/api/admin/transactions`               | ✅   | Histórico completo de transações       |
| 9 | GET    | `/api/market/offers`                    | ✅   | Listar ofertas activas (filtro região) |
| 10| POST   | `/api/market/offers`                    | ✅   | Criar nova oferta de venda             |
| 11| POST   | `/api/market/offers/:id/buy`            | ✅   | Compra directa (ACID via SP)           |
| 12| POST   | `/api/market/order`                     | ✅   | Criar ordem de compra pendente         |
| 13| POST   | `/api/market/match`                     | ✅   | Disparar matching engine manualmente   |

---

## 🔍 Verificar Leituras por Período

| Campo   | Valor                                                                |
|---------|----------------------------------------------------------------------|
| Method  | `GET`                                                                |
| URL     | `{{base_url}}/api/meters/{{contador_id}}/readings`                   |
| Auth    | Bearer `{{token}}`                                                   |
| Params  | `inicio=2025-01-01T00:00:00Z` e `fim=2025-03-31T23:59:59Z`          |

**URL completa:**
```
{{base_url}}/api/meters/1/readings?inicio=2025-01-01T00:00:00Z&fim=2025-03-31T23:59:59Z
```

**✅ Resultado esperado — 200 OK:**
```json
[
    {
        "leitura_id": 1234,
        "contador_id": 1,
        "data_hora": "2025-03-20T12:04:52.000Z",
        "kwh_leitura": "42.500",
        "dados_audit": {
            "temperatura": 38,
            "voltagem": 231
        }
    }
]
```

> ✅ Esta query explora o **particionamento** da tabela `Leituras` — o PostgreSQL só lê as partições de Jan/Fev/Mar 2025, ignorando as restantes 21 partições.

---

## 💡 Dicas Rápidas

- **Utilizadores do seed:** `user1@voltexchange.com` até `user10@voltexchange.com`, password `password123`
- **Saldo dos utilizadores seed:** aleatório entre 0–10000€ — se a compra falhar por saldo, usa outro utilizador
- **Contadores seed:** `contador_id` 1–10 estão associados aos `user1`–`user10`
- **Leituras seed:** 500 050 leituras de Jan 2025 a Dez 2026 já existem na DB
- **Ofertas seed:** 1 020 ofertas, maioria em estado `ATIVA`
- **Ordens seed:** 510 ordens, algumas `CONCLUIDA` (processadas pelo seed), outras `PENDENTE`
