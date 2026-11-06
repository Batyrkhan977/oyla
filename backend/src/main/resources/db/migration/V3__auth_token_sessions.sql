ALTER TABLE auth_token ADD COLUMN session_id UUID;
UPDATE auth_token SET session_id = id WHERE session_id IS NULL;
ALTER TABLE auth_token ALTER COLUMN session_id SET NOT NULL;
CREATE INDEX auth_token_session_idx ON auth_token(session_id);
