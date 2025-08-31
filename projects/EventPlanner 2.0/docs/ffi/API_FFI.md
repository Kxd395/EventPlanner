# FFI API Index
Last Updated: 2025-08-29 23:15:47Z

- Status
  - `edp_status_from_str(const char*) -> int`
  - `edp_status_to_str(int) -> const char*` (static)
  - `edp_status_label(int) -> const char*` (static)
  - `edp_validate_status_code(const char*) -> int`
  - `edp_ssot_status_count() -> int`
  - `edp_ssot_status_code_at(int) -> const char*` (static)

- Validation & Transitions
  - `edp_validate_transition(int current, int new, bool inProgress, bool override) -> int`
  - `edp_update_status(const char* attendanceId, const char* newStatus, bool inProgress, bool override, const char* reasonOrNull, const char* changedByOrNull) -> int`

- CSV
  - `edp_csv_preview_utf8(const char*) -> char*` (free with `edp_free_cstr`)
  - `edp_csv_commit_preview_json(const char*) -> char*` (free)
  - `edp_set_db_path(const char*) -> int`
  - `edp_csv_commit_for_event(const char* eventId, const char* csvText) -> char*` (free)
  - `edp_csv_export_for_event(const char* eventId) -> char*` (free)
  - `edp_counts_by_status(const char* eventId) -> char*` (free)
  - `edp_export_json_for_event(const char* eventId) -> char*` (free)
  - `edp_list_status_audit(const char* eventIdOrNull, const char* attendeeIdOrNull, long long limit) -> char*` (free)
  - `edp_bulk_status_update(const char* eventId, const char* attendeeIdsCsv, const char* newStatus, bool inProgress, bool override, const char* reasonOrNull, const char* changedByOrNull) -> long long`

- Analytics
  - `edp_analytics_validate(const char*) -> int`
  - `edp_analytics_emit(const char*) -> int`
  - `edp_set_analytics_path(const char*) -> int`

- Misc
  - `edp_core_version() -> const char*` (static)
  - `edp_free_cstr(char*)`
  - `edp_last_error_message() -> char*` (free)
  - `edp_delete_event(const char* eventId) -> long long`
  - `edp_member_profile(const char* memberId) -> char*` (free)
  - `edp_create_event(...) -> char*` (free), `edp_update_event(...) -> int`, `edp_list_events(long long,long long) -> char*` (free)
