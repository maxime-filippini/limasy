import gleam/json
import server/web
import wisp.{type Request, type Response}

/// The HTTP request handler- your application!
///
pub fn handle_request(req: Request) -> Response {
  // Apply the middleware stack for this request/response.
  use _req <- web.middleware(req)

  // Strip the /limasy prefix if present (for Coolify path-based routing)
  let path = case wisp.path_segments(req) {
    ["limasy", ..rest] -> rest
    other -> other
  }

  // Route based on the path
  case path {
    // Health check endpoint for Docker/Coolify
    ["health"] -> wisp.ok()

    // Default route
    [] -> {
      let body = "<h1>Hello, Joe!</h1>"
      wisp.html_response(body, 200)
    }

    ["data"] -> {
      wisp.json_response(
        json.object([#("data", json.int(420))])
          |> json.to_string,
        200,
      )
    }

    // 404 for everything else
    _ -> wisp.not_found()
  }
}
