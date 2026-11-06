CREATE TABLE app_user (
    id UUID PRIMARY KEY,
    email VARCHAR(320) NOT NULL UNIQUE,
    nickname VARCHAR(80),
    status VARCHAR(20) NOT NULL,
    locale VARCHAR(16) NOT NULL DEFAULT 'en',
    timezone VARCHAR(64) NOT NULL DEFAULT 'UTC',
    settings_json TEXT NOT NULL DEFAULT '{}',
    settings_updated_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    last_sign_in_at TIMESTAMPTZ
);
CREATE TABLE login_code (
    id UUID PRIMARY KEY,
    email VARCHAR(320) NOT NULL,
    code_hash VARCHAR(64) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX login_code_email_created_idx ON login_code(email, created_at DESC);
CREATE TABLE auth_token (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    kind VARCHAR(16) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX auth_token_hash_idx ON auth_token(token_hash);
CREATE TABLE workout (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    installation_id UUID NOT NULL,
    local_date DATE NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    completion_state VARCHAR(20) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX workout_user_changed_idx ON workout(user_id, changed_at);
CREATE TABLE exercise_result (
    id UUID PRIMARY KEY,
    workout_id UUID REFERENCES workout(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    installation_id UUID NOT NULL,
    exercise_type VARCHAR(32) NOT NULL,
    difficulty INTEGER NOT NULL,
    algorithm_version INTEGER NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL,
    correct_count INTEGER NOT NULL,
    attempted_count INTEGER NOT NULL,
    score INTEGER NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT result_counts_valid CHECK (correct_count >= 0 AND attempted_count >= correct_count),
    CONSTRAINT result_score_valid CHECK (score BETWEEN 0 AND 100),
    CONSTRAINT result_difficulty_valid CHECK (difficulty BETWEEN 1 AND 10)
);
CREATE INDEX result_user_changed_idx ON exercise_result(user_id, changed_at);
