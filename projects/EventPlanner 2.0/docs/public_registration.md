Public Registration via QR + Web Form

Overview
- Generate a signed, time-limited URL for each event
- Render a QR code in-app for share/print
- Host a minimal web form that POSTs JSON to your endpoint
- Backend verifies HMAC, de-dupes by email/phone, upserts Member, links Attendee with status preregistered

Files in this repo
- apps/EventDeskProApp/Sources/Views/Components/PublicRegistrationQRView.swift
  - SwiftUI modal that creates the signed URL, shows the QR, copy/save actions
- samples/public_form/index.html
  - Static HTML form posting to /api/events/:id/registrations
- samples/backend/axum_register.rs
  - Minimal Axum handler verifying HMAC and returning a stub response

Signed URL format
- Base: https://r.eventdesk.pro/e/<eventId>
- Query: t=<HMAC-SHA256 base64url>, exp=<unix-seconds>
- Message: "<eventId>|<exp>" signed with per-event secret

Secret storage
- Default (app): per-event secret is stored in the macOS Keychain (service: `com.eventdesk.public.secret`, account: `<eventId>`), with a safe fallback to UserDefaults key `eventPublicSecret_<eventId>` if Keychain writes fail.
- Server (backend): persist the same secret in your DB (e.g., `events.public_secret`) and verify tokens server-side.

Swift (generate link + QR)
- See PublicRegistrationQRView.swift for drop-in code

Form contract
POST /api/events/:id/registrations
Body (JSON):
{
  "event_id": "evt_x7T39",
  "token": "HMAC_BASE64URL",
  "exp": 1735651200,
  "first_name": "Ava",
  "last_name": "Chen",
  "email": "ava@example.com",
  "phone": "+1 555 000 1111",
  "company": "Orbit Labs",
  "consent": { "email": true }
}

201 Created:
{ "status":"ok", "attendee_id":"att_9L8", "member_id":"mem_3K2", "state":"preregistered" }

Backend options
- Self-hosted: samples/backend/axum_register.rs (Rust, Axum)
- Serverless: replicate the same logic (token verify, upsert, link) on your platform of choice

App updates
- Poll every 10–15s for new registrations for the active event, or use push via SSE/WebSocket.
- New rows appear as preregistered and increment counters

Realtime (sample)
- Polling: GET `/api/events/:id/registrations?since=<unix>` returns minimal rows (email, first_name, last_name, company)
- Push: SSE at GET `/api/events/:id/registrations/stream` emits registration events as JSON; subscribe in the app to avoid polling.

Security & abuse controls
- Signed URL with TTL
- Email/phone de-dupe, optional confirm email
- Rate-limit (IP), add CAPTCHA on bursts

Next steps (smallest slice)
1) Store per-event public_secret in DB
2) Wire the QR modal into Event Overview
3) Stand up POST /registrations endpoint (verify token, write to DB)
4) Add de-dupe (email/phone), status = preregistered
5) App: poll updated registrations while event open
