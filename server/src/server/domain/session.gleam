import gleam/dynamic/decode
import gleam/list
import gleam/result
import gleam/time/duration
import gleam/time/timestamp
import server/database
import server/domain/user
import sqlight
import youid/uuid

pub type UserSession {
  UserSession(
    id: uuid.Uuid,
    user_id: String,
    created_at: timestamp.Timestamp,
    expires_at: timestamp.Timestamp,
  )
}

fn timestamp_decoder() {
  use v <- decode.then(decode.string)

  case timestamp.parse_rfc3339(v) {
    Ok(vv) -> decode.success(vv)
    Error(_) ->
      decode.failure(
        timestamp.from_unix_seconds(0),
        "a valid RFC3339 timestamp",
      )
  }
}

fn uuid_decoder() {
  use v <- decode.then(decode.string)

  case uuid.from_string(v) {
    Ok(vv) -> decode.success(vv)
    Error(_) -> decode.failure(uuid.v4(), "a valid UUID")
  }
}

pub fn session_decoder() {
  use id <- decode.field(0, uuid_decoder())
  use user_id <- decode.field(1, decode.string)
  use created_at <- decode.field(2, timestamp_decoder())
  use expires_at <- decode.field(3, timestamp_decoder())

  decode.success(UserSession(id:, user_id:, created_at:, expires_at:))
}

pub fn get_active_session_for_user(conn: sqlight.Connection, user_id: String) {
  let sql =
    "
SELECT id, user_id, created_at, expires_at
FROM sessions
WHERE user_id = $1
  AND expires_at > datetime('now')
ORDER BY expires_at DESC
LIMIT 1;
"

  let res =
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(user_id)],
      expecting: session_decoder(),
    )

  case res {
    Ok([v]) -> Ok(v)
    Ok([]) -> Error(database.NoRecordFound)
    Ok(v) -> Error(database.UnexpectedNumberOfRows(1, list.length(v)))
    Error(e) -> Error(database.QueryError(e))
  }
}

pub fn get_or_create(conn: sqlight.Connection, user: user.User) {
  get_active_session_for_user(conn, user.id)
  |> result.lazy_or(fn() {
    let session = new(user, timestamp.system_time())
    insert_session(conn, session)
    |> result.map(fn(_) { session })
  })
}

pub fn get_session_by_id(conn: sqlight.Connection, id: uuid.Uuid) {
  let sql =
    "
SELECT id, user_id, created_at, expires_at
FROM sessions
WHERE id = $1;    
"

  let res =
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(uuid.to_string(id))],
      expecting: session_decoder(),
    )

  case res {
    Ok([v]) -> Ok(v)
    Ok([]) -> Error(database.NoRecordFound)
    Ok(v) -> Error(database.UnexpectedNumberOfRows(1, list.length(v)))
    Error(e) -> Error(database.QueryError(e))
  }
}

pub fn new(user: user.User, now: timestamp.Timestamp) -> UserSession {
  UserSession(
    id: uuid.v4(),
    user_id: user.id,
    created_at: now,
    expires_at: timestamp.add(now, duration.seconds(60 * 60 * 24)),
  )
}

pub fn insert_session(conn: sqlight.Connection, session: UserSession) {
  let sql =
    "
INSERT INTO sessions (id, user_id, created_at, expires_at)    
VALUES ($1, $2, $3, $4);
"

  sqlight.query(
    sql,
    on: conn,
    with: [
      session.id |> uuid.to_string |> sqlight.text,
      sqlight.text(session.user_id),
      session.created_at
        |> timestamp.to_rfc3339(duration.seconds(0))
        |> sqlight.text,
      session.expires_at
        |> timestamp.to_rfc3339(duration.seconds(0))
        |> sqlight.text,
    ],
    expecting: decode.string,
  )
  |> result.map(fn(_) { Nil })
  |> result.map_error(database.QueryError)
}
