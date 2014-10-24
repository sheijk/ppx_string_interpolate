open Printf

let () =
  let name = "ppx_string" in
  let mood = "fine" in
  let larrys_baby = "perl" in

  let msg = [%str "hello $(name) are you $(mood)?\n"] in
  print_string msg;
  print_string "testing double dollar: $$(name)";

  print_string [%str {eof|
This also works with new string syntax
So you can do templates like in $(larrys_baby).

|eof}];

  print_newline()

