# Member Dedupe & Merge
Last Updated: 2025-08-29 23:15:47Z

## Goal
Collapse duplicate members by migrating event attendance from a duplicate member to a primary member and removing the duplicate safely.

## Behavior
- Updates `event_attendance.member_id` from duplicate → primary.
- If moving an attendance would violate the UNIQUE(member_id,event_id) constraint (i.e., both members attended the same event), the duplicate attendance row is deleted to preserve uniqueness.
- Deletes the duplicate row from `members`.
- Logs merge in `member_merge_log(from_member_id, to_member_id, merged_at)`.

## API
- Rust: `merge_members(primaryId, duplicateId) -> moved_count`
- FFI: `edp_merge_members(primaryId, duplicateId) -> long long`
- CLI: `merge-members <primaryId> <duplicateId> [--db <path>]`

## Notes
- Choose the canonical primary based on email or business rules.
- Consider consolidating tags/notes at application level before or after merge.
