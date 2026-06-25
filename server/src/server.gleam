import envoy
import gleam/erlang/process
import gleam/int
import logging
import mist
import server/database
import server/router
import server/web
import wisp
import wisp/wisp_mist

const default_port = 1234

const path_setup_scripts = ["./src/setup_db.sql"]

pub fn main() {
  wisp.configure_logger()

  let assert Ok(_) = setup_database()
  let secret_key_base = wisp.random_string(64)
  let port = get_port()

  let assert Ok(db_path) = envoy.get("DATABASE_PATH")

  let ctx = web.Context(db_path)

  let assert Ok(_) =
    router.handle_request(_, ctx)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(port)
    |> mist.start

  process.sleep_forever()
}

fn setup_database() {
  let maybe_init = database.initialize(path_setup_scripts)
  case maybe_init {
    Ok(_) -> {
      logging.log(logging.Info, "Database initialized successfully")
    }
    Error(database.ConnectionError(msg)) -> {
      logging.log(logging.Error, "Database connection error: " <> msg)
    }
    Error(database.SetupError(msg)) -> {
      logging.log(logging.Error, "Database setup error: " <> msg)
    }
    Error(database.EnvironmentError(msg)) -> {
      logging.log(logging.Error, "Environment error: " <> msg)
    }
    Error(database.SetupScriptNotFound(s)) ->
      logging.log(logging.Error, "Setup script not found: " <> s)
    Error(database.FileError(s)) ->
      logging.log(logging.Error, "Error attempting to read file: " <> s)
  }

  maybe_init
}

fn get_port() {
  case envoy.get("PORT") {
    Ok(port_str) ->
      case int.parse(port_str) {
        Ok(p) -> p
        Error(_) -> default_port
      }
    Error(_) -> default_port
  }
}
