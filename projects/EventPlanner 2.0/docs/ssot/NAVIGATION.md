# Navigation Contracts (Deep-Linkable)
Last Updated: 2025-08-29 23:15:47Z

## Routes
- `/members` → Members list (global directory)
- `/members/{memberId}` → Member profile (includes event history)
- `/events` → Events list
- `/events/{eventId}` → Event detail (default tab: Overview)
- `/events/{eventId}?tab=attendees` → Event detail Attendees tab
- `/events/{eventId}?tab=attendees&highlight={attendanceId}` → highlight a row

## Behavior
- Switching tabs preserves base route and query params.
- Highlight param auto-focuses row shortly after mount.
- Back/forward restores the previous tab and scroll position.
- Opening Member from Attendee stores return anchor to restore highlight on return.

## Acceptance
- All routes resolve without 404.
- Deep-links land on correct tab with expected context.
- “Open in Event” returns to Attendees tab highlighted.
