open Printf

let () =
  let name = "ppx_string" in
  let mood = "fine" in
  let msg = [%str "hello, $(name) are you $(mood)?\n"] in
  print_string msg;
  print_newline()

