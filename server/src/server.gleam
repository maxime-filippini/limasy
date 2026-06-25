import envoy
import gleam/erlang/process
import gleam/int
import gleam/io
import logging
import mist
import server/database
import server/router
import wisp
import wisp/wisp_mist

const default_port = 1234

pub fn main() {
  wisp.configure_logger()

  // Initialize database (will create and setup if it doesn't exist)
  let _db_conn = case database.initialize() {
    Ok(conn) -> {
      logging.log(logging.Info, "Database initialized successfully")
      conn
    }
    Error(database.ConnectionError(msg)) -> {
      logging.log(logging.Info, "Database connection error: " <> msg)
      panic as "Failed to connect to database"
    }
    Error(database.SetupError(msg)) -> {
      logging.log(logging.Info, "Database setup error: " <> msg)
      panic as "Failed to setup database"
    }
    Error(database.EnvironmentError(msg)) -> {
      logging.log(logging.Info, "Environment error: " <> msg)
      panic as "Database environment configuration error"
    }
  }

  let secret_key_base = wisp.random_string(64)

  let port = case envoy.get("PORT") {
    Ok(port_str) ->
      case int.parse(port_str) {
        Ok(p) -> p
        Error(_) -> default_port
      }
    Error(_) -> default_port
  }

  let assert Ok(_) =
    router.handle_request
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(port)
    |> mist.start

  process.sleep_forever()
}
