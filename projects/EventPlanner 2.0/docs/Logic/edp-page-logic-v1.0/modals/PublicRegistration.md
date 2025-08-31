# Modal — Public Registration (QR Link)

## What you see
- Toggle to **Enable public registration** for this event.
- TTL picker (15m, 1h, 1d, 1w, custom).
- **Generate** button → shows **Signed URL** and **QR code**.
- Controls: **Copy Link**, **Save PNG**, **Regenerate** secret.
- Note: Submissions create **Pre‑Registered** attendees (or per‑event default).

## Trigger → Logic → Outcome (TLO)
| Trigger | Logic | Outcome |
|---|---|---|
| Enable | Requires event not Cancelled; respects org policy. | Generates/activates a signed URL. |
| Generate | HMAC(secret, eventId, ttl, issuedAt). | URL + QR shown; expiry timestamp displayed. |
| Rotate secret | Invalidate old links; issue new signature. | Previous links stop working; audit “rotation”. |

## Security
- Signatures include event ID, expiry, and nonce; server verifies and rate-limits.
- Form submissions verify email ownership if opt-in is set (email OTP).

## Storage
- App stores per‑event secret in macOS Keychain (service `com.eventdesk.public.secret`, account = eventId) with a UserDefaults fallback.
- Backend stores `events.public_secret` for verification.
