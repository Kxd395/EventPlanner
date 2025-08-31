# Security & Data Handling
Last Updated: 2025-08-29 23:15:47Z

- PII boundaries: Emails and raw names must only appear inside analytics `pii` envelope.
- Logs: No PII (emails/names/phone) in logs; analytics JSONL file contains only validated events without PII in `payload`/`context`.
- DB: `members.email` may be NULL (walk-ins); unique constraint prevents duplicates when present.
- FFI: Functions returning strings document ownership; always free heap strings with `edp_free_cstr`.
- Audit: All status changes should create `status_audit_log` entries with `changed_by` and optional `reason`.
