import gleam/bool
import gleam/result
import gleam/string
import simplifile
import wisp

pub opaque type Path {
  Path(raw: String)
}

pub fn db_path(s: String) {
  use <- bool.guard(!string.ends_with(s, ".db"), Error(Nil))

  use is_file <- result.try(
    simplifile.is_file(s) |> result.map_error(fn(_) { Nil }),
  )

  use <- bool.guard(!is_file, Error(Nil))

  Ok(Path(s))
}

pub type Context {
  Context(db_path: String)
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- wisp.csrf_known_header_protection(req)
  handle_request(req)
}

pub fn require_cookie(
  req: wisp.Request,
  name: String,
  security: wisp.Security,
  if_error: fn() -> wisp.Response,
  next: fn(String) -> wisp.Response,
) -> wisp.Response {
  case wisp.get_cookie(req, name, security) {
    Ok(v) -> next(v)
    Error(_) -> if_error()
  }
}

pub fn try(res: Result(a, e), if_error: fn(e) -> b, next: fn(a) -> b) -> b {
  case res {
    Ok(v) -> next(v)
    Error(e) -> if_error(e)
  }
}
