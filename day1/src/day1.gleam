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
          let new = curr - num
          let new = new % 100
          let new_acc = case new == 0 {
            True -> acc + 1
            False -> acc
          }
          count(rest, new, new_acc)
        }
        #(Right, num) -> {
          let new = curr + num
          let new = new % 100
          let new_acc = case new == 0 {
            True -> acc + 1
            False -> acc
          }
          count(rest, new, new_acc)
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
