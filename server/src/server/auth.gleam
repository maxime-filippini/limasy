import gleam/bool
import gleam/http/request
import gleam/list
import gleam/order
import gleam/result
import gleam/time/timestamp
import server/database
import server/domain/session
import server/domain/user
import server/web
import sqlight
import wisp
import youid/uuid

pub type Error {
  NoAuthCookieFound
  InvalidUuidInCookie
  DatabaseError(database.DatabaseError)
  ExpiredSession
  UserNotFound
}

pub fn require_user(
  req: wisp.Request,
  ctx: web.Context,
  next: fn(user.User) -> wisp.Response,
) -> wisp.Response {
  case get_user(req, ctx) {
    Ok(user) -> next(user)
    Error(UserNotFound) -> wisp.response(404)
    Error(NoAuthCookieFound) -> wisp.response(401)
    Error(InvalidUuidInCookie) -> wisp.response(401)
    Error(DatabaseError(_)) -> wisp.response(500)
    Error(ExpiredSession) -> wisp.response(401)
  }
}

pub fn get_user(req: wisp.Request, ctx: web.Context) -> Result(user.User, Error) {
  let maybe_cookie =
    request.get_cookies(req)
    |> list.key_find("limasy-auth")

  use cookie <- result.try(
    maybe_cookie |> result.map_error(fn(_) { NoAuthCookieFound }),
  )
  use uuid <- result.try(
    uuid.from_string(cookie) |> result.map_error(fn(_) { InvalidUuidInCookie }),
  )

  let maybe_session = {
    use conn <- sqlight.with_connection(ctx.db_path)
    session.get_session_by_id(conn, uuid)
  }

  use session <- result.try(maybe_session |> result.map_error(DatabaseError))

  let is_expired = case
    timestamp.compare(timestamp.system_time(), session.expires_at)
  {
    order.Lt -> False
    order.Eq -> True
    order.Gt -> True
  }

  use <- bool.guard(is_expired, Error(ExpiredSession))

  let maybe_user = {
    use conn <- sqlight.with_connection(ctx.db_path)
    user.get_user_from_db(conn, session.user_id)
  }

  maybe_user
  |> result.map_error(DatabaseError)
}
