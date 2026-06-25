import envoy
import gleam/bool
import gleam/io
import gleam/list
import gleam/result
import logging
import simplifile
import sqlight

pub type DatabaseError {
  ConnectionError(String)
  SetupError(String)
  EnvironmentError(String)
  SetupScriptNotFound(String)
  FileError(String)
}

pub const default_database_path = "./data/database.db"

pub fn get_database_path() {
  case envoy.get("DATABASE_PATH") {
    Ok(path) -> path
    Error(_) -> {
      io.println(
        "WARNING: DATABASE_PATH not set, using default: ./data/database.db",
      )
      "./data/database.db"
    }
  }
}

pub fn initialize(
  path_setup_scripts: List(String),
) -> Result(Nil, DatabaseError) {
  let db_path = case envoy.get("DATABASE_PATH") {
    Ok(path) -> path
    Error(_) -> {
      logging.log(
        logging.Warning,
        "WARNING: DATABASE_PATH not set, using default: ./data/database.db",
      )
      default_database_path
    }
  }

  logging.log(logging.Info, "Checking database at: " <> db_path)

  let db_exists = case simplifile.is_file(db_path) {
    Ok(True) -> True
    Ok(False) -> False
    Error(_) -> False
  }

  case db_exists {
    False -> {
      logging.log(
        logging.Info,
        "Database not found. Creating new database and running setup...",
      )

      use conn <- sqlight.with_connection(db_path)
      use _ <- result.try(run_setup(conn, path_setup_scripts))
      io.println("Database setup completed successfully")
      Ok(Nil)
    }
    True -> {
      logging.log(logging.Info, "Database found.")
      Ok(Nil)
    }
  }
}

fn load_script_and_exec(
  path: String,
  conn: sqlight.Connection,
) -> Result(Nil, DatabaseError) {
  use is_file <- result.try(
    simplifile.is_file(path) |> result.map_error(fn(_) { FileError(path) }),
  )
  use <- bool.guard(!is_file, Error(SetupScriptNotFound(path)))

  use sql <- result.try(
    simplifile.read(path) |> result.map_error(fn(_) { FileError(path) }),
  )

  case sqlight.exec(sql, conn) {
    Ok(_) -> {
      logging.log(logging.Info, "Executed setup script successfully: " <> path)
      Ok(Nil)
    }
    Error(_err) -> {
      Error(SetupError("Failed to run setup script: " <> path))
    }
  }
}

fn run_setup(
  conn: sqlight.Connection,
  path_setup_scripts: List(String),
) -> Result(Nil, DatabaseError) {
  io.println("Running database setup script...")

  list.map(path_setup_scripts, load_script_and_exec(_, conn))
  |> result.all
  |> result.map(fn(_) { Nil })
}
