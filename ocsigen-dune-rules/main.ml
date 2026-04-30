open Cmdliner

module Gen = struct
  let run dir =
    let files = Utils.list_dir dir in
    let files = List.filter (Fun.negate Utils.is_dir) files in
    Gen_rules.run files

  let arg_dir =
    let doc = "Directory containing the Eliom modules." in
    Arg.(required & pos 0 (some dir) None & info ~doc ~docv:"DIR" [])

  let cmd =
    let term = Term.(const run $ arg_dir) in
    let doc = "Generate dune rules to stdout." in
    let info = Cmd.info "gen" ~doc in
    Cmd.v info term
end

module Check_modules = struct
  let run server_bytecode client_bytecode =
    Check_modules.run ~server_bytecode ~client_bytecode

  let arg_server =
    let doc =
      "Path to the bytecode executable for the server side. Usually \
       APP_NAME.bc."
    in
    Arg.(
      required
      & opt (some string) None
      & info ~doc ~docv:"APP_NAME.bc" [ "server" ])

  let arg_client =
    let doc =
      "Path to the bytecode executable for the client side. Usually \
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
