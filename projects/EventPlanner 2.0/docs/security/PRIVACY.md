# Privacy Summary
Last Updated: 2025-08-29 23:15:47Z

- Analytics schema separates PII into the `pii` object; no PII in `payload` or `context`.
- CSV imports may include emails and names; these are stored in the database per SSOT schema.
- Exports include contact fields required for operational use; be mindful when sharing exported files.
- No PII is written to console logs or error messages.
