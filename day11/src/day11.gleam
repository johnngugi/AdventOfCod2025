import gleam/dict
import gleam/int
import gleam/io
import gleam/list
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

fn solution_2(lines: List(String)) -> Int {
  get_graph(lines)
  |> get_paths_with_tracking
}

fn get_paths_with_tracking(graph: dict.Dict(String, List(String))) -> Int {
  let #(count, _memo) = count_paths("svr", False, False, graph, dict.new())
  count
}

fn count_paths(
  node: String,
  dac_seen: Bool,
  fft_seen: Bool,
  graph: dict.Dict(String, List(String)),
  memo: dict.Dict(#(String, Bool, Bool), Int),
) -> #(Int, dict.Dict(#(String, Bool, Bool), Int)) {
  let new_dac_state = dac_seen || node == "dac"
  let new_fft_state = fft_seen || node == "fft"
  let key = #(node, new_dac_state, new_fft_state)

  case dict.get(memo, key) {
    Ok(count) -> #(count, memo)
    Error(Nil) -> {
      case node == "out" {
        True ->
          case new_dac_state && new_fft_state {
            True -> {
              let new_memo = dict.insert(memo, key, 1)
              #(1, new_memo)
            }
            False -> {
              let new_memo = dict.insert(memo, key, 0)
              #(0, new_memo)
            }
          }
        False -> {
          case dict.get(graph, node) {
            Ok(neighbours) -> {
              let #(total, final_memo) =
                list.fold(neighbours, #(0, memo), fn(acc, neighbour) {
                  let #(sum_so_far, current_memo) = acc
                  let #(child_count, updated_memo) =
                    count_paths(
                      neighbour,
                      new_dac_state,
                      new_fft_state,
                      graph,
                      current_memo,
                    )
                  #(sum_so_far + child_count, updated_memo)
                })

              let new_memo = dict.insert(final_memo, key, total)
              #(total, new_memo)
            }
            Error(Nil) -> {
              let new_memo = dict.insert(memo, key, 0)
              #(0, new_memo)
            }
          }
        }
      }
    }
  }
}

fn solution_1(lines: List(String)) -> Int {
  get_graph(lines)
  |> get_paths
}

fn get_paths(graph: dict.Dict(String, List(String))) -> Int {
  let assert Ok(first) = dict.get(graph, "you")
  let queue = first

  bfs(queue, graph, 0)
}

fn bfs(
  queue: List(String),
  graph: dict.Dict(String, List(String)),
  count: Int,
) -> Int {
  case queue {
    [] -> count
    [first, ..rest] -> {
      case first == "out" {
        True -> bfs(rest, graph, count + 1)
        False -> {
          case dict.get(graph, first) {
            Ok(neighbours) -> {
              let new_queue =
                list.fold(neighbours, rest, fn(acc, curr) {
                  list.append(acc, [curr])
                })

              bfs(new_queue, graph, count)
            }
            Error(Nil) -> bfs(rest, graph, count)
          }
        }
      }
    }
  }
}

fn get_graph(lines: List(String)) -> dict.Dict(String, List(String)) {
  lines
  |> list.map(fn(line) {
    let assert [device, outputs] = string.split(line, ":")
    let outputs = string.split(outputs, " ")

    #(device, outputs)
  })
  |> dict.from_list
}
