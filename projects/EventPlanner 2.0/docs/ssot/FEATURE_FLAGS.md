# Feature Flags
Last Updated: 2025-08-29 23:15:47Z

- status_v2_dual_write (bool): write both legacy `status` and `status_v2` (migration Phases 1–3).
- status_v2_read_pivot (bool): prefer `status_v2` for reads (migration Phase 3+).

Recommended:
- Store flags in a small config table or env; ensure CI guard for legacy-only writes post-Phase 4.
