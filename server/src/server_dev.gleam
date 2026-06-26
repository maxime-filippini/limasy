import argus
import argv
import gleam/io
import gleam/time/timestamp
import server/domain/session
import server/domain/user
import sqlight

pub fn main() {
  case argv.load().arguments {
    ["hash", pw] -> {
      let assert Ok(hashes) =
        argus.hasher()
        |> argus.hash(pw, argus.gen_salt())

      io.println(hashes.encoded_hash)
    }
    ["test"] -> {
      use conn <- sqlight.with_connection("./data/database.db")

      let assert Ok(user) = user.get_user_from_db(conn, "maxime")

      let session = session.new(user, timestamp.system_time())

      let _ =
        session.insert_session(conn, session)
        |> echo

      Nil
    }
    _ -> io.println("Error")
  }
}
