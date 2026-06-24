import envoy
import gleam/erlang/process
import gleam/int
import mist
import server/router
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)

  // Read PORT from environment variable, default to 8000
  let port = case envoy.get("PORT") {
    Ok(port_str) ->
      case int.parse(port_str) {
        Ok(p) -> p
        Error(_) -> 8000
      }
    Error(_) -> 8000
  }

  let assert Ok(_) =
    router.handle_request
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(port)
    |> mist.start

  process.sleep_forever()
}
