-- Settings is a single row.
INSERT INTO "settings" ("id") VALUES (1) ON CONFLICT DO NOTHING;
--> statement-breakpoint
ALTER TABLE "settings" ADD CONSTRAINT "settings_singleton" CHECK ("id" = 1);
--> statement-breakpoint
-- The audit log is append-only: block UPDATE and DELETE for every role.
CREATE OR REPLACE FUNCTION audit_log_immutable() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit_log is append-only';
END;
$$ LANGUAGE plpgsql;
--> statement-breakpoint
CREATE TRIGGER audit_log_no_update BEFORE UPDATE OR DELETE ON "audit_log"
  FOR EACH ROW EXECUTE FUNCTION audit_log_immutable();
--> statement-breakpoint
CREATE TRIGGER audit_log_no_truncate BEFORE TRUNCATE ON "audit_log"
  FOR EACH STATEMENT EXECUTE FUNCTION audit_log_immutable();
