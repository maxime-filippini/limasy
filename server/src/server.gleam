import envoy
import gleam/erlang/process
import gleam/int
import mist
import server/dotenv
import server/router
import server/web
import wisp
import wisp/wisp_mist

const default_port = 1234

pub type Mode {
  Local
  Dev
  Prod
}

pub fn main() {
  wisp.configure_logger()

  let assert Ok(_) = case envoy.get("LIMASY_MODE") {
    Ok(v) ->
      case v {
        "local" -> {
          let assert Ok(_) = dotenv.load(".env")
          Ok(Local)
        }

        "dev" -> Ok(Dev)
        "prod" -> Ok(Prod)
        _ -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }

  let assert Ok(secret_key_base) = envoy.get("SECRET_KEY_BASE")
  let port = get_port()

  let assert Ok(db_path) = envoy.get("DATABASE_PATH")
  let assert Ok(hashed_pw) = envoy.get("PASSWORD")

  let ctx = web.Context(db_path, hashed_pw:)

  let assert Ok(_) =
    router.handle_request(_, ctx)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(port)
    |> mist.start

  process.sleep_forever()
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
