# EventDeskPro — Repository Overview

Last Updated: 2025-08-29 23:15:47Z

Docs have been reorganized into subfolders under `docs/` (UI, SSOT, DB, Swift, etc.). See the docs hub for entry points and categories:

- Docs Hub: docs/README.md
- Progress: docs/progress/PROGRESS.md
- SSOT: docs/ssot/SSOT.md

Note for contributors: If you had older links to paths like `docs/PROGRESS.md` or `docs/SCHEMA.sql`, they have moved to `docs/progress/PROGRESS.md` and `docs/db/SCHEMA.sql` respectively.

## Exports v1.4

- Added Export menu with formats: CSV, JSON, Markdown (.md), Plain text (.txt).
- Scope options: All, Filtered, Selected.
- Unified schema: `id, eventId, name, email, phone, status, confirmed, checkedInAt, dnaAt, createdAt, tags, notes`.
- macOS save: uses a default filename `eventName_YYYY-MM-DD_attendees.ext` and opens the file.
- Role-based redaction (optional): if PII export is restricted, CSV/JSON are disabled and Markdown/Text include only non-PII columns (e.g., Name, Status, Checked-In At).

