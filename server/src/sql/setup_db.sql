CREATE TABLE IF NOT EXISTS users(
    id integer PRIMARY KEY AUTOINCREMENT,
    name text NOT NULL,
    email text UNIQUE NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sessions(
    id text PRIMARY KEY,
    user_id integer NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);

CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);

