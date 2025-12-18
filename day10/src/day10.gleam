import gleam/dict
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import simplifile

pub fn main() -> Nil {
  let assert Ok(content) = simplifile.read("src/input.txt")

  content
  |> string.trim
  |> string.split("\n")
  |> solution_1
  |> int.to_string
  |> io.println

  content
  |> string.trim
  |> string.split("\n")
  |> solution_2
  |> int.to_string
  |> io.println

  Nil
}

pub type Machine {
  Machine(lights: List(Int), buttons: List(Int))
}

pub type Machine2 {
  Machine2(buttons: List(List(Int)), joltages: List(Int))
}

fn solution_1(lines: List(String)) -> Int {
  lines
  |> list.map(fn(line) { string.split(line, " ") })
  |> list.map(fn(machine) {
    let assert [indicator_lights, ..rest] = machine
    let buttons = list.take(rest, list.length(rest) - 1)

    let lights = get_lights_bits(indicator_lights)
    let button_bits = get_buttons_bits(buttons, list.length(lights))

    Machine(lights:, buttons: button_bits)
  })
  |> list.fold(0, fn(acc, machine) {
    machine
    |> fewest_button_presses
    |> int.add(acc)
  })
}

fn get_buttons_bits(buttons: List(String), width: Int) -> List(Int) {
  buttons
  |> list.map(fn(button) {
    button
    |> string.replace("(", "")
    |> string.replace(")", "")
    |> string.split(",")
    |> list.map(fn(num_str) {
      let assert Ok(num) = int.parse(num_str)
      num
    })
  })
  |> list.map(fn(button) { bits_to_int(button, width) })
}

fn bits_to_int(bits: List(Int), width: Int) -> Int {
  list.fold(bits, 0, fn(acc, bit) {
    acc + int.bitwise_shift_left(1, width - 1 - bit)
  })
}

fn binary_list_to_int(nums: List(Int)) -> Int {
  bin_to_int(list.reverse(nums), 0, 0)
}

fn bin_to_int(nums: List(Int), power: Int, acc: Int) -> Int {
  case nums {
    [] -> acc
    [first, ..rest] -> {
      let assert Ok(pow) = int.power(2, int.to_float(power))
      let result = acc + int.multiply(first, float.round(pow))

      bin_to_int(rest, power + 1, result)
    }
  }
}

fn fewest_button_presses(machine: Machine) -> Int {
  let num_of_buttons = list.length(machine.buttons)
  let assert Ok(masks) = int.power(2, int.to_float(num_of_buttons))
  let goal = binary_list_to_int(machine.lights)

  list.range(0, float.round(masks) - 1)
  |> list.filter_map(fn(mask) {
    let pressed_indices = get_set_bits(mask, num_of_buttons)

    let result =
      pressed_indices
      |> list.filter_map(fn(i) {
        machine.buttons
        |> list.drop(i)
        |> list.first
      })
      |> list.fold(0, int.bitwise_exclusive_or)

    case result == goal {
      True -> Ok(list.length(pressed_indices))
      False -> Error(Nil)
    }
  })
  |> list.fold(999_999, int.min)
}

fn get_set_bits(mask: Int, num_bits: Int) -> List(Int) {
  list.range(0, num_bits - 1)
  |> list.filter(fn(i) {
    int.bitwise_and(mask, int.bitwise_shift_left(1, i)) != 0
  })
}

fn get_lights_bits(lights_part: String) -> List(Int) {
  string.split(lights_part, "")
  |> list.filter(fn(char) { char != "[" && char != "]" })
  |> list.map(fn(char) {
    case char {
      "#" -> 1
      "." -> 0
      _ -> 0
    }
  })
}

fn solution_2(lines: List(String)) -> Int {
  lines
  |> list.map(parse_machine)
  |> list.map(solve_machine)
  |> list.fold(0, int.add)
}

fn parse_machine(line: String) -> Machine2 {
  let parts = string.split(line, " ")
  let assert [_, ..rest] = parts
  // skip indicator lights

  // Split into buttons and joltages
  let buttons_strs = list.take(rest, list.length(rest) - 1)
  let assert [joltage_str, ..] = list.reverse(rest)

  let buttons =
    list.map(buttons_strs, fn(button) {
      button
      |> string.replace("(", "")
      |> string.replace(")", "")
      |> string.split(",")
      |> list.map(fn(s) {
        let assert Ok(n) = int.parse(s)
        n
      })
    })

  let joltages =
    joltage_str
    |> string.replace("{", "")
    |> string.replace("}", "")
    |> string.split(",")
    |> list.map(fn(s) {
      let assert Ok(n) = int.parse(s)
      n
    })

  Machine2(buttons:, joltages:)
}

fn solve_machine(machine: Machine2) -> Int {
  let num_counters = list.length(machine.joltages)

  // Build lookup: parity pattern -> list of (button combo, resulting counts)
  let press_patterns = build_press_patterns(machine.buttons, num_counters)

  // Call recursive solver
  let cache = dict.new()
  let #(result, _) = cost(machine.joltages, press_patterns, cache)
  result
}

// Generate all button combinations and group by parity pattern
fn build_press_patterns(
  buttons: List(List(Int)),
  num_counters: Int,
) -> dict.Dict(List(Int), List(#(Int, List(Int)))) {
  let num_buttons = list.length(buttons)
  let assert Ok(num_combos) = int.power(2, int.to_float(num_buttons))

  list.range(0, float.round(num_combos) - 1)
  |> list.map(fn(mask) {
    // Get which buttons are pressed
    let pressed =
      buttons
      |> list.index_map(fn(button, i) { #(i, button) })
      |> list.filter(fn(pair) {
        int.bitwise_and(mask, int.bitwise_shift_left(1, pair.0)) != 0
      })
      |> list.map(fn(pair) { pair.1 })

    // Compute the resulting count for each counter
    let counts = compute_counts(pressed, num_counters)

    // Compute parity pattern
    let parity = list.map(counts, fn(c) { c % 2 })

    // Return: parity pattern, (number of buttons pressed, counts)
    #(parity, #(list.length(pressed), counts))
  })
  |> group_by_first
}

// Compute how many times each counter is incremented
fn compute_counts(
  pressed_buttons: List(List(Int)),
  num_counters: Int,
) -> List(Int) {
  list.range(0, num_counters - 1)
  |> list.map(fn(counter) {
    pressed_buttons
    |> list.filter(fn(button) { list.contains(button, counter) })
    |> list.length
  })
}

// Group list of #(key, value) into Dict(key, List(value))
fn group_by_first(pairs: List(#(a, b))) -> dict.Dict(a, List(b)) {
  list.fold(pairs, dict.new(), fn(acc, pair) {
    let #(key, value) = pair
    dict.upsert(acc, key, fn(existing) {
      case existing {
        None -> [value]
        Some(lst) -> [value, ..lst]
      }
    })
  })
}

// Recursive cost function with memoization
fn cost(
  joltages: List(Int),
  press_patterns: dict.Dict(List(Int), List(#(Int, List(Int)))),
  cache: dict.Dict(List(Int), Int),
) -> #(Int, dict.Dict(List(Int), Int)) {
  // Base case: all zeros
  case list.all(joltages, fn(j) { j == 0 }) {
    True -> #(0, cache)
    False -> {
      // Check cache
      case dict.get(cache, joltages) {
        Ok(cached) -> #(cached, cache)
        Error(_) -> {
          // Check for negative values (invalid)
          case list.any(joltages, fn(j) { j < 0 }) {
            True -> #(999_999_999, cache)
            False -> {
              // Get parity pattern of current joltages
              let parity = list.map(joltages, fn(j) { j % 2 })

              // Find all button combos matching this parity
              case dict.get(press_patterns, parity) {
                Error(_) -> #(999_999_999, cache)
                Ok(combos) -> {
                  // Try each combo and find minimum
                  let #(min_cost, final_cache) =
                    list.fold(combos, #(999_999_999, cache), fn(acc, combo) {
                      let #(best, curr_cache) = acc
                      let #(num_pressed, counts) = combo

                      // Compute remaining joltages: (joltage - count) / 2
                      let remaining =
                        list.map2(joltages, counts, fn(j, c) { { j - c } / 2 })

                      // Recurse
                      let #(sub_cost, new_cache) =
                        cost(remaining, press_patterns, curr_cache)

                      let total = num_pressed + 2 * sub_cost

                      case total < best {
                        True -> #(total, new_cache)
                        False -> #(best, new_cache)
                      }
                    })

                  // Update cache
                  let updated_cache =
                    dict.insert(final_cache, joltages, min_cost)
                  #(min_cost, updated_cache)
                }
              }
            }
          }
        }
      }
    }
  }
}
