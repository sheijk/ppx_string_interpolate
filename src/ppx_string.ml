open Ast_mapper
open Ast_helper
open Asttypes
open Parsetree
open Longident

type part = String of string | Var of string
[@@deriving Show]

exception Parse_error of string * int

(** Using \\ works but will produce warnings from the lexer. *)
let escapeChar = '$'

let parse_string str =
  let parts = ref [] in
  let add item =
    parts := item :: !parts;
  in
  let buf = Sedlexing.Latin1.from_string str in
  let pos buf =
    let start, _ = Sedlexing.loc buf in
    start
  in
  let rec loop() =
    match%sedlex buf with
      | Plus (Compl '$') ->
         add @@ String (Sedlexing.Latin1.lexeme buf);
         loop()
      | "$$" ->
         add @@ String (Sedlexing.Latin1.lexeme buf);
         loop()
      | "$(", Plus (Compl ')'), ')' ->
         let token = Sedlexing.Latin1.lexeme buf in
         let var = String.sub token 2 (String.length token - 3) in
         add @@ Var var;
         loop()
      | ('$', Plus (Compl ('$' | '('))) | ('$', eof) ->
         raise (Parse_error ("Expected $ to be followed by '$' or '('", pos buf + 1))
      | "$(", Plus (Compl ')'), eof ->
         raise (Parse_error ("Expected closing ')' but found end of string", String.length str))
      | eof ->
         ()
      | _ ->
         raise (Parse_error ("Unexpected character", pos buf))
  in
  loop();
  List.rev !parts

let to_str_code parts =
  let rec to_list =
    function
    | [] ->
       [%expr []]
    | hd :: tl ->
       let hd_expr =
         match hd with
           | String str ->
              Exp.constant ~loc:!(Ast_helper.default_loc) (Const_string (str, None))
           | Var name ->
              Exp.ident @@ { txt = Longident.parse name; loc = !(Ast_helper.default_loc) }
       in
       [%expr ([%e hd_expr] :: [%e to_list tl])]
  in
  let parts_list = to_list parts in
  [%expr String.concat "" [%e parts_list]]

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
                               pexp_desc = Pexp_constant (Const_string (sym, _))}, _)}] ->
           begin
             try
               let parts = parse_string sym in
               Ast_helper.with_default_loc loc (fun () -> to_str_code parts)

             with Parse_error (message, pos) ->
               let string_start = loc.Location.loc_start.Lexing.pos_cnum in
               let loc = { loc with
                           Location.loc_start = {
                             loc.Location.loc_start with Lexing.pos_cnum = string_start + 1 + pos };
                           loc_end = { loc.Location.loc_end with Lexing.pos_cnum = string_start + 2 + pos } }
               in
               let error = Location.error ~loc ("Error: " ^ message) in
               raise (Location.Error error)
           end
        | _ ->
          raise (Location.Error (
                  Location.error ~loc "[%str] accepts a string, e.g. [%str \"USER\"]"))
        end
      (* Delegate to the default mapper. *)
      | x -> default_mapper.expr mapper x;
  }

let () = register "str" getenv_mapper
 
