open Ast_mapper
open Ast_helper
open Asttypes
open Parsetree
open Longident

type part = String of string | Var of string
[@@deriving Show]

let parse_string str =
  let str_len = String.length str in
  let parts = ref [] in
  let pos = ref 0 in

  let add part =
    parts := part :: !parts;
  in
  let add_string_until new_pos =
    parts := String (String.sub str !pos (new_pos - !pos)) :: !parts;
    pos := new_pos
  in
  let skip test =
    let rec loop n =
      if n < str_len && test str.[n] then
        loop (n+1)
      else
        n
    in
    loop !pos
  in
  let look_at chr =
    !pos < str_len && str.[!pos] = chr
  in
  let expect chr =
    if not (look_at chr) then
      failwith (Printf.sprintf "expected %c at index %d" chr !pos)
  in
  let expect_eof yesno =
    if yesno <> (!pos >= str_len) then
      failwith "parse_string"
  in

  while !pos < str_len do
    let quote_pos = skip ((<>) '$') in
    add_string_until quote_pos;
    incr pos;
    if look_at '$' then
      add (String "$")
    else if look_at '(' then begin
      let quote_end = skip ((<>) ')') in
      pos := quote_end;
      expect ')';
      add (Var (String.sub str (quote_pos + 2) (quote_end - quote_pos - 2)));
      incr pos;
    end
  done;
  List.rev !parts

let getenv_mapper argv =
  (* Our getenv_mapper only overrides the handling of expressions in the default mapper. *)
  { default_mapper with
    expr = fun mapper expr ->
      match expr with
      (* Is this an extension node? *)
      | { pexp_desc =
          (* Should have name "str". *)
          Pexp_extension ({ txt = "str"; loc }, pstr)} ->
        begin match pstr with
        | (* Should have a single structure item, which is evaluation of a constant string. *)
          PStr [{ pstr_desc =
                  Pstr_eval ({ pexp_loc  = loc;
                               pexp_desc = Pexp_constant (Const_string (sym, None))}, _)}] ->
           let parts = parse_string sym in
           Printf.printf "parts = %s\n" @@ String.concat ", " @@ List.map show_part parts;
           let rec to_str_code = function
             | [] -> [%expr ""]
             | hd :: tl ->
                let hd_expr =
                  match hd with
                    | String str ->
                       Exp.constant ~loc (Const_string (str, None))
                    | Var name ->
                       Exp.ident @@ { txt = Longident.parse name; loc }
                in
                [%expr ([%e hd_expr] ^ [%e to_str_code tl])]
           in

           to_str_code parts
        | _ ->
          raise (Location.Error (
                  Location.error ~loc "[%str] accepts a string, e.g. [%str \"USER\"]"))
        end
      (* Delegate to the default mapper. *)
      | x -> default_mapper.expr mapper x;
  }

let () = register "str" getenv_mapper
 
