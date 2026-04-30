(** Extract source file names from the [DBUG] section. See [Bytelink]. *)
let extract_source_files toc ic =
  let locs = ref [] in
  let record_events _ evl =
    List.iter
      (fun (ev : Instruct.debug_event) ->
        locs := ev.ev_loc.Location.loc_start.Lexing.pos_fname :: !locs)
      evl
  in
  (* Code taken from [tools/dumpobj.ml]. *)
  begin match Bytesections.seek_section toc ic Bytesections.Name.DBUG with
  | exception Not_found -> ()
  | (_ : int) ->
      let num_eventlists = input_binary_int ic in
      for _i = 1 to num_eventlists do
        let orig = input_binary_int ic in
        let evl = (input_value ic : Instruct.debug_event list) in
        (* Skip the list of absolute directory names *)
        ignore (input_value ic);
        record_events orig evl
      done
  end;
  !locs

(** Extract the list of source file names that were compiled to produce a
    bytecode program. Requires that the program is compiled with [-g]. *)
let source_files_in_bytecode path =
  In_channel.with_open_bin path (fun ic ->
      let toc = Bytesections.read_toc ic in
      extract_source_files toc ic)

module S = Set.Make (String)

let eliom_modules path =
  source_files_in_bytecode path
  |> List.filter (fun f -> Filename.check_suffix f ".eliom")
  |> S.of_list

let run ~server_bytecode ~client_bytecode =
  let server_modules = eliom_modules server_bytecode in
  let client_modules = eliom_modules client_bytecode in
  let missing_server_modules =
    S.diff server_modules client_modules |> S.to_list
  in
  let missing_client_modules =
    S.diff client_modules server_modules |> S.to_list
  in
  let missing_modules =
    missing_server_modules <> [] || missing_client_modules <> []
  in
  if missing_modules then (
    Format.(
      eprintf
        "Some modules are missing. Make sure to build with [(library_flags \
         (:standard -linkall))].@.@.@[<hv>Missing on the server:@ \
         @[<hov>%a@]@]@.@[<hv>Missing on the client:@ @[<hov>%a@]@]@."
        (pp_print_list pp_print_string)
        missing_server_modules
        (pp_print_list pp_print_string)
        missing_client_modules);
    exit 1)
