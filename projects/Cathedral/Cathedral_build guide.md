# Cathedral Build Guide

# Role and Objective

- Act as an expert product strategist and technical architect tasked with designing a world-class web application for the board game "Cathedral." Your objective is to define all critical aspects—rules, style, codebase, infrastructure, and marketecture—for a successful modern adaptation.

# Top-Level Conceptual Checklist

1. Codify complete, faithful Cathedral gameplay rules & edge cases
2. Define experiential vision: visual language, interaction, audio, accessibility
3. Specify end‑to‑end technical architecture (client, server, real-time, AI, infra, tooling, ops)
4. Craft marketecture: audience, positioning, feature roadmap, monetization
5. Risk / scalability / quality strategy with KPIs & success metrics
6. Validation & analytics framework to iterate toward product-market fit

---
## 0. Summary Elevator Pitch

Cathedral Online is a premium, cross‑platform, modern-medieval themed adaptation of the classic territory-control abstract strategy board game. It blends: (a) faithful, highly polished synchronous & asynchronous multiplayer, (b) adaptive AI & puzzle/solo challenge modes, (c) esports-ready ranked ladder, seasonal cosmetic progression, and (d) community workshop variants. Built atop a modular TypeScript mono-repo, real-time authoritative server simulation, and scalable cloud infra, it aims to own the digital niche for deep-yet-accessible spatial placement strategy.

## 1. Gameplay Rules (Authoritative Specification)

## 1.1 Core Components

- Board: 10×10 grid (standard Cathedral) with central 2×2 (or 3×3 variant) representing the Cathedral footprint.
- Pieces (Buildings): Two players (Light / Dark) each have a distinct polyomino-like set (mirrors real set):
  - Shapes: L, T, S, Z, rectangles, plus unique irregulars; each occupies distinct contiguous squares.
  - Count: 28 total buildings including the shared neutral Cathedral piece (placed first).
- Neutral Piece: Cathedral (occupies central designated squares) is placed before player buildings.

## 1.2 Setup

1. Randomly decide who places the Cathedral (or allow bidding: offer opponent X initiative tokens). By default: Random coin flip.
2. Cathedral piece is placed in any legal position where it fits fully within board interior excluding edges (standard is predefined center; variant: free central placement to increase depth).
3. The player who did NOT place the Cathedral moves first placing one of their buildings.

## 1.3 Turn Structure

- Active player selects one unplaced building and attempts placement.
- Placement Rules:
  - Must align to grid; no overlap with existing pieces or outside board.
  - Rotation (0°, 90°, 180°, 270°) & reflection allowed (if respecting physical piece parity; configurable toggle in digital version—default ON for reflection to aid accessibility, OFF in “Tournament Classic”).
  - Cannot encroach (occupy) opponent-controlled territory (see 1.4) unless performing a capture.
- After placement, territory claims and captures are resolved immediately.

## 1.4 Territory Control & Enclosure

- Definition: A territory is a contiguous empty region (orthogonal adjacency) fully enclosed by a single player’s pieces AND the Cathedral (neutral) without any gaps to board edge or opponent pieces forming boundary breaches.
- Claim: After a placement, algorithm flood-fills each empty region; if boundary set contains only player buildings + Cathedral and no edges/opponent buildings, region is owned by that player.
- Consequence: Opponent may not place inside claimed territory; claiming player may fill it with their remaining pieces freely in later turns.
- Variant Options:
  - Fog Claim Reveal: Claims appear with subtle highlight; toggle for competitive mode to delay highlight until end of turn (bluff potential).

## 1.5 Capture Mechanic

- If a newly enclosed region contains exactly one opponent building (completely surrounded) that building is captured: removed and returned to opponent’s reserve (optional variant: removed permanently). Standard physical rule returns it to reserve.
- Multiple opponent buildings inside boundary → no capture (region remains neutral until simplified by future placements). Digital Clarification: The presence of multiple foreign buildings invalidates capture, but territory may remain unclaimed if edges involved.

## 1.6 Illegal Moves & Validation

- Illegal placements: overlaps, off-board, inside opponent’s claimed territory, creating ambiguous (non-simply connected) enclosure algorithm anomalies (guard via geometry test), or self-collision (N/A). UI prevents by pre-validating geometry.
- Undo: Allowed only during same turn before confirm, except in ranked/timed modes.

## 1.7 End Game & Scoring

- Game ends when both players consecutively pass (no legal placements) or one player places all pieces (triggers final opponent turn to attempt to reduce territory differential—optional). Standard: when no further moves by current player, opponent continues until they cannot.
- Score: Sum of empty squares remaining for each player’s unplaced buildings (their area). Player with lower remaining total wins. Tie-breakers: (1) Fewest unplaced pieces count; (2) Earliest claim timestamp aggregate; (3) Sudden-death micro-board (5×5 subset) playoff (digital exclusive). Classic rule: player who placed more buildings wins—supported as legacy scoring option.

## 1.8 Time Controls & Modes

- Real-Time: 10m main + 5s increment; Blitz 3+2; Bullet 1+1.
- Async (Correspondence): 24h / move with vacation bank.
- Solo: AI difficulties (Beginner, Adaptive, Grandmaster ML) or Puzzle Fill challenges (minimal leftover squares). Daily Puzzle seeded by date.

## 1.9 Edge Cases (Algorithmic Test Suite Targets)

- Enclosure touching board edge (not enclosed) must not claim.
- Cathedral participation: Cathedral counts as boundary piece for claims but cannot be captured.
- Simultaneous multiple region claims after a complex placement.
- Capturing with shape that produces nested region inside another claimed region (inner should be merged if same player boundary; else separate neutral pocket).
- Reflection-off rule toggling may change available legal moves—test parity.

## 1.10 Data Structures (Server Simulation)

- Board: 100-cell bit-packed (2 bits occupancy owner + 6 bits piece id) or 10×10 int array.
- Pieces: canonical shape coordinates; precomputed rotations/reflections, hashed for lookup.
- Game State: { id, players[], turn, phase, boardHash Zobrist, territories: map<regionId, owner>, reserves, history (compressed diff ops), clocks }

## 2. Visual & UX/UI Design

## 2.1 Design Language

- Theme: Modern-Medieval Fusion. Palette: Earthen stone (#6B5B4D), aged parchment (#F4E9D3), accent royal azure (#3A63A8), highlight gold (#D8B24A), error crimson (#A33434).
- Typography: Heading: Cinzel (serif, gothic nuance); Body: Inter / Source Sans. Numeric timers: Roboto Mono.
- Iconography: Line + subtle chisel texture. Piece outlines contrast-adaptive.

## 2.2 Layout Principles

- Responsive Core: Board maintains square aspect; side panels collapse to overlays on small screens.
- Priority: Board > Move List > Chat/Emotes > Meta (clocks, score preview) > Ads (only in free tier, non-intrusive below fold).
- Accessibility: High-contrast mode, colorblind palettes (shape texture overlays), full keyboard navigation (WASD focus grid + R/F rotate/flip), ARIA roles for live region updates, screen reader succinct move narrations ("Light places Keep at D4 orientation 90 capturing 1")

## 2.3 Interaction Model

- Drag & Drop with ghost preview; snapping + illegal zone desaturation.
- Tap cycle (mobile): tap piece → orientation wheel (radial) → tap board cell.
- Multi-step Confirm: Ranked uses single tap with 300ms cancel grace (Esc / two-finger tap).
- Territory Highlights: Soft overlay tinted per player; capture animation: pulse + lift & fade piece.

## 2.4 Visual Assets & Rendering

- Board & Pieces: 3D low-poly stylized marble/wood with PBR subtlety; fallback 2D canvas sprite for low-end.
- Technology: Three.js scene; SSR-friendly static preview rendered via headless canvas for SEO.
- Animations: GSAP / React Spring for UI, Three.js tween for piece placement (200ms ease cubic-out).
- Performance Targets: < 120KB critical CSS+JS, < 2.5s LCP on 3G, 60fps interactions.

## 2.5 Audio Design

- Sound Palette: soft wooden placement thud, chime on claim, subdued horn on check-like pivotal capture, ambient monastery wind loop (optional).
- Dynamic Mix: Duck chat notification sounds during piece placement.
- Settings Matrix: Master, SFX, Ambient, Voice (future narration) sliders stored per user.

## 2.6 HUD & Information Architecture

- Primary HUD: Player avatars (Elo, flag), clocks, reserve piece tray (availability + count), last move highlight, score estimator (toggle). Reserve tray supports filtering by size or complexity.
- Secondary Panels: Move list (SAN-like algebraic notation), Chat (markdown-limited), Analysis (after game only—avoid collusion in live ranked).

## 2.7 Onboarding & Tutorials

- Guided interactive steps: highlight board region, instruct first placement, show claim outcome.
- Progressive Disclosure: advanced mechanics (capture variants) introduced after 2 wins vs AI.
- Hints: Suggest 3 legal moves with evaluation deltas (in casual only).

## 2.8 Accessibility Testing KPIs

- WCAG 2.2 AA compliance (contrast > 4.5:1 vital text, focus ring > 2px).
- Screen Reader: NVDA + VoiceOver scripted smoke test flows.
- Motion Reduction: Respect prefers-reduced-motion disables placement tween.

## 2.9 Monetization UX (Non-Pay-to-Win Ethics)

- Cosmetics Drawer: Board material skins, cathedral architectural variants.
- Battle Pass: Seasonal progression bar under move list; challenges ("Capture exactly 1 piece", "Win with <= 5 leftover squares").
- Purchase Flow: Minimal steps (<=3) Apple/Google Pay; localized pricing.

## 3. Technical Architecture

## 3.1 High-Level Diagram (Narrative)

Client (React/Next.js + Three.js) ↔ Real-Time Gateway (WebSocket / Socket.IO) ↔ Game Orchestrator (authoritative simulation + matchmaking) ↔ Persistence (PostgreSQL + Redis) ↔ Analytics/Event Stream (Kafka) → Data Lake (S3/Parquet) → BI / ML (feature store) & Recommendation Services (personalized puzzles).

## 3.2 Frontend Stack

- Framework: Next.js (App Router), TypeScript, React 19.
- State Management: Zustand for local UI; React Query for server data; WebSocket context for real-time events.
- Rendering Layers: Three.js canvas for board/pieces; HTML overlay for HUD; accessible offscreen DOM for screen reader narration.
- Packaging: Vite or Turbopack for dev, production with RSC streaming.
- Testing: Vitest/Jest + Testing Library + Playwright (E2E board interactions), Lighthouse CI.
- Internationalization: i18next (namespace separation: core, gameplay, shop, onboarding).

## 3.3 Backend Services (All TypeScript in a Turborepo)

| Service | Responsibility | Tech | Scaling |
|---------|----------------|------|---------|
| gateway-ws | WebSocket termination, auth handshake, rate-limit | Fastify + uWebSockets.js | Horizontal (sticky by game id) |
| game-engine | Authoritative turn validation, territory algorithm, AI pluggable module host | Pure TS worker cluster | CPU-bound autoscale |
| matchmaking | Queue buckets (Elo ±, time control) | Fastify + Redis streams | Elastic |
| user-profile | Accounts, progress, cosmetics, purchases | Fastify + Postgres | Multi-AZ |
| analytics-ingest | Event intake, schema validation | Node + Kafka producer | Partition scale |
| ai-eval | Monte Carlo / heuristic search evaluation microservice | Rust or TS + WASM core | GPU/Compute pool |
| notifier | Email/push/async turn reminders | Node + SES/FCM/APNs | Queue-driven |

## 3.4 Data Model (Selected Tables)

- users(id, handle, elo_overall, locale, settings_json, created_at)
- games(id, status, variant, started_at, ended_at, player_light_id, player_dark_id, result, moves_pgn_like, final_board_hash)
- game_positions(game_id, ply, board_hash, territories_json, move_notation, clocks_json)
- inventory(user_id, cosmetic_id, acquired_at)
- purchases(id, user_id, sku, price_cents, currency, platform, receipt_json, created_at)
- leaderboards(season, user_id, elo, rank_snapshot_ts)
- events(id, user_id?, game_id?, type, payload_json, ts)

## 3.5 Territory & Capture Algorithm (Pseudo)

```pseudo
place(piece):
  apply piece cells
  changed = union(piece cells, orth adjacency)
  for each empty cell in changed not visited:
   region = flood(empty)
   boundaryOwners = set( owner(cell) for each boundary neighbor piece )
   if edgeTouched(region): continue
   if boundaryOwners subset of {player, neutralCathedral}:
     if count(opponentPiecesInside(region)) == 1:
       capture(pieceOpp)
       // re-run region evaluation after removal
     if opponentPiecesInside(region) == 0:
       claim(region, player)
```

Edge detection optimized via precomputed bitmask edges.

## 3.6 AI Architecture

- Heuristics: Mobility (legal moves count), Territory Potential (flood-fill empties * weight), Piece Fit Difficulty (remaining complex shapes), Opponent Enclosure Threat.
- Search: Iterative deepening alpha-beta with transposition (Zobrist), move ordering (captures -> high territory delta -> largest piece). Late Move Reductions.
- Advanced: Hybrid policy network (WASM ONNX) for move prior ordering (Phase 2). Self-play data ingested into feature store.
- Difficulty Scaling: Depth/time budget + stochastic evaluation noise.

## 3.7 Real-Time & Consistency

- Server authoritative state; clients send intent (pieceId, anchorCell, rotation, reflection mask).
- Validation within <20ms target; if legal, broadcast diff patch (list of modified cells + new territories).
- Reconciliation: Client predicts then confirms; mismatch triggers rollback diff.
- Transport: Binary (MessagePack) for low overhead.

## 3.8 Matchmaking Logic

- Buckets keyed by (timeControl, variant, EloTier). Search expands ±Elo every X seconds.
- Async invites use short-lived signed join tokens.
- Anti-smurf: Device/behavioral fingerprint heuristics.

## 3.9 Security & Fair Play

- Auth: JWT (short) + Refresh tokens (HttpOnly) + WebSocket upgrade token.
- Anti-Cheat: Server-only AI assistance locked; suspicious high-accuracy patterns flagged (z-score vs baseline). Rate-limit orientation brute force.
- Observability: Structured logs (pino), metrics (Prometheus), traces (OpenTelemetry) with exemplar linking to game id.

## 3.10 Infrastructure & DevOps

- Deployment: Kubernetes (EKS/GKE) with separate node pools (CPU vs GPU for AI). CI: GitHub Actions → build, test, lint, container scan (Trivy), deploy via ArgoCD.
- Caching: Redis (moves, session), CDN (CloudFront/Fastly) for static and progressive 3D asset streaming (basis compressed textures).
- Storage: S3 for replays (JSONL or compressed binary), CloudFront cached.
- Secrets: Vault / AWS Secrets Manager.
- IaC: Terraform modules (network, db, redis, k8s, monitoring). Policy as code (OPA) gating.

## 3.11 Tooling & Developer Experience

- Monorepo: Turbo build pipelines; ESLint + Prettier + TypeDoc.
- Code Quality Gates: 90% logic coverage game-engine; mutation testing (Stryker) subset.
- Feature Flags: OpenFeature SDK; config persisted in Postgres + cached.
- Local Dev: Docker Compose spins Postgres, Redis, Kafka (redpanda), MinIO (S3 mock), MailHog.

## 3.12 Analytics & Telemetry

- Event Taxonomy: game_move, game_end, territory_claimed, capture, matchmaking_queue_enter, purchase_complete, tutorial_step.
- Funnel KPIs: D1/D7 retention, conversion to first multiplayer, average session length, churn hazard triggers (lack of wins).
- A/B Testing: Flag based; sequential testing for low-traffic variants.

## 3.13 Performance Budgets

- P95 move latency < 150ms global.
- Backend cost target: < $0.05 per active DAU at scale 100k.
- AI move compute < 600ms at depth target for mid difficulty.

## 3.14 Scalability & Load Strategy

- Shard game-engine by consistent hash of game id; sticky gateway routing.
- Horizontal autoscale on queue depth & CPU. Pre-warm AI workers.
- Replay offload to async pipeline (Kafka consumer) to minimize write amplification.

## 3.15 Disaster Recovery & Reliability

- RPO: 5m (WAL shipping to cross-region standby). RTO: < 30m.
- Chaos testing: quarterly game state corruption drills.
- Circuit breakers: degrade to async-only if real-time load threshold exceeded.

## 3.16 Compliance & Privacy

- GDPR: Data export endpoint; pseudonymize IP after 30 days.
- COPPA (if minors): Age gate gating chat/emotes; safe dictionary filtering.

## 3.17 Roadmap-Linked Architecture Hooks

- Workshop (Phase 3): Asset pipeline prepped for custom board skins; server validates community variant rule sets (DSL subset).
- Spectator/Streaming API (Phase 2 late): Event-sourced feed with filtering.

## 4. Marketecture & Product Strategy

## 4.1 Target Segments

| Segment | Need | Value Proposition |
|---------|------|-------------------|
| Abstract Strategy Enthusiasts | Depth, fairness, ranking | Precise implementation + competitive ladder |
| Casual Mobile Gamers | Quick sessions | Smooth onboarding + daily puzzles |
| Board Game Collectors | Authenticity, aesthetics | Faithful visuals + lore + premium cosmetics |
| Streamers / Influencers | Content hooks | Spectator overlays + puzzle race events |
| Educators / Cognitive Training | Spatial reasoning tool | Analytics dashboards + classroom mode |

## 4.2 Positioning Statement

For strategic thinkers seeking elegant spatial mastery, Cathedral Online is the definitive digital adaptation delivering authentic depth and modern polish, unlike generic puzzle apps or low-fidelity ports.

## 4.3 Messaging Pillars

1. Authentic Strategy: Every ruling codified & transparent.
2. Beautifully Crafted: Hand-textured 3D medieval-modern ambiance.
3. Fair Competitive Play: Anti-cheat & skill-based ranking.
4. Evolving Challenges: Daily puzzles, seasonal goals.
5. Ethical Monetization: Cosmetics only; no pay-to-win.

## 4.4 Feature Phase Roadmap

| Phase | Timeline | Key Features | Monetization | Validation Metrics |
|-------|----------|-------------|-------------|-------------------|
| 1 Core Launch | M0-M3 | Real-time ranked, AI (2 levels), tutorial, web & mobile web | None (foundational) | Retention D7 > 25%, Avg games/user D2 > 3 |
| 2 Growth | M4-M6 | Advanced AI, Daily puzzles, Cosmetics shop, Season 1 Pass, Async games | Cosmetics, Pass | ARPPU > $4, Conv > 3% |
| 3 Community | M7-M9 | Workshop variants, Spectator mode, Stream overlays, Events | Premium skins bundles | UGC > 10% sessions |
| 4 Expansion | M10+ | Mobile native app, Localization 6 langs, ML match insights | Regional bundles | Intl DAU share > 35% |

## 4.5 Monetization Model Detail

- Cosmetics Tiers: Common (colorway), Rare (material), Epic (animated cathedral aura), Limited (seasonal architectural style).
- Season Pass: 90-day cadence; XP from wins, puzzle streaks, community events.
- Bundles: Starter aesthetic pack; region-specific pricing fairness (PPP indexing via external service).
- Future Optional: Tournament premium entries with sponsorship-funded prize pools (strict fairness audit).

## 4.6 Competitive Landscape

| Competitor Type | Examples | Gap Openings |
|-----------------|----------|--------------|
| Generic Abstract Portals | BoardGameArena | Superior bespoke polish & AI depth |
| Casual Block Puzzles | Tetris-like clones | True territory control & multiplayer depth |
| Physical-only Fans | N/A digital | Accessibility, global matchmaking |

## 4.7 KPIs & North Star

- North Star: Weekly Engaged Strategists (≥3 multiplayer games + 1 puzzle).
- Supporting: Match Completion Rate > 95%; Queue Median Wait < 30s prime time.

## 4.8 Risk Register (Top 6)

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| AI too strong discouraging | Medium | Medium | Adaptive difficulty calibration |
| Monetization backlash | High | Low | Transparent cosmetic-only policy |
| Latency spikes | High | Medium | Multi-region PoPs, routing metrics |
| Cheating / tooling | High | Medium | Behavior anomaly detection |
| Scope creep Phase 1 | Medium | High | Strict launch cutline, flag future |
| Low early retention | High | Medium | Iterative onboarding A/B tests |

## 4.9 Community & Engagement

- Events: Weekly territory efficiency challenge; monthly Invitational.
- Social Integrations: Share final board export (PNG / GIF animation) + short URL.
- Feedback Loop: In-app feature voting + NPS micro-survey after 5 games.

## 4.10 Localization Strategy

- Phase order: EN → DE, FR, ES, PT-BR, JA. Machine pre-translation + human review (game terms glossary).

## 4.11 Ethical & Inclusive Design

- No dark patterns (explicit odds for seasonal cosmetics if RNG packs introduced later).
- Inclusive avatar library; pronoun selection optional.

## 5. Quality, Testing & Governance

## 5.1 Test Pyramid

- Unit: geometry, enclosure, AI eval (mutation tested).
- Property-Based: random board states maintain invariants (no overlapping, correct territory ownership).
- Integration: full turn flows, matchmaking queue join → game start → termination.
- E2E: user signup, tutorial completion, ranked match, purchase simulation.

## 5.2 Release Workflow

- Trunk-based with short-lived feature branches; PR checks: lint, unit+integration, perf budget diff, bundle size gate.
- Canary Deploy (5%) with synthetic match load generator.

## 5.3 Metrics to Gate Release

- Error Rate < 0.5% 5xx game endpoints.
- P95 auth latency < 120ms.
- Client crash-free sessions > 99.5%.

## 6. Implementation Sequencing (Phase 1 Sprint Outline)

| Sprint | Goals | Deliverables |
|--------|-------|-------------|
| 0 (Prep) | Repo, infra skeleton | Turborepo, Docker Compose, CI pipeline |
| 1 | Core board rendering + piece interactions | 2D fallback, rotation/flip logic |
| 2 | Game rules engine + validation | Unit tests, territory claim algorithm |
| 3 | Real-time multiplayer minimal | Lobby, join, move broadcast |
| 4 | Persistence + replay | Game save, move list, basic analysis playback |
| 5 | AI v1 (heuristic shallow) | Difficulty selection, move timing |
| 6 | Polishing + Tutorial | Onboarding flow, accessibility pass |
| 7 | Closed Beta Launch | Metrics instrumentation, feedback loop |

## 7. Self-Validation Checklist

- Rules coverage: setup, placement, claim, capture, scoring, termination, edge cases ✅
- Design: visual, interaction, accessibility, performance budgets ✅
- Architecture: services, data, AI, infra, security, scaling, observability ✅
- Marketecture: audience, positioning, roadmap, monetization, risks, KPIs ✅
- Quality & sequencing: testing, sprints, release gating ✅
No critical gaps detected against internal rubric.

## 8. Completion

This document constitutes the comprehensive Cathedral web app design & build guide (Phase 1–3 scope). Ready for implementation kickoff.
