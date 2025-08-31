# Sync & Realtime — Public Registrations (v1.0)

## Overview
- When Event → Attendees is open, the app brings in new registrations created via the public form.
- Two paths supported: polling and SSE push.

## Polling
- Endpoint: `GET /api/events/:id/registrations?since=<unix>`
- Frequency: ~12s while the page is active.
- Contract: array of rows with at least `email, first_name, last_name, company, updated_at`.
- Merge: convert to CSV and call `EDPCore.csvCommit(eventId:, csvText:)` (idempotent upsert by email).
- After merge: refresh counts; list updates automatically.

## SSE (Push)
- Endpoint: `GET /api/events/:id/registrations/stream`
- Message: JSON registration event (`event_id, email, first_name, last_name, company, attendee_id, member_id`).
- Client: connect on appear; for each event, upsert to local DB (same path as polling merge) and update UI.
- Reconnect: backoff and resume.

## Settings
- AppStorage key: `apiBase` (Settings → Integration).
- Validation: must start with `https://`; the Settings view offers a one‑click Fix.

## Errors
- Network failure: silent retry; show a toast only if debug mode is on.
- Merge failure: record `EDPCore.lastError()`; surface in a non‑blocking banner.

## Audit
- Count of imported items per interval (analytics event `attendee_import_public`).
- SSE connected/disconnected events in debug analytics.

