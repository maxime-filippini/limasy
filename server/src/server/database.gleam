import envoy
import gleam/io
import gleam/result
import simplifile
import sqlight

pub type DatabaseError {
  ConnectionError(String)
  SetupError(String)
  EnvironmentError(String)
}

/// Initialize the database connection. If the database doesn't exist,
/// it will be created and the setup script will be run.
pub fn initialize() -> Result(sqlight.Connection, DatabaseError) {
  // Get database path from environment variable
  let db_path = case envoy.get("DATABASE_PATH") {
    Ok(path) -> path
    Error(_) -> {
      io.println(
        "WARNING: DATABASE_PATH not set, using default: ./data/database.db",
      )
      "./data/database.db"
    }
  }

  io.println("Checking database at: " <> db_path)

  // Check if database exists
  let db_exists = case simplifile.is_file(db_path) {
    Ok(True) -> True
    Ok(False) -> False
    Error(_) -> False
  }

  case db_exists {
    False -> {
      io.println("Database not found. Creating new database and running setup...")
      create_and_setup(db_path)
    }
    True -> {
      io.println("Database found. Connecting...")
      connect(db_path)
    }
  }
}

/// Connect to an existing database
fn connect(db_path: String) -> Result(sqlight.Connection, DatabaseError) {
  case sqlight.open(db_path) {
    Ok(conn) -> {
      io.println("Successfully connected to database")
      Ok(conn)
    }
    Error(_err) -> {
      Error(ConnectionError("Failed to connect to database at " <> db_path))
    }
  }
}

/// Create a new database and run the setup script
fn create_and_setup(db_path: String) -> Result(sqlight.Connection, DatabaseError) {
  // Open connection (this will create the database file)
  use conn <- result.try(case sqlight.open(db_path) {
    Ok(conn) -> Ok(conn)
    Error(_err) ->
      Error(ConnectionError("Failed to create database at " <> db_path))
  })

  // Run setup script
  use _ <- result.try(run_setup(conn))

  io.println("Database setup completed successfully")
  Ok(conn)
}

/// Run the database setup script to create tables and initial data
fn run_setup(conn: sqlight.Connection) -> Result(Nil, DatabaseError) {
  io.println("Running database setup script...")

  // Example schema - you can customize this based on your needs
  let setup_sql =
    "
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS sessions (
      id TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      expires_at TIMESTAMP NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id)
    );

    CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
    CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);
  "

  case sqlight.exec(setup_sql, conn) {
    Ok(_) -> {
      io.println("Database schema created successfully")
      Ok(Nil)
    }
    Error(_err) -> {
      Error(SetupError("Failed to run setup script - SQL execution error"))
    }
  }
}
