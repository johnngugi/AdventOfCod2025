import gleam/int
import gleam/io
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(lines) = simplifile.read(from: "src/input.txt")

  lines
  |> string.split("\n")
  |> process
  |> int.to_string
  |> io.println
}

type Direction {
  Left
  Right
  Unknown
}

fn process(lines: List(String)) -> Int {
  count(lines, 50, 0)
}

fn count(lines: List(String), curr: Int, acc: Int) -> Int {
  case lines {
    [] -> acc
    [first, ..rest] -> {
      case line(first) {
        #(Left, num) -> {
          let completed_circles = num / 100
          let remaining = num % 100
          let partial_cross = case curr {
            0 -> 0
            _ ->
              case remaining >= curr {
                True -> 1
                False -> 0
              }
          }
          let crossings = completed_circles + partial_cross

          let new_curr = int.modulo(curr - num, 100) |> result.unwrap(curr)
          count(rest, new_curr, acc + crossings)
        }
        #(Right, num) -> {
          let completed_circles = num / 100
          let remaining = num % 100
          let partial_cross = case curr {
            0 -> 0
            _ ->
              case remaining >= 100 - curr {
                True -> 1
                False -> 0
              }
          }
          let crossings = completed_circles + partial_cross

          let new_curr = int.modulo(curr + num, 100) |> result.unwrap(curr)

          count(rest, new_curr, acc + crossings)
        }
        #(Unknown, _) -> count(rest, curr, acc)
      }
    }
  }
}

fn line(text: String) {
  case text {
    "L" <> rest -> #(Left, int.parse(rest) |> result.unwrap(0))
    "R" <> rest -> #(Right, int.parse(rest) |> result.unwrap(0))
    _ -> #(Unknown, 0)
  }
}
