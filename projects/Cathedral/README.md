# Cathedral Monorepo

Initial scaffold per build guide. Packages:

- `@cathedral/shared-types`: shared domain & state types
- `@cathedral/game-engine`: authoritative rules simulation (WIP minimal placeholder)
- `@cathedral/gateway-ws`: WebSocket gateway prototype

## Getting Started

Install dependencies (ensure pnpm installed):

```bash
pnpm install
```

Build all:

```bash
pnpm build
```

Run tests:

```bash
pnpm test
```

Run gateway (after build):

```bash
pnpm --filter @cathedral/gateway-ws dev
```

## Next Steps (Roadmap Extraction)

1. Flesh out full piece set & rotations/reflections
2. Implement collision + territory & capture validation
3. Board diff & efficient encoding
4. WebSocket protocol design (intents, acks, state patches)
5. Persistence layer scaffold (Postgres schema & migration tool)
6. Add property-based tests (fast-check) for enclosure invariants
7. Introduce AI heuristic evaluation module

Refer to `Cathedral_build guide.md` for comprehensive specification.
