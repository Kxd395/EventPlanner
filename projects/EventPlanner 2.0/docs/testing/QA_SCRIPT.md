# QA Script — Phase 1 Acceptance
Last Updated: 2025-08-29 23:15:47Z

## A. Attendee Editing & Linking
- Open Events list → select an event → Attendees tab
- Click a row → side panel opens
- Edit Contact (name/email/company) → Save → Verify change on Members profile
- Edit Participation (status/ticket/seat/notes) → Save → Verify scoped to event only
- Click “Open Member Profile” → navigate to Members with event history
- From Member profile click “Open in Event” → back to Attendees with highlight

## B. Status Transitions & Safeguards
- Pre‑Registered → Checked‑In → OK (no confirmation)
- Checked‑In → Pre‑Registered → Reason dialog required
- During event: Any → DNA → Requires manager override
- Bulk early DNA (select several) → Manager override confirmation

## C. CSV Import Preview / Commit
- Import CSV with duplicates and 2 errors
- Preview shows totals, duplicates list, and errors link
- Commit applies valid rows only; errors available for download

## D. Keyboard & A11y
- / focuses search; A adds attendee; W opens walk‑in; Esc closes panel
- Tab order logical; status buttons have accessible labels

## E. Analytics
- Trigger actions and verify analytics payload passes validator (no PII outside `pii`)
