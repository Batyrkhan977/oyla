CREATE TABLE connect_settings (
 id UUID PRIMARY KEY REFERENCES app_user(id) ON DELETE CASCADE,
 enabled BOOLEAN NOT NULL DEFAULT FALSE, share_activity BOOLEAN NOT NULL DEFAULT FALSE,
 show_streak BOOLEAN NOT NULL DEFAULT TRUE, freezes INTEGER NOT NULL DEFAULT 0,
 earned_freezes INTEGER NOT NULL DEFAULT 0,
 frozen_days TEXT NOT NULL DEFAULT '', last_invite_at TIMESTAMPTZ, last_gift_at TIMESTAMPTZ
);
CREATE TABLE family_subscription (
 id UUID PRIMARY KEY, owner_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
 recipient VARCHAR(255) NOT NULL, inactivity_days INTEGER NOT NULL CHECK(inactivity_days BETWEEN 2 AND 30),
 weekly BOOLEAN NOT NULL, enabled BOOLEAN NOT NULL, unsubscribed BOOLEAN NOT NULL DEFAULT FALSE,
 unsubscribe_token UUID NOT NULL UNIQUE, consent_at TIMESTAMPTZ NOT NULL,
 last_inactivity_sent TIMESTAMPTZ, last_weekly_sent TIMESTAMPTZ,
 UNIQUE(owner_id,recipient)
);
CREATE TABLE connect_challenge (
 id UUID PRIMARY KEY, owner_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
 friend_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
 type VARCHAR(255) NOT NULL, status VARCHAR(255) NOT NULL,
 start_date DATE NOT NULL, end_date DATE NOT NULL, goal INTEGER NOT NULL
);
