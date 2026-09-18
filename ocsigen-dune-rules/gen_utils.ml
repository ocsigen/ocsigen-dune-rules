open Sexpgen

type libraries = { lib_server : string list; lib_client : string list }

type preprocess = {
  pps_server : string list;
  pps_client_libs : string list;
  pps_client_args : string list;
}

let server_default_pps =
  [ "eliom.ppx.server"; "ocsigen-ppx-rpc"; "js_of_ocaml-ppx_deriving_json" ]

let client_default_pps =
  [
    "eliom.ppx.client";
    "ocsigen-ppx-rpc";
    "js_of_ocaml-ppx";
    "js_of_ocaml-ppx_deriving_json";
  ]

let server_default_libs = [ "eliom.server" ]
let client_default_libs = [ "eliom.client"; "js_of_ocaml"; "js_of_ocaml-lwt" ]

(** Generate a warning when a default library or preprocessor is passed. *)
let check_duplicated what defaults items =
  List.fold_left
    (fun acc item ->
      if List.mem item defaults then (
        Printf.eprintf "Error: %s %S is already included by default.\n" what
          item;
        true)
      else acc)
    false items

(** non short-circuiting to print all the errors at once. *)
let ( ||| ) = ( || )

let exit_if b = if b then exit 1

let make_libraries ~server ~client ~both ~eliom =
  exit_if
    (check_duplicated "server library" server_default_libs server
    ||| check_duplicated "server library (use --client-libraries)"
          server_default_libs both
    ||| check_duplicated "client library" client_default_libs client
    ||| check_duplicated "client library (use --server-libraries)"
          client_default_libs both
    ||| check_duplicated "eliom library" [ "eliom" ] eliom);
  let eliom suffix = List.map (fun l -> l ^ suffix) eliom in
  {
    lib_server = server_default_libs @ server @ both @ eliom ".server";
    lib_client = client_default_libs @ client @ both @ eliom ".client";
  }

let make_preprocess ~server ~client ~both ~no_rpc_raw =
  let rpc_raw_flag = if no_rpc_raw then [] else [ "--rpc-raw" ] in
  (* Split at the [--] argument. *)
  let rec split_pps_args acc = function
    | [] -> (List.rev acc, [])
    | "--" :: args -> (List.rev acc, args)
    | lib :: tl -> split_pps_args (lib :: acc) tl
  in
  let client_libs, client_args = split_pps_args [] client in
  let both_libs, both_args = split_pps_args [] both in
  exit_if
    (check_duplicated "server preprocess" server_default_pps server
    ||| check_duplicated "server preprocess (use --client-preprocess)"
          server_default_pps both
    ||| check_duplicated "client preprocess" client_default_pps client
    ||| check_duplicated "client preprocess (use --server-preprocess)"
          client_default_pps both);
  {
    pps_server = server_default_pps @ rpc_raw_flag @ server @ both;
    pps_client_libs = client_default_pps @ client_libs @ both_libs;
    pps_client_args = rpc_raw_flag @ client_args @ both_args;
  }

(** A standalone Ppxlib driver linking every client PPX. Running them all in a
    single driver is what allows Ppxlib to order the transformations. *)
let ppx_client_stanza preprocess =
  field "subdir"
    [
      atom "client/ppx";
      field "rule"
        [
          field "write-file"
            [ atom "main.ml"; atom "let () = Ppxlib.Driver.standalone ()" ];
        ];
      field "executable"
        [
          field "name" [ atom "main" ];
          field "libraries" (atoms ("ppxlib" :: preprocess.pps_client_libs));
        ];
    ]

(** Stanzas building the client modules: the PPX driver and the rule generating
    the [dune.client] file, which contains a rule per module. *)
let gen_client_modules_stanzas ~name ~wrapped preprocess =
  let ppx_args =
    match preprocess.pps_client_args with [] -> [] | args -> "--" :: args
  and wrapped_args =
    (* gen-client-modules needs to construct wrapped names and to locate the
       server library objects. *)
    if wrapped then
      [
        "--internal-prefix";
        name;
        "--server-objs-dir";
        Printf.sprintf "../.%s.objs/byte" name;
      ]
    else []
  in
  [
    ppx_client_stanza preprocess;
    field "rule"
      [
        field "deps"
          [
            field "glob_files" [ atom "*.eliom" ];
            field "glob_files" [ atom "*.eliomi" ];
          ];
        field "action"
          [
            field "with-stdout-to"
              [
                atom "dune.client";
                field "run"
                  (atoms
                     ([ "ocsigen-dune-rules"; "gen-client-modules" ]
                     @ wrapped_args @ [ "." ] @ ppx_args));
              ];
          ];
      ];
  ]

let generated_start_marker = "; [ocsigen-dune-rules]"

let preserve_prelude dune_file =
  let rec loop acc inp =
    match In_channel.input_line inp with
    | Some l ->
        if String.starts_with ~prefix:generated_start_marker l then acc
        else loop (l :: acc) inp
    | None -> acc
  in
  List.rev (In_channel.with_open_text dune_file (loop []))

let gen_default_prelude () =
  let argv = List.tl (Array.to_list Sys.argv) in
  field "rule"
    [
      field "with-stdout-to"
        [
          atom "dune.corrected";
          field "run"
            (atoms
               (("ocsigen-dune-rules" :: argv) @ [ "--dune"; "%{dep:dune}" ]));
        ];
    ]

(** Output the top part of the dune file by reading the current dune file. If
    [--dune] is not passed, generate the rule calling ocsigen-dune-rules. *)
let gen_prelude ~dune_file =
  let prelude =
    match dune_file with
    | Some dune_file -> raw_sexp_lines (preserve_prelude dune_file)
    | None -> gen_default_prelude ()
  in
  [
    prelude;
    raw_sexp_lines [ generated_start_marker ^ " Do not remove this line." ];
    cmt
      {| Below this line, any changes will be overwritten.

 To update the rules below, modify the invocation of ocsigen-dune-rules above
 and run:

     dune runtest --auto-promote
|};
    field "rule"
      [
        field "alias" [ atom "runtest" ];
        field "action" [ field "diff" [ atom "dune"; atom "dune.corrected" ] ];
      ];
  ]
