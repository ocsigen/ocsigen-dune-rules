open Sexpgen

let public_name_field ~public_name ~name suffix =
  let n = Option.value public_name ~default:name in
  field "public_name" [ atom (n ^ suffix) ]

let server_library_stanza ~public_name ~name ~wrapped ~libraries ~preprocess =
  field "library"
    [
      public_name_field ~public_name ~name ".server";
      field "name" [ atom name ];
      field "modes" [ atom "byte"; atom "native" ];
      field "wrapped" [ atom (string_of_bool wrapped) ];
      field "library_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
      field "preprocess" [ field "pps" (atoms preprocess.Gen_utils.pps_server) ];
      field "libraries" (atoms libraries.Gen_utils.lib_server);
    ]

let client_library_stanza ~public_name ~name ~wrapped ~libraries =
  field "library"
    [
      public_name_field ~public_name ~name ".client";
      field "name" [ atom name ];
      field "modes" [ atom "byte" ];
      field "wrapped" [ atom (string_of_bool wrapped) ];
      field "library_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
      field "libraries" (atoms libraries.Gen_utils.lib_client);
    ]

let client_subdir_stanza ~public_name ~name ~wrapped ~libraries =
  field "subdir"
    [
      atom "client";
      client_library_stanza ~public_name ~name ~wrapped ~libraries;
      field "dynamic_include" [ atom "../dune.client" ];
    ]

let run public_name wrapped dune_file libraries preprocess name =
  Gen_utils.gen_prelude ~dune_file
  @ [
      server_library_stanza ~public_name ~name ~wrapped ~libraries ~preprocess;
      client_subdir_stanza ~public_name ~name ~wrapped ~libraries;
    ]
  @ Gen_utils.gen_client_modules_stanzas ~name ~wrapped preprocess
  |> pp_list Format.std_formatter
