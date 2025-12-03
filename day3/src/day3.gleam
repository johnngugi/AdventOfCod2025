import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() -> Nil {
  let assert Ok(lines) = simplifile.read(from: "src/input.txt")

  let banks = read_banks(lines)

  // Uncomment for part 1
  // banks
  // |> solution_1
  // |> int.to_string
  // |> io.println

  banks
  |> solution_2
  |> int.to_string
  |> io.println

  Nil
}

fn solution_1(battery_banks: List(String)) -> Int {
  battery_banks
  |> list.map(parse_bank)
  |> list.map(max_bank_joltage_1)
  |> list.fold(0, int.add)
}

fn solution_2(battery_banks: List(String)) -> Int {
  battery_banks
  |> list.map(parse_bank)
  |> list.map(max_bank_joltage_2)
  |> list.fold(0, int.add)
}

fn max_bank_joltage_2(digits: List(Int)) -> Int {
  find_max_joltage(digits, 0, 12, [])
}

fn find_max_joltage(
  digits: List(Int),
  position: Int,
  still_needed: Int,
  accumulator: List(Int),
) -> Int {
  case still_needed {
    0 -> {
      accumulator
      |> list.reverse
      |> list.fold(0, fn(acc, digit) { acc * 10 + digit })
    }
    _ -> {
      let remaining = list.length(digits) - position
      let window_size = remaining - still_needed + 1

      let max_item =
        digits
        |> list.drop(position)
        |> list.take(window_size)
        |> list.index_fold(#(0, 0), fn(acc, item, index) {
          case item > acc.1 {
            True -> #(index, item)
            False -> acc
          }
        })
      find_max_joltage(digits, position + max_item.0 + 1, still_needed - 1, [
        max_item.1,
        ..accumulator
      ])
    }
  }
}

fn max_bank_joltage_1(digits: List(Int)) -> Int {
  digits
  |> list.index_map(fn(d, i) {
    digits
    |> list.drop(i + 1)
    |> list.fold(0, fn(acc, curr) {
      let value =
        int.multiply(d, 10)
        |> int.add(curr)

      int.max(acc, value)
    })
  })
  |> list.fold(0, int.max)
}

fn parse_bank(bank: String) -> List(Int) {
  bank
  |> string.split("")
  |> list.filter_map(fn(char) { int.parse(char) })
}

fn read_banks(contents: String) -> List(String) {
  contents
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.filter(fn(r) { r != "" })
}
