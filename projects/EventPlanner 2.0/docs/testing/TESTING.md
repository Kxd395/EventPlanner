# Testing & CI Strategy (Phase 1)
Last Updated: 2025-08-29 23:15:47Z

## Principles
- Fast, deterministic, layered confidence; no network flakiness.

## Pyramid Targets
- Unit ~60% (Swift view models, Rust domain)
- Integration/API ~30% (SQLite + services)
- UI/Smoke ~10% (critical journeys)

## Coverage & Gates
- Lines ≥ 70% (Phase 1 exit), roadmap to 80%.
- Lint clean; security advisories: block.
- Migration guard: fail on legacy-only status writes post-pivot.

## DB Seeding
- Fresh migrations per run; small seed (1 event, 3 members, varied statuses).
- Tests run in transaction and rollback per test.

## Analytics Validation
- Trigger core events; validate schema and `pii` boundary.

## CI Stages
- Install & build → Lint & type check → Unit → Integration → UI smoke → Coverage/artifacts.
