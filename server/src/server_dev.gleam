import argus
import argv
import gleam/io

pub fn main() {
  case argv.load().arguments {
    ["hash", pw] -> {
      let assert Ok(hashes) =
        argus.hasher()
        |> argus.hash(pw, argus.gen_salt())

      io.println(hashes.encoded_hash)
    }
    _ -> io.println("Error")
  }
}
