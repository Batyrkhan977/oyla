ALTER TABLE app_user ADD COLUMN friend_code VARCHAR(10);
UPDATE app_user
SET friend_code = UPPER(SUBSTRING(REPLACE(gen_random_uuid()::text, '-', '') FROM 1 FOR 10));
ALTER TABLE app_user ALTER COLUMN friend_code SET NOT NULL;
ALTER TABLE app_user ADD CONSTRAINT app_user_friend_code_unique UNIQUE (friend_code);

ALTER TABLE exercise_result ADD COLUMN local_date DATE;
UPDATE exercise_result SET local_date = (completed_at AT TIME ZONE 'UTC')::date;
ALTER TABLE exercise_result ALTER COLUMN local_date SET NOT NULL;

CREATE TABLE friendship (
    id UUID PRIMARY KEY,
    first_user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    second_user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    requested_by_user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    status VARCHAR(16) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT friendship_distinct_users CHECK (first_user_id <> second_user_id),
    CONSTRAINT friendship_canonical_order CHECK (first_user_id::text < second_user_id::text),
    CONSTRAINT friendship_requester_is_member CHECK (requested_by_user_id IN (first_user_id, second_user_id)),
    CONSTRAINT friendship_status_valid CHECK (status IN ('PENDING', 'ACCEPTED')),
    CONSTRAINT friendship_pair_unique UNIQUE (first_user_id, second_user_id)
);
CREATE INDEX friendship_first_user_idx ON friendship(first_user_id);
CREATE INDEX friendship_second_user_idx ON friendship(second_user_id);
