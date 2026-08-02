# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Three audiences, owner-operators first:

1. **Server owner-operators (primary).** Small teams running a GrandRP-inspired roleplay server on FiveM. They install the framework, configure it via `server.cfg`, and want security + anticheat defaults working out of the box rather than bolting them on.
2. **Players on the RP server.** End users who never touch framework code; they only experience the in-game React NUI (HUD, inventory, bank, character creation, spawn selection). Smoothness of that NUI is the felt product.
3. **Developers extending the framework.** The owner and collaborators building resources on top of `zenith-core`'s exports. TypeScript types for FiveM natives, Vite HMR, Stylua + ESLint, and a typed Lua↔NUI bridge are the success metric for this group.

## Product Purpose

Zenith Framework is a modular FiveM roleplay framework built from scratch on Overextended's `ox_mysql` and `ox_lib`, plus many original resources. It exists to give a roleplay server (a) a custom React NUI inspired by the GrandRP server's UI conventions, and (b) a smoother RP experience by utilizing the host CPU's ticks at the full rate. Success means a server operator can install Zenith, configure purely through `server.cfg` and per-resource `config.lua`, and get a secure, server-authoritative RP server with a polished shared design system across every menu — without editing framework source to change values.

## Positioning

Full ownership of the core with no opaque upstream to fight (unlike ESX/QBCore derivatives), plus a first-class GrandRP-inspired React NUI reused across every menu. Where ESX/QBCore mixes framework values into source code, Zenith moves all tuning to `server.cfg` `set cfg_*` overrides; where most FiveM frameworks treat the NUI as an afterthought, Zenith treats one shared design-system package as the product surface every resource renders into.

## Operating Context

- **Runtime:** FiveM (Lua 5.4 runtime), React 18+Vite+TS+Tailwind NUI in CEF.
- **Backing services:** MySQL 8 / MariaDB 10.5+ via `ox_mysql` (JSON functions required); `ox_lib` for callbacks, context menus, notify, input, zones, profiling.
- **Topology:** many small self-contained resources under `resources/`, each owning its data and exposing a clean `module:Method` export API plus `zenith:module:action` ox_lib callbacks. Dependency graph: migrations → ox_lib/ox_mysql → zenith-core → zenith-player → (characters, money, jobs, spawn, housing, admin → permissions) → zenith-nui last. (Note: `ox_inventory` is a customized UI fork loaded alongside the framework).
- **Workflows:** server boots → `zenith-migrations` runs versioned `sql/migrations/*.sql` in order inside transactions → `zenith-permissions` mirrors `user_groups` to ace principals → `zenith-player` resolves identifiers → player joins → `zenith-characters` create/select → `zenith-spawn` spawn selection → live RP with shared NUI overlay (HUD fixed; menus mount/unmount on demand).
- **Dev loop:** `pnpm dev` in `resources/zenith-nui/web` for Vite HMR on :5173; Lua reloads via `/rl`; `pnpm build` emits `dist/` consumed by `fxmanifest.lua`.
- **Target host:** a single FiveM server process on a VPS; deployment scale is undecided (see Open Decisions).

## Capabilities and Constraints

Confirmed MVP capability spread (one resource each, all server-authoritative):

- **zenith-core** — hub: `Zenith.DB` (query cache + trace over `MySQL.*`), `Zenith.Player` registry, typed `Zenith.Event` bus, `Zenith.Config` (per-resource config + hot-reload in dev), `Zenith.Logger`, `Zenith.Ready` signal for inter-resource init ordering.
- **zenith-migrations** — scans `sql/migrations/*.sql`, runs un-applied in order inside transactions, records `schema_migrations`, fails fast (halts server on migration failure), `--nomig` escape hatch.
- **zenith-player** — identifier → `users` row resolution; session lifecycle; `GetPlayer`, `GetIdentifier`; `player:joining/joined/dropped` events.
- **zenith-characters** — multi-character slots (default 5, configurable), NUI character creation (name, DOB, gender, height, nationality, `skin_json` via NUI camera), soft delete with delayed purge, `GetCharacter`/`GetActiveCharacter`.
- **ox_inventory (custom fork)** — Overextended inventory engine with standard database/logic backend. The frontend (Vite/React/TypeScript) under `resources/ox_inventory/web` is completely replaced/styled to match the GrandRP-inspired design system.
- **zenith-money** — cash/bank/crypto per character cached then written through; every mutation appends to `money_ledger` (never `UPDATE balance = balance + X`); `AddMoney/RemoveMoney/GetMoney/TransferMoney`; bank NUI (statement, transfer, salary history); anticheat ceiling + anomaly detection into `admin_logs`.
- **zenith-jobs** — jobs + grades + permissions, duty on/off affecting salary and access, gang roster lives in `jobs WHERE type='gang'`, configurable payday tick, job stash/vault perms delegated to inventory by `owner_id`.
- **zenith-spawn** — NUI spawn selection with map pin cards (GrandRP-style) on first join; last-position respawn on later joins unless dead; hospital respawn if dead (configurable); `SetSpawnPoint`/`GetLastSpawn`.
- **zenith-housing** — admin-placed houses, buy/rent/sell/keys, shell interiors (ox_lib/IPL), stash + wardrobe wired to inventory. Robbery hooks deferred to phase 2.
- **zenith-admin** — `/admin` NUI: player list, teleport, heal, freeze, kick, ban; spectate with anti-abuse; console-only commands gated by ace (`command.ban`, `command.kick`); all actions → `admin_logs`.
- **zenith-permissions** — loads `user_groups` at boot, mirrors to `ExecuteCommand('add_principal … group.<group>')`, syncs DB ↔ ace both ways via `/grantgroup`/`/revokegroup`, HMAC over ace grants, exposes `canDo(action)` to inventory/jobs/admin.
- **zenith-nui** — the React app, built into `dist/`, one design-system package reused by every menu; lives in `resources/zenith-nui/web` with `src/design-system`, `src/hud`, `src/menus`, `src/lib` (nui bridge, `useNuiCallback`, `fetchNui`).

Confirmed technical constraints:

- Lua 5.4 client/server/shared split per resource; React 18 + Vite + TypeScript + Tailwind for the NUI.
- Server is the source of truth: clients request, server validates; per-action auth through `zenith-permissions`.
- Money is a deterministic append-only ledger; inventory/money swaps are transactional and atomic.
- Ace governs infrastructure; DB groups govern gameplay; never reuse a server console principal as in-game authority.
- Every resource carries one README documenting its public API + examples; all action names live in `types/bridge.d.ts` and are auto-generated from documented events (drift is a TS build error).
- Configuration only via `shared/config.lua` + `set cfg_*` overrides in `server.cfg`; no editing framework source to tweak values (the ESX anti-pattern).

### Open Decisions

- **Deployment scale.** Single community server (tens of players) vs single high-population server (100+) vs multi-server/networked with shared backend. Not decided. MVP is built for a single FiveM server and optimized for simplicity, but must avoid choices that block multi-server sharding later.
- **Clothing system.** `ox_appearance` (recommended, reuses `skin_json`) vs `fivem-appearance`. To be decided during milestone M2.
- **Item image hosting.** Local `web/dist/img/items/` (zip-bloat) vs operator CDN. Recommendation on file: local with build-time hashing + a `set cfg_item_images_url` override.
- **Vehicle layer.** A separate `zenith-vehicles` resource (parked, garages, fuel) is phase 2, not MVP.
- **Phone.** `zenith-phone` phase 2; likely a thin React-NUI phone calling Zenith's own SMS/contacts endpoints.
- **Multi-language.** Only client-visible messages localized; use the ox_lib locales system; English default.

## Brand Commitments

- **Name:** Zenith Framework (also `zenith_framework` / `zenith-*` resources). Binding.
- **Visual reference:** the UI conventions of the **GrandRP** server. Binding as inspiration only — "GrandRP-inspired React NUI" per PLANNING.md §2/§6.2. Exact dark-glass + amber/blue/red palette, Inter + JetBrains Mono, sharp 2px corners, and the shared component list (Button, IconButton, Modal, Panel, Card, Stat, Hotbar, ContextMenu, Dialog, Toast, Tabs) live in PLANNING.md as a proposal, not yet an authority — the visual world is established later in new-work and recorded in DESIGN.md.
- **Voice / personality:** not yet established beyond "GrandRP-inspired". No invented testimonials, customers, benchmarks, or release claims.
- **License:** MIT. Binding. Enables public contribution from M0.

## Evidence on Hand

- `PLANNING.md` — 485-line planning document: goals/non-goals, full tech stack, repo layout, resource dependency graph, proposed DB schema (users, characters, items, inventory_slots, drops, jobs, job_grades, job_members, money_ledger, houses, house_owners, user_groups, admin_logs, schema_migrations), per-module MVP spec, NUI bridge contracts, security principles, migrations system, CI plan, and milestone table M0→M7.
- `README.md` — placeholder (`# zenith_framework`) only; no product copy yet.

Absences future work must not fabricate:

- No screenshots, testimonials, player counts, uptime, or benchmark numbers exist. None may be invented.
- No existing characters, items, jobs, or houses data. Schema is proposed only.
- No DESIGN.md or surface brief yet; the visual world is not established.
- No deployed server evidence; the project is at the M0 pre-scaffold stage (only `README.md` and `PLANNING.md` are committed).

## Product Principles

1. **Own the core.** The framework source is ours; no opaque upstream to fight. Decisions that would re-introduce an ESX/QBCore dependency or anti-pattern are rejected at the spec stage.
2. **The NUI is the product.** Every menu shares one design-system package and one GrandRP-inspired visual world; HUD lives in a fixed overlay, menus mount/unmount on demand, and a mediocre NUI on a solid backend is still a failure.
3. **Configure, don't fork.** All tuning flows through `shared/config.lua` defaults plus `server.cfg` `set cfg_*` overrides. Editing framework source to change a value is a bug.
4. **Server authority is non-negotiable.** Clients request; the server validates per-action via `zenith-permissions`, money is an append-only ledger, and inventory swaps are transactional. Anticheat is shipped, not bolted on.
5. **CPU ticks at the full rate.** Smoothness is a stated goal: server-authoritative state must not become a UX bottleneck. Performance-sensitive hot paths are profiled with `ox_lib` profiling before they earn their place.

## Accessibility & Inclusion

- **English default;** client-visible messages localized through the ox_lib locales system so operators can ship other languages without forking source.
- No product-specific accessibility standard was established in this interview. FiveM NUI runs inside CEF, so standard web accessibility (keyboard navigation, focus management, sufficient contrast) applies to the React NUI but is not yet a binding requirement above baseline web expectations.
