# ⚡ VoltExchange

A peer-to-peer energy trading marketplace, built as the practical project for a Database Systems II course. The interesting part isn't the CRUD — it's the PostgreSQL schema underneath: **range partitioning**, **targeted indexing**, **stored procedures with row-level locking**, and **triggers that drive an automatic order-matching engine**.

## Overview

VoltExchange lets **prosumers** (households with solar panels) sell surplus energy and **consumers** buy directly from their neighbors, with an automatic matching engine pairing buy orders against sell offers by price and region.

- **Database**: PostgreSQL 16+
- **API**: Node.js + Express, JWT auth, `pg` (no ORM — raw SQL, `CALL`/`SELECT` into stored procedures)
- **Frontend**: Vue 3 + Vite + Tailwind CSS (dark dashboard, EN/PT via vue-i18n), served by nginx

## Frontend

The Vue dashboard doesn't hide the database layer — it showcases it:

- **Dashboard** — balance (with a clearly-labelled demo deposit), meters, and a consumption chart fed by partition-pruned range queries, with a badge showing exactly which `Leituras_YYYY_MM` partitions the query touched
- **Market** — browse/filter active offers by region, buy directly (`sp_ExecutarCompraDireta`), publish offers and buy orders — and watch the statement-level triggers auto-match them instantly
- **My Activity** — own offers/orders/transactions with cancel actions
- **Meters** — submit readings with optional JSONB diagnostics; a temperature above 80°C or an error code fires `trg_DetectarAnomalias` live and flips the meter to maintenance
- **DB Internals** — a deliberate showcase panel: anomaly feed, global transaction log, a button that runs `sp_MatchingEngine()` and reports how many new transactions it settled, and user quarantine via `sp_QuarentenaUtilizador` — each card annotated with the actual SQL behind it

## Database design

Six tables: `Utilizadores` (users), `Contadores` (smart meters), `Leituras` (meter readings), `OfertasVenda` (sell offers), `OrdensCompra` (buy orders), `Transacoes` (settled trades).

### Partitioning

`Leituras` (meter readings) is declared `PARTITION BY RANGE (data_hora)` and split into 24 monthly partitions spanning 2025–2026. This is the table that receives high-volume time-series writes (smart-meter telemetry) and is queried almost exclusively by date range, so range partitioning lets Postgres prune irrelevant partitions at query time instead of scanning half a million rows.

### Indexing

24 indexes, chosen to match actual query patterns rather than applied blanket-style:
- **Partial indexes** on hot subsets only — e.g. `idx_ofertas_ativas_preco` indexes sell offers `WHERE estado = 'ATIVA'`, so the matching engine's price-ordered scan never touches sold/cancelled offers.
- **GIN index** on `Leituras.dados_audit` (JSONB) for querying meter diagnostic payloads (temperature, error codes) without a fixed schema.
- **Expression index** on `(dados_audit->>'temperatura')::numeric` so anomaly queries on the JSONB payload can use an index instead of a full scan.
- **Composite indexes** aligned with the matching engine's access path — offers by `(regiao, preco_unitario, data_criacao)`, pending orders by the same shape — so the FIFO/best-price matching logic in `sp_MatchingEngine` hits an index instead of sorting on every run.

### Stored procedures

- **`sp_ExecutarCompraDireta`** — direct purchase of a specific offer. Locks the offer and buyer rows with `FOR UPDATE`, validates funds/quantity/state, then updates balances, offer state, and inserts the transaction — all inside one procedure so a failure anywhere rolls the whole trade back.
- **`sp_MatchingEngine`** — the core matching logic. Walks pending buy orders oldest-first, and for each one scans compatible active offers (price ≤ max, same region or unrestricted, different user) ordered by best price, settling partial fills across multiple offers until the order is filled or no compatible offer remains.
- **`sp_QuarentenaUtilizador`** — administrative procedure that puts a user in quarantine: flags their meters for maintenance and cancels their active offers in one transaction.

### Triggers

- **`trg_DetectarAnomalias`** (`AFTER INSERT` on `Leituras`) — inspects the incoming reading's JSONB payload; if temperature exceeds a threshold or an error code is present, it flips the meter to `MANUTENCAO` automatically.
- **`trg_ProtegerUtilizadores`** (`BEFORE DELETE` on `Utilizadores`) — blocks deletion of a user with a positive balance or active offers, forcing a proper withdrawal/cancellation first.
- **`trg_AutoMatching_Ordem` / `trg_AutoMatching_Oferta`** (`AFTER INSERT`, statement-level, on `OrdensCompra`/`OfertasVenda`) — fire `sp_MatchingEngine()` automatically whenever new orders or offers land, so matching happens continuously without a separate scheduler.

## Repository structure

```
voltexchange/
├── api/                    # Express API
│   └── src/
│       ├── config/         # DB connection pool
│       ├── middleware/     # JWT auth
│       ├── routes/         # auth, me, meters, market, admin
│       ├── utils/          # shared route helpers
│       └── migrations/     # numbered SQL scripts, in delivery order
├── frontend/               # Vue 3 + Vite + Tailwind dashboard
│   └── src/
│       ├── api/            # axios client + endpoint functions
│       ├── stores/         # Pinia (auth, user, toast)
│       ├── views/          # Dashboard, Market, Activity, Meters, Internals
│       ├── components/     # layout, ui, dashboard
│       └── i18n/           # en.json / pt.json (browser-language detection)
├── sql/                    # Final consolidated scripts (as submitted)
│   ├── ddl.sql             # schema + partitions + indexes
│   ├── logic.sql           # procedures + triggers
│   └── seed.sql            # demo/test data
├── BD2___projeto_2026-3.pdf   # Original assignment brief
├── VoltExchange.postman_collection.json
└── docker-compose.yml.example
```

`sql/` holds the final, deduplicated scripts as delivered for grading. `api/src/migrations/` keeps the step-by-step history (schema → partitions → indexes → seed → procedures → triggers) for anyone who wants to see how the design evolved.

## Running it

```bash
cp .env.example .env            # fill in DB credentials
cp docker-compose.yml.example docker-compose.yml
docker compose up --build
```

This spins up Postgres (seeded via `sql/ddl.sql` → `sql/logic.sql` → `sql/seed.sql`), the API on the port set in `.env`, and the frontend on http://localhost:8095 (`FRONTEND_PORT`). The frontend reads the backend URL from a `config.js` generated at container start, so the same built image works against any backend without a rebuild.

Log in with a seed account (e.g. `alice@voltexchange.com` / `senha123` — has meters with 2 years of readings) or register a new account and use the demo deposit to get a balance.

Without Docker:

```bash
psql -U postgres -d voltexchange -f sql/ddl.sql
psql -U postgres -d voltexchange -f sql/logic.sql
psql -U postgres -d voltexchange -f sql/seed.sql

cd api && npm install && npm run dev
```

Seed data includes ~500,000 meter readings across 10 meters, 1,000 sell offers and 500 buy orders — enough volume to see the partitioning and indexing actually matter (`EXPLAIN ANALYZE` on a date-ranged reading query hits one partition, not all 24).

## API

| Area | Endpoints |
|---|---|
| Auth (public) | `POST /api/auth/register`, `POST /api/auth/login` |
| Profile (JWT) | `GET /api/me`, `POST /api/me/deposit` (demo funding), `GET /api/me/offers`, `GET /api/me/orders`, `GET /api/me/transactions` |
| Meters (JWT) | `GET /api/meters`, `POST /api/meters/:id/readings`, `GET /api/meters/:id/readings?inicio=&fim=` |
| Market (JWT) | `GET /api/market/offers`, `POST /api/market/offers`, `POST /api/market/offers/:id/buy`, `POST /api/market/order`, `PATCH /api/market/offers/:id/cancel`, `PATCH /api/market/order/:id/cancel`, `POST /api/market/match` |
| Admin (JWT) | `GET /api/admin/anomalies`, `GET /api/admin/transactions`, `GET /api/admin/users`, `POST /api/admin/quarantine/:userId` |

> Note: there is no role system — the `admin` routes only require a valid JWT. The frontend presents them openly in a "DB Internals" panel as a deliberate PostgreSQL showcase, not as real access control.

A full Postman collection is included (`VoltExchange.postman_collection.json`) with example requests for every endpoint.

## Author

Built end-to-end (schema, procedures, triggers, and API) by André Pacheco as the Database Systems II project.
