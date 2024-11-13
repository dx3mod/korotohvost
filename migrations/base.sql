CREATE TABLE IF NOT EXISTS aliases (
    alias TEXT UNIQUE NOT NULL,
    original_url TEXT NOT NULL,
	clicks INTEGER DEFAULT 0,
	expire_at DATETIME
);

CREATE INDEX IF NOT EXISTS idx_aliases ON aliases (alias);

CREATE TRIGGER IF NOT EXISTS remove_expired_aliases
BEFORE INSERT ON aliases
BEGIN
    DELETE FROM aliases WHERE expire_at < DATETIME(current_timestamp, 'localtime');
END;