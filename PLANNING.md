# Zenith Framework — Planning Document

A modular FiveM roleplay framework built from scratch, using **ox_mysql** and **ox_lib**, with a GrandRP-inspired React NUI, multi-resource layout, versioned migrations, ace + DB groups, and CI out of the box.

> Status: **Planning** · Owner: @subhamoy · Last updated: 2026-08-01

---

## 1. Goals & Non-Goals

### Goals
1. **Full control** — we own the core; no opaque upstream to fight with.
2. **First-class UI** — GrandRP-style React + Vite + TS + Tailwind NUI, shared design system across every menu.
3. **Modularity** — many small resources, each resource owns its data and exports a clean API.
4. **Security by default** — server-authoritative state, ace + DB groups, anticheat-friendly hooks.
5. **Dev experience** — Vite HMR for NUI, Stylua + ESLint, TS types for FiveM natives, migrations on boot, GitHub Actions.

### Non-Goals (MVP)
- Backwards-compat shims with ESX/QBCore (we import data later via a converter).
- Phone / economy depth features beyond banking basics.
- Voice-radio subsystem (phase 2).

---

## 2. Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Game scripting | Lua 5.4 (FiveM runtime, build 3258 E&E enforced) | client/server/shared split per resource |
| DB layer | **ox_mysql** | async/await + prepared statements, exposed as `Zenith.DB` helper in core |
| Shared lib | **ox_lib** | callbacks, context menus, notify, input dialog, zones, profiling |
| NUI | React 18 + Vite + TypeScript + Tailwind | one design-system package reused by all NUI |
| NUI ↔ Lua bridge | ox_lib `callbacks` + custom typed message bus | see §6 |
| Lint/format | Stylua (Lua), ESLint + Prettier (TS) | enforced in CI |
| FiveM natives types | `citizenfx-types` or `@citefx/types` (TBD in scaffold) | autocomplete + safety |
| Migrations | Custom versioned `*.sql` runner inside `zenith-migrations` | runs on server boot; idempotent |
| CI | GitHub Actions | lint + typecheck + NUI build + run `oxmysql` smoke test |
| License | MIT (or private) | decided in scaffold step |

---

## 3. Repository Layout (Many small resources)

```
zenith_framework/
├── server.cfg                     # master cfg — sets vars, principals, ensures resources
├── README.md
├── PLANNING.md                     # this file
├── AGENTS.md                       # opencode working agreement (lint/build/run commands)
├── .github/workflows/ci.yml
├── .github/workflows/release.yml
├── .stylua.toml
├── .eslintrc.cjs / eslint.config.js
├── .prettierrc
├── pnpm-workspace.yaml
│
├── resources/                      # every resource is self-contained
│   │
│   ├── zenith-core/                 # bootstrap, player registry, event bus, exports hub
│   │   ├── fxmanifest.lua
│   │   ├── server/
│   │   ├── client/
│   │   ├── shared/
│   │   └── README.md
│   │
│   ├── zenith-player/               # identifiers, sessions, character lifecycle
│   ├── zenith-characters/           # multi-character, slot DB, char creation NUI hook
│   ├── ox_inventory/                # customized UI fork of ox_inventory (item logic, backend)
│   ├── zenith-jobs/                 # jobs, duty, salaries, gang roster
│   ├── zenith-money/                # cash+bank+crypto, transactions log
│   ├── zenith-housing/              # houses, shells, keys, stash link to inventory
│   ├── zenith-spawn/                # spawn selection, last position
│   ├── zenith-admin/                # ace commands, admin menu, ban/kick logs
│   ├── zenith-permissions/          # ace + DB groups bridge (depends on core + admin)
│   ├── zenith-migrations/           # runs SQL migrations on boot (highest priority)
│   ├── zenith-nui/                  # the React app, built into dist/, shared design system
│   │   ├── fxmanifest.lua           # ensures built assets + dev HTML
│   │   ├── web/
│   │   │   ├── package.json
│   │   │   ├── vite.config.ts
│   │   │   ├── tailwind.config.js
│   │   │   ├── tsconfig.json
│   │   │   ├── src/
│   │   │   │   ├── design-system/  # Button, Modal, Panel, TextInput, Icon…
│   │   │   │   ├── hud/             # HUD, health/armor/stress, status, min cash
│   │   │   │   ├── menus/           # Inventory, Bank, Admin, Jobs, Spawn…
│   │   │   │   ├── lib/             # nui bridge, useNuiCallback, fetchNui
│   │   │   │   └── index.tsx
│   │   │   └── dist/                # built output (generated)
│   │   └── client/nui.lua           # window focus, message router
│   │
│   └── [shared_depends]/            # ox_lib, ox_mysql — symlinked or referenced from cfg
│
├── sql/
│   ├── schema.sql                  # full current schema (regeneratable)
│   └── migrations/
│       ├── 0001_initial.sql
│       ├── 0002_players_meta.sql
│       └── …
│
├── types/                           # shared TS types for Lua↔NUI bridge events
│   └── fivem.d.ts
│
└── docs/
    ├── architecture.md
    ├── data-model.md
    ├── nui-bridge.md
    └── CONTRIBUTING.md
```

### Resource dependency graph
```
zenith-migrations  ──┐
ox_lib             ──┤
ox_mysql           ──┼──►  zenith-core  ──►  zenith-player  ──►  zenith-characters
                                                  │
                                                  ├──► ox_inventory
                                                  ├──► zenith-money
                                                  ├──► zenith-jobs
                                                  ├──► zenith-spawn
                                                  ├──► zenith-housing
                                                  └──► zenith-admin  ──► zenith-permissions
                                                                                         │
                                                                             zenith-nui (depends on all core events but loads last)
```

---

## 4. Database Schema (proposed)

Single players table + per-module tables, JSONB columns for soft/volatile state. Target: MySQL 8 / MariaDB 10.5+ (JSON functions required).

### 4.1 Users & Characters
```sql
CREATE TABLE users (                       -- one row per FiveM player (license)
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  license VARCHAR(48) UNIQUE NOT NULL,    -- fivem:license
  steam VARCHAR(32), discord VARCHAR(32), fivem VARCHAR(48),
  ip VARCHAR(45),
  last_seen DATETIME,
  banned BOOLEAN DEFAULT FALSE, ban_until DATETIME, ban_reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_license (license)
);

CREATE TABLE characters (                  -- multi-character slots
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  slot TINYINT NOT NULL,                  -- 1..N (configurable max)
  first_name VARCHAR(32), last_name VARCHAR(32),
  dob DATE, gender VARCHAR(16), nationality VARCHAR(32),
  height TINYINT, skin_json JSON NOT NULL,
  metadata JSON NOT NULL,                 -- any volatile flags
  last_pos JSON DEFAULT NULL,             -- vector4 {x,y,z,h}
  json_money JSON NOT NULL,               -- {cash,bank,crypto}
  json_job JSON NOT NULL,                 -- {name,grade,duty}
  is_dead BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP NULL,
  UNIQUE KEY uk_user_slot (user_id, slot),
  INDEX idx_user (user_id)
);
```

### 4.2 Inventory (custom; not ox_inventory, but compatible metadata)
```sql
CREATE TABLE items (                       -- item definitions (server-side seed)
  name VARCHAR(48) PRIMARY KEY,
  label VARCHAR(64), weight SMALLINT DEFAULT 0,
  stack BOOLEAN DEFAULT TRUE, close_on_use BOOLEAN DEFAULT TRUE,
  category VARCHAR(24), image VARCHAR(128),
  unique BOOLEAN DEFAULT FALSE, description TEXT
);

CREATE TABLE inventory_slots (             -- every container is a set of slots
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  owner_kind ENUM('character','trunk','stash','drop','glovebox','house'), -- no ENUM in MariaDB → VARCHAR(16)+index
  owner_id VARCHAR(64),                    -- char id or stash name
  slot SMALLINT NOT NULL,
  item_name VARCHAR(48) NOT NULL,
  count INT NOT NULL DEFAULT 1,
  metadata JSON NOT NULL,                  -- durability, attachments, serial, custom
  UNIQUE KEY uk_owner_slot (owner_kind, owner_id, slot),
  INDEX idx_item (item_name),
  CONSTRAINT fk_inv_item FOREIGN KEY (item_name) REFERENCES items(name)
);

CREATE TABLE drops (                       -- ground drops (despawn after X)
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  pos JSON NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, despawn_at DATETIME,
  INDEX idx_pos ( (CAST(pos->>'$.x' AS DOUBLE)) )
);
```

### 4.3 Jobs & Gangs
```sql
CREATE TABLE jobs (
  name VARCHAR(48) PRIMARY KEY,
  label VARCHAR(64), type ENUM('job','gang'),
  default_duty BOOLEAN DEFAULT FALSE,
  salary INT DEFAULT 0
);
CREATE TABLE job_grades (
  job_name VARCHAR(48), grade TINYINT, label VARCHAR(64), salary INT, is_owner BOOLEAN DEFAULT FALSE,
  perms JSON NOT NULL,                     -- {manage, hire, fire, stash, vault, duty}
  PRIMARY KEY (job_name, grade),
  CONSTRAINT fk_grades_job FOREIGN KEY (job_name) REFERENCES jobs(name) ON DELETE CASCADE
);
CREATE TABLE job_members (                 -- explicit roster (denormalized from characters.json_job)
  character_id BIGINT PRIMARY KEY,
  job_name VARCHAR(48), grade TINYINT, is_duty BOOLEAN DEFAULT FALSE,
  UNIQUE KEY uk_char_job (character_id, job_name)
);
```

### 4.4 Money & Banking
```sql
CREATE TABLE money_ledger (                -- append-only transactions
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  character_id BIGINT NOT NULL,
  kind ENUM('cash','bank','crypto'),
  amount INT NOT NULL,                     -- + positive = credit, - negative = debit
  balance_after INT NOT NULL,
  reason VARCHAR(48), src_id VARCHAR(64), dest_id VARCHAR(64),
  metadata JSON NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_char_time (character_id, created_at)
);
```

### 4.5 Housing
```sql
CREATE TABLE houses (                       -- shell templates (admin-defined)
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  label VARCHAR(64), shell VARCHAR(48), pos JSON, price INT,
  stash_slots SMALLINT DEFAULT 50, ward_slots SMALLINT DEFAULT 30
);
CREATE TABLE house_owners (                -- who owns / keys
  house_id BIGINT PRIMARY KEY,
  character_id BIGINT, owned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  rent_until DATE NULL,
  keys JSON NOT NULL                        -- array of char ids + names
);
```

### 4.6 Permissions & Admin
```sql
CREATE TABLE user_groups (                 -- DB-side role map, mirrored to ace at boot
  license VARCHAR(48) NOT NULL,
  group_name VARCHAR(32) NOT NULL,          -- 'admin','mod','helper','vip'…
  granted_by VARCHAR(48), granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (license, group_name)
);

CREATE TABLE admin_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  admin_license VARCHAR(48), target_license VARCHAR(48),
  action VARCHAR(32), reason TEXT, evidence_url VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4.7 Migrations bookkeeping
```sql
CREATE TABLE schema_migrations (
  version INT PRIMARY KEY,
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 5. Core Modules (MVP)

Each module = one resource. Every resource exposes:
- **exports** (server): `module:Method(...)`
- **ox_lib callbacks**: `zenith:module:action` pattern (typed on both sides)
- **events** for one-way notifications
- **one README** with public API + examples

### 5.1 zenith-core

The hub. Provides:
- `Zenith.DB` (thin wrapper over `MySQL.*` from ox_mysql, with query cache + trace)
- `Zenith.Player` registry (server-held table of active Citizens keyed by source)
- `Zenith.Event` (typed internal bus, replaces scattering of `TriggerEvent`)
- `Zenith.Config` (load `config.lua` per resource, hot-reload in dev)
- `Zenith.Logger` (pretty + level + file rotation via ox_lib)
- `Zenith.Ready` signal so resources can `WaitFor('inventory')` before init

### 5.2 zenith-player

- Identifiers resolution → finds or creates `users` row
- Session start/end, kick reason handling
- Exposes `GetPlayer(src)`, `GetIdentifier(src, kind)`
- Tracks online count, triggers `player:joining`, `player:joined`, `player:dropped`

### 5.3 zenith-characters

- Multi-character slots (configurable max, default 5)
- Character creation NUI: name, DOB, gender, height, nationality, appearance (skin_json via NUI camera)
- Character deletion (soft delete; holds for X days before purge)
- `GetCharacter(citizenid)`, `GetActiveCharacter(src)`

### 5.4 ox_inventory (custom UI fork)

- Uses standard ox_inventory database schemas, native functions, and server-side logic (containers, drop synchronization, weight checks, durability, metadata).
- Replaces standard ox_inventory React/Vite UI in `resources/ox_inventory/web` with our GrandRP-inspired design system.
- Re-architects frontend drag-and-drop visually to match Zenith framework visual commitments while preserving underlying Redux/DND states.
- Re-uses standard ox_inventory exports and callbacks (`ox_inventory:openInventory`, stashes, etc.) for high compatibility.

### 5.5 zenith-jobs

- Job definition table + grades + permissions
- Duty (on/off) affects salary & access
- Gang roster (data lives in `jobs WHERE type='gang'`)
- Salaries paid every payday tick (configurable)
- Job stash/vault perms delegated to inventory via owner_id

### 5.6 zenith-money

- `cash`, `bank`, `crypto` per character (cached in player object, written through)
- `AddMoney`, `RemoveMoney`, `GetMoney`, `TransferMoney`
- Every mutation → append to `money_ledger` (async, retryable)
- Bank UI (NUI): statement, transfer to another character, salary history
- Anticheat: ceiling checks, anomaly detection (gain > X in Y time → flag in admin_logs)

### 5.7 zenith-spawn

- Spawn selection on first join (NUI with map pins via GrandRP-style cards)
- Last-position respawn on later joins (unless dead)
- Hospital respawn if dead (configurable)
- Exposes `SetSpawnPoint`, `GetLastSpawn`

### 5.8 zenith-housing

- Houses pre-placed in `houses` (admin tool)
- Buy/rent/sell/keys
- Entering shell: ox_lib interiors or IPL shell loader
- Stash + wardrobe containers wired to inventory
- Robbery hooks (phase 2)

### 5.9 zenith-admin

- `/admin` NUI menu (model-viewer style): player list, teleport, heal, freeze, kick, ban
- Spectate (with anti-abuse)
- Console-only commands gated by ace (`command.ban`, `command.kick`)
- All actions logged to `admin_logs`

### 5.10 zenith-permissions

- Loads `user_groups` at boot, mirrors to `ExecuteCommand('add_principal identifier fivem:license:<x> group.<group>')`
- Syncs DB ↔ ace in both directions (`/grantgroup`, `/revokegroup` update DB)
- Used by inventory/jobs/admin for `canDo(action)` checks
- DH-style HMAC over ace grants so forged `add_principal` cli (impossible anyway) can be detected

### 5.11 zenith-migrations

- Scans `sql/migrations/*.sql`, sorts by version, runs un-applied in order inside a transaction
- Records version in `schema_migrations`
- `--nomig` server arg to skip (disaster recovery)
- Stops server with clear error if a migration fails (fail-fast)

---

## 6. NUI Architecture

### 6.1 The bridge

**Lua → NUI** (push data to UI):
```lua
-- server
TriggerClientEvent('zenith:nui:state', src, { namespace='inventory', visible=true, slots=… })
-- client forwards the payload
SendNUIMessage({ type='zenith:state', payload=<above> })
```

**NUI → Lua** (request/response):
- All NUI→Lua goes through `fetchNUICallback(action, data) → Promise<result>` built on ox_lib callbacks.
- Server-side handlers use `zenith:core:callback <action>` so every request is authenticated by `source`.

All action names live in `types/bridge.d.ts` and are auto-generated from documented events. Drift = TS error at build time.

### 6.2 Design system

Inspired by GrandRP (German_rp) UI conventions:
- Dark glass panels (`bg-black/60 backdrop-blur ring-1 ring-white/10`)
- Sharp 2px corners, subtle 1px ring
- Accent amber `#ffb020` for primary, cool blue `#3b82f6` for info, red `#ef4444` for destructive
- Inter UI + JetBrains Mono for numbers
- Components: `Button`, `IconButton`, `Modal`, `Panel`, `Card`, `Stat` (for HUD), `Hotbar`, `ContextMenu`, `Dialog`, `Toast`, `Tabs`
- HUD lives in a fixed overlay div (`pointer-events:none` except hotbar); all other menus mount/unmount on demand.

### 6.3 Dev loop

- `pnpm dev` in `resources/zenith-nui/web` → Vite dev server on `:5173`, NUI uses `nui://` proxy in dev (FiveM CEF supports fetch to localhost via a reverse proxy resource).
- HMR for components, Lua reloads via `/rl` ox_lib helper.
- `pnpm build` → outputs `dist/` consumed by `fxmanifest.lua`.

---

## 7. Security Principles

1. **Server is the source of truth.** Client never tells the server "you have 500 cash". Client requests, server validates.
2. **Per-action auth**: every callback resolves source character, checks `canDo(action)` via `zenith-permissions`.
3. **Idempotent & atomic** DB writes (transactions for money+inventory swaps).
4. **Deterministic ledger** for money — never `UPDATE balance = balance + X`; append ledger row, recompute.
5. **Anticheat hooks**: events subscribe and audit; anomalies log to `admin_logs` + optionally kick.
6. **Ace for infra**, DB groups for gameplay. Never reuse a server console principal as in-game authority.

---

## 8. Migrations System

- Directory: `sql/migrations/NNNN_name.sql`
- Runner: `zenith-migrations` (lower than all others; ensured first in `server.cfg`).
- Each file is wrapped in START TRANSACTION; …; COMMIT; failure → server halts with log.
- CLI helper planned: `pnpm migrate:status` reads the `schema_migrations` table through a tiny node script.

---

## 9. CI Plan

`.github/workflows/ci.yml` runs on push & PR:
1. **Lua lint** — `stylua --check resources/`
2. **NUI lint** — `pnpm -C resources/zenith-nui/web lint`
3. **NUI typecheck** — `pnpm -C resources/zenith-nui/web typecheck`
4. **NUI build** — `pnpm -C resources/zenith-nui/web build`
5. **Migrations smoke test** — spin MySQL 8 service container, run all `*.sql`, assert `schema_migrations` rows.
6. **Lua smoke** — start a FiveM artifact stub is OUT of MVP scope; skipped on CI.

`.github/workflows/release.yml` tags → packs `zenith-framework-<ver>.zip` (resources + sql + server.cfg example) as GitHub release.

---

## 10. Milestones

| # | Milestone | Default branch state at end |
|---|---|---|
| **M0** | Repo scaffold + tooling + server.cfg + ox wiring + CI green (no logic yet) | `zenith/phase-0` |
| **M1** | `zenith-core` + `zenith-migrations` + `zenith-player` works: join server → user row created, basic `/ping` returns char count | `zenith/phase-1` |
| **M2** | `zenith-characters` NUI create/select/delete working against DB; spawn falls back to default | `zenith/phase-2` |
| **M3** | `zenith-inventory` + `zenith-money` end-to-end: `/givecash`, hotbar, ledger entries; `zenith-permissions` mirrors ace | `zenith/phase-3` |
| **M4** | `zenith-jobs` + `zenith-spawn` + `zenith-housing` MVP; admin menu basic only | `zenith/phase-4` |
| **M5** | Design-system pass: HUD polished, every menu uses shared components, screenshot tests in CI | `zenith/phase-5` |
| **M6** | Hardening: anticheat hooks, audit, perf profiling with ox_lib, docs | `zenith/phase-6` |
| **M7** | Public 0.1.0 release zip + installer readme | `main` |

---

## 11. Configuration Strategy

- Every resource has `shared/config.lua` (string-keyed) with sane defaults.
- Operators override via `server.cfg` `set cfg_inventory_max_slots 100` (FiveM's `exec` pattern); core applies overrides at startup.
- Avoid the ESX anti-pattern of editing framework source to tweak values.

---

## 12. Open Questions / Decisions Pending

1. **Item image hosting**: local `web/dist/img/items/` (zip-bloat) vs. operator-provided CDN. Recommend local with build-time hashing + a `set cfg_item_images_url` override.
2. **Clothing system**: ox_appearance (recommended, reuses skin_json) vs. fivem-appearance. Pick during M2.
3. **Vehicle layer**: separate `zenith-vehicles` resource in phase 2 (parked, garages, fuel). Not in MVP.
4. **Phone**: `zenith-phone` phase 2 — probably reuse a thin React-NUI phone that calls our own SMS/contacts endpoints.
5. **License**: MIT (community-friendly) vs. private/commercial. Decide before M0 PRs.
6. **Multi-language**: only client-visible messages should be localized; use ox_lib locales system, English default.

---

## 13. Next Step (immediately after you approve)

I'll start the **M0 scaffold** in this order:
1. `AGENTS.md` with lint/build/test commands (so opencode knows them)
2. `.stylua.toml`, `eslint.config.js`, `.prettierrc`, `pnpm-workspace.yaml`, `.github/workflows/ci.yml`
3. `server.cfg` skeleton (ox_lib, ox_mysql, all `zenith-*` resources ensured)
4. Empty `fxmanifest.lua` for each resource in `resources/`
5. `sql/migrations/0001_initial.sql` (schema from §4)
6. Tiny `zenith-nui/web` Vite+React+TS+Tailwind app that boots and shows "Zenith — ready"
7. Wire `zenith-migrations` to run on boot and create `schema_migrations`
8. Push first commit on a `zenith/phase-0` branch (pending your go-ahead)

When you say "go", I'll execute M0 and we can review the diff together before moving to M1.
