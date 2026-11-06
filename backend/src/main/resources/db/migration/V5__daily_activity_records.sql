-- Retain historical friend codes while stopping code generation for new users.
ALTER TABLE app_user ALTER COLUMN friend_code DROP NOT NULL;
CREATE TABLE day_record (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    kind VARCHAR(32) NOT NULL,
    record_id VARCHAR(240) NOT NULL,
    payload TEXT NOT NULL,
    revision BIGINT NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT day_record_owner_key UNIQUE(user_id,kind,record_id)
);
CREATE INDEX day_record_user_changed ON day_record(user_id,changed_at);
