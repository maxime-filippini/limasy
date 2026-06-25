import envoy
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Error {
  FileError(String)
  ParsingError(Int, String)
}

pub fn load(path: String) -> Result(Nil, Error) {
  use content <- result.try(
    simplifile.read(path) |> result.map_error(fn(_) { FileError(path) }),
  )

  let lines = string.split(content, "\n")

  lines
  |> list.index_map(fn(line, idx) {
    let res = string.split_once(line, "=")

    case res {
      Ok(#(k, v)) -> {
        envoy.set(k, v)
        Ok(Nil)
      }
      Error(_) -> Error(ParsingError(idx, line))
    }
  })

  Ok(Nil)
}
