open Cmdliner

module Gen = struct
  let run internal_prefix subdir server_objs_dir dir =
    (match internal_prefix with
    | Some p -> Gen_rules.extra_ppx_args := [ "-internal-prefix"; p ]
    | None -> ());
    (match subdir with
    | Some s -> Gen_rules.subdir_name := s
    | None -> ());
    (match server_objs_dir with
    | Some d -> Gen_rules.server_objs_dir := d
    | None -> ());
    let files = Utils.list_dir dir in
    let files = List.filter (Fun.negate Utils.is_dir) files in
    Gen_rules.run files

  let arg_dir =
    let doc = "Directory containing the Eliom modules." in
    Arg.(required & pos 0 (some dir) None & info ~doc ~docv:"DIR" [])

  let arg_internal_prefix =
    let doc =
      "Pass [-internal-prefix $(docv)] to ocsigen-ppx-client.  Tells the \
       client PPX to strip the [$(docv)__] wrapper prefix from the type \
       paths it reads in the server [.cmo] files, so that the generated \
       client code references the user-visible names instead of the \
       internal ones.  Required when compiling a wrapped library whose \
       [%client] blocks refer to its own modules (e.g. ocsigen-start)."
    in
    Arg.(
      value
      & opt (some string) None
      & info ~doc ~docv:"PREFIX" [ "internal-prefix" ])

  let arg_subdir =
    let doc =
      "Wrap the generated rules in a [(subdir $(docv) ...)] stanza so the \
       preprocessed files land in [$(docv)/].  Used together with \
       [(include_subdirs qualified)] to expose the modules under a \
       [$(docv).] namespace."
    in
    Arg.(value & opt (some string) None & info ~doc ~docv:"DIR" [ "subdir" ])

  let arg_server_objs_dir =
    let doc =
      "Path to the server library's [.objs/byte/] directory, relative to \
       the dune file containing the generated rules.  When set, emit \
       explicit [%{dep:$(docv)/<prefix>__<Name>.cmo}] paths for \
       [-server-cmo] instead of the [%{cmo:Name}] dune variable.  Needed \
       when the client lib has a sister module of the same name as the \
       server, in which case [%{cmo:Name}] resolves to the local (client) \
       [.cmo] rather than the server's.  The [<prefix>__] is derived from \
       [--subdir]."
    in
    Arg.(
      value
      & opt (some string) None
      & info ~doc ~docv:"DIR" [ "server-objs-dir" ])

  let cmd =
    let term =
      Term.(
        const run
        $ arg_internal_prefix
        $ arg_subdir
        $ arg_server_objs_dir
        $ arg_dir)
    in
    let doc = "Generate dune rules to stdout." in
    let info = Cmd.info "gen" ~doc in
    Cmd.v info term
end

module Check_modules = struct
  let run server_bytecode client_bytecode =
    Check_modules.run ~server_bytecode ~client_bytecode

  let arg_server =
    let doc =
      "Path to the compiled bytecode for the server side. Usually APP_NAME.cma."
    in
    Arg.(
      required
      & opt (some string) None
      & info ~doc ~docv:"APP_NAME.cma" [ "server" ])

  let arg_client =
    let doc =
      "Path to the compiled bytecode for the client side. Usually \
       client/APP_NAME.bc."
    in
    Arg.(
      required
      & opt (some string) None
      & info ~doc ~docv:"client/APP_NAME.bc" [ "client" ])

  let cmd =
    let term = Term.(const run $ arg_server $ arg_client) in
    let doc =
      "Check whether the client and server libraries contain the same modules."
    in
    let info = Cmd.info "check-modules" ~doc in
    Cmd.v info term
end

let cmd =
  let doc =
    "Generate dune rules for building an ocsigen application or library."
  in
  let info = Cmd.info "ocsigen-dune-rules" ~version:"%%VERSION%%" ~doc in
  Cmd.group info [ Gen.cmd; Check_modules.cmd ]

let () = exit (Cmd.eval cmd)
