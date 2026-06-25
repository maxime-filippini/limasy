import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import server/web
import sqlight
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  echo req

  use _req <- web.middleware(req)

  let path = case wisp.path_segments(req) {
    ["limasy", ..rest] -> rest
    other -> other
  }

  case path {
    ["health"] -> wisp.ok()

    [] -> {
      let body = "<h1>Hello, Joe!</h1>"
      wisp.html_response(body, 200)
    }

    ["data"] -> {
      use conn <- sqlight.with_connection(ctx.db_path)

      process.sleep(1000)

      let sql =
        "
SELECT *
FROM users;
  "

      let assert Ok(res) =
        sqlight.query(sql, on: conn, with: [], expecting: { decode.success(25) })

      wisp.json_response(
        json.object([#("query_result", json.array(res, json.int))])
          |> json.to_string,
        200,
      )
    }

    _ -> wisp.not_found()
  }
}
