#ifndef EVENTDESK_CORE_H
#define EVENTDESK_CORE_H

#include <stdbool.h>
#include <stdint.h>

// Status codes (must match Rust order)
// 0=preregistered, 1=walkin, 2=checkedin, 3=dna

#ifdef __cplusplus
extern "C" {
#endif

// Returns -1 on unknown
int edp_status_from_str(const char* status_str);
// Returns code string (UTF-8) for a status code (0..3); NULL on invalid.
// NOTE: Returned pointer is owned by the library and must NOT be freed.
const char* edp_status_to_str(int code);
// Returns human label (UTF-8) for a status code (0..3); NULL on invalid.
// NOTE: Returned pointer is owned by the library and must NOT be freed.
const char* edp_status_label(int code);

// Normalize free-form status string to canonical code; -1 if unknown.
int edp_normalize_status(const char* status_str);

// Returns: 0=OK, 1=NeedsReason, 2=NeedsManagerOverride
int edp_validate_transition(int current_status,
                            int new_status,
                            bool event_in_progress,
                            bool has_manager_override);

// Returns 1 if event_end_epoch_s + grace_seconds <= now_epoch_s (UTC), else 0.
int edp_auto_rollover_due(int64_t event_end_epoch_s,
                          int64_t grace_seconds,
                          int64_t now_epoch_s);

// CSV preview (UTF-8 text). Returns heap-allocated JSON string; free with edp_free_cstr.
char* edp_csv_preview_utf8(const char* csv_text_utf8);
void edp_free_cstr(char* ptr);

// Analytics validation and emit (returns 1 if accepted, else 0)
int edp_analytics_validate(const char* json_utf8);
int edp_analytics_emit(const char* json_utf8);
int edp_set_analytics_path(const char* path_utf8); // returns 1 if set

// CSV commit stub: input is preview JSON (from edp_csv_preview_utf8),
// returns JSON: { "rowsImported": <u64>, "rowsErrored": <u64> }
char* edp_csv_commit_preview_json(const char* preview_json_utf8);

// DB-backed operations
int edp_set_db_path(const char* db_path_utf8); // returns 1 if set, else 0
char* edp_csv_commit_for_event(const char* event_id_utf8, const char* csv_text_utf8); // JSON {rowsImported, rowsErrored, duplicates}
char* edp_last_error_message(void); // Get and clear last error message (heap string; free with edp_free_cstr)
char* edp_csv_export_for_event(const char* event_id_utf8); // CSV string; free with edp_free_cstr
char* edp_counts_by_status(const char* event_id_utf8); // JSON counts {preregistered,walkin,checkedin,dna}
long long edp_process_auto_rollover(const char* event_id_utf8, long long event_end_epoch_s, long long now_epoch_s, long long grace_seconds);
char* edp_list_attendance(const char* event_id_utf8); // JSON array of attendees
int edp_remove_attendance(const char* attendance_id_utf8, const char* reason_utf8_or_null, const char* changed_by_utf8_or_null);
char* edp_search_members(const char* query_utf8, int limit); // JSON array of members
char* edp_create_walkin(const char* event_id_utf8, const char* name_utf8, const char* email_utf8_or_null, const char* phone_utf8_or_null, const char* company_utf8_or_null, bool immediate_checkin, const char* changed_by_utf8_or_null);
long long edp_merge_members(const char* primary_member_id_utf8, const char* duplicate_member_id_utf8);
char* edp_create_event(const char* id_utf8_or_null, const char* name_utf8, const char* starts_at_utf8, const char* ends_at_utf8, const char* location_utf8_or_null, long long capacity_or_zero, const char* status_utf8_or_null, const char* timezone_utf8_or_null, const char* description_utf8_or_null);
int edp_update_event(const char* id_utf8, const char* name_utf8_or_null, const char* starts_at_utf8_or_null, const char* ends_at_utf8_or_null, const char* location_utf8_or_null, long long capacity_or_zero, const char* status_utf8_or_null, const char* timezone_utf8_or_null, const char* description_utf8_or_null);
char* edp_list_events(long long limit, long long offset);
int edp_update_status(const char* attendance_id_utf8,
                      const char* new_status_utf8,
                      bool event_in_progress,
                      bool has_manager_override,
                      const char* reason_utf8_or_null,
                      const char* changed_by_utf8_or_null);
// Members (create)
char* edp_create_member(const char* email_utf8_or_null,
                        const char* first_utf8,
                        const char* last_utf8,
                        const char* phone_utf8_or_null,
                        const char* company_utf8_or_null,
                        const char* tags_utf8_or_null,
                        const char* notes_utf8_or_null);
// Additional APIs
char* edp_member_profile(const char* member_id_utf8); // JSON profile; free with edp_free_cstr
long long edp_bulk_status_update(const char* event_id_utf8,
                                 const char* attendee_ids_csv_utf8,
                                 const char* new_status_utf8,
                                 bool event_in_progress,
                                 bool has_manager_override,
                                 const char* reason_utf8_or_null,
                                 const char* changed_by_utf8_or_null);

// Migration checks
long long edp_status_v2_nulls(const char* event_id_utf8);
long long edp_status_v2_backfill(const char* event_id_utf8);
int edp_update_member(const char* id_utf8,
                      const char* email_utf8_or_null,
                      const char* first_utf8_or_null,
                      const char* last_utf8_or_null,
                      const char* phone_utf8_or_null,
                      const char* company_utf8_or_null,
                      const char* tags_utf8_or_null,
                      const char* notes_utf8_or_null);

// Version and SSOT helpers
const char* edp_core_version(void); // static string, do not free
int edp_validate_status_code(const char* status_str); // 1 if valid canonical, else 0
int edp_ssot_status_count(void); // 4
const char* edp_ssot_status_code_at(int idx); // static string or NULL

#ifdef __cplusplus
}
#endif

#endif // EVENTDESK_CORE_H
