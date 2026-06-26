import gleam/dynamic/decode
import gleam/list
import server/database
import sqlight

pub type User {
  User(id: String, name: String, hashed_password: String)
}

fn user_decoder() {
  use id <- decode.field(0, decode.string)
  use name <- decode.field(1, decode.string)
  use hashed_password <- decode.field(2, decode.string)
  decode.success(User(id:, name:, hashed_password:))
}

pub fn get_user_from_db(conn: sqlight.Connection, id: String) {
  let sql =
    "
SELECT id, name, hashed_password
FROM users
WHERE id = $1
LIMIT 1;
  "

  let res =
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(id)],
      expecting: user_decoder(),
    )
  case res {
    Ok([v]) -> Ok(v)
    Ok(v) ->
      Error(database.UnexpectedNumberOfRows(limit: 1, got: list.length(v)))
    Error(e) -> Error(database.QueryError(e))
  }
}
