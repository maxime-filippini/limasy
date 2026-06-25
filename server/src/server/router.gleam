import argus
import gleam/dynamic/decode
import gleam/http
import server/web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  use _req <- web.middleware(req)

  let path = case wisp.path_segments(req) {
    ["limasy", ..rest] -> rest
    other -> other
  }

  case req.method, path {
    http.Get, ["health"] -> wisp.ok()

    http.Get, [] -> {
      let body = "<h1>Hello, Joe!</h1>"
      wisp.html_response(body, 200)
    }

    http.Post, ["auth", "check"] -> {
      use password <- web.require_cookie(req, "limasy-auth", wisp.Signed, fn() {
        wisp.bad_request("No auth cookie found")
      })

      case argus.verify(ctx.hashed_pw, password) {
        Ok(True) -> wisp.html_response("OK", 200)
        Ok(False) -> wisp.response(401)
        Error(_) -> wisp.internal_server_error()
      }
    }

    http.Post, ["sign-in"] -> {
      use dyna <- wisp.require_json(req)

      case decode.run(dyna, decode.string) {
        Ok(s) -> {
          case argus.verify(ctx.hashed_pw, s) {
            Ok(True) -> {
              wisp.html_response("OK", 200)
              |> wisp.set_cookie(
                req,
                "limasy-auth",
                s,
                wisp.Signed,
                max_age: 24 * 60 * 60,
              )
            }
            Ok(False) -> wisp.response(401)
            Error(e) -> {
              echo e
              wisp.internal_server_error()
            }
          }
        }
        Error(_) -> wisp.unprocessable_content()
      }
    }

    //     ["data"] -> {
    //       use conn <- sqlight.with_connection(ctx.db_path)
    //       process.sleep(1000)
    //       let sql =
    //         "
    // SELECT *
    // FROM users;
    //   "
    //       let assert Ok(res) =
    //         sqlight.query(sql, on: conn, with: [], expecting: { decode.success(25) })
    //       wisp.json_response(
    //         json.object([#("query_result", json.array(res, json.int))])
    //           |> json.to_string,
    //         200,
    //       )
    //     }
    _, _ -> wisp.not_found()
  }
}
