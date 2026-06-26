import argus
import gleam/bool
import gleam/dynamic/decode
import gleam/http
import gleam/json
import server/auth
import server/domain/session
import server/domain/user
import server/web
import sqlight
import wisp.{type Request, type Response}
import youid/uuid

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

    http.Post, ["sign-in"] -> {
      use dyna <- wisp.require_json(req)

      let decoder = {
        use user <- decode.field("user", decode.string)
        use password <- decode.field("password", decode.string)
        decode.success(#(user, password))
      }

      use #(user_id, password) <- web.try(decode.run(dyna, decoder), fn(_) {
        wisp.unprocessable_content()
      })

      let maybe_user = {
        use conn <- sqlight.with_connection(ctx.db_path)
        user.get_user_from_db(conn, user_id)
      }

      use user <- web.try(maybe_user, fn(_) { wisp.not_found() })

      let maybe_verified_password = argus.verify(user.hashed_password, password)

      use is_good_password <- web.try(maybe_verified_password, fn(_) {
        wisp.response(500)
      })

      use <- bool.guard(!is_good_password, wisp.response(401))

      let maybe_session = {
        use conn <- sqlight.with_connection(ctx.db_path)
        session.get_or_create(conn, user)
      }

      use session <- web.try(maybe_session, fn(_) {
        wisp.internal_server_error()
      })

      let body =
        json.object([#("session", json.string(uuid.to_string(session.id)))])
        |> json.to_string

      wisp.json_response(body, 200)
    }

    // Protected route
    http.Get, ["data"] -> {
      use user <- auth.require_user(req, ctx)

      echo user

      wisp.json_response(
        json.object([
          #("query_result", json.array([1, 2, 3, 4, 5, 6, 7], json.int)),
        ])
          |> json.to_string,
        200,
      )
    }
    _, _ -> wisp.not_found()
  }
}
