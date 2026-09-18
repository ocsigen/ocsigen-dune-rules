let spf = Printf.sprintf
let dep f = spf "%%{dep:%s}" f

let ppx_exe ~subdir_name =
  let prefix = if subdir_name = "" then "" else "../" in
  spf "%%{exe:%sppx/main.exe}" prefix

let gen_eliom_ppx_rule ~ppx_exe ~target ~input ~args =
  (* The [chdir] instruction is needed to obtain the correct path for
     [-loc-filename] to be used in error messages. *)
  Sexpgen.
    [
      field "rule"
        [
          field "with-stdout-to"
            [
              atomf "%s" target;
              field "chdir"
                [
                  atom "%{workspace_root}";
                  field "run"
                    (atoms [ ppx_exe; "-as-pp"; "-loc-filename"; dep input ]
                    @ atoms args
                    @ atoms [ dep input ]);
                ];
            ];
        ];
    ]

let with_subdir_opt ~subdir_name rules =
  if subdir_name = "" then rules
  else Sexpgen.[ field "subdir" (atom subdir_name :: rules) ]

(** Compute the [-server-cmo] argument for a given module file.

    With [--server-objs-dir DIR], build an explicit [%{dep:...}] path pointing
    at [DIR/<prefix>__<Name>.cmo] to avoid the ambiguity of [%{cmo:Name}] when
    client and server libs both have a [Name] module. *)
let server_cmo_arg ~internal_prefix ~subdir_name ~server_objs_dir
    ~server_rel_prefix ~fname_no_ext =
  if server_objs_dir <> "" then
    let module_base = Filename.basename fname_no_ext in
    let cap_name = String.capitalize_ascii module_base in
    let cmo_from_dune_dir =
      let prefix =
        if internal_prefix <> "" then
          String.lowercase_ascii internal_prefix ^ "__"
        else if subdir_name <> "" then String.lowercase_ascii subdir_name ^ "__"
        else ""
      in
      spf "%s/%s%s.cmo" server_objs_dir prefix cap_name
    in
    let cmo_path =
      if subdir_name <> "" then spf "../%s" cmo_from_dune_dir
      else cmo_from_dune_dir
    in
    spf "%%{dep:%s}" cmo_path
  else
    let server_cmo = Filename.concat server_rel_prefix fname_no_ext in
    spf "%%{cmo:%s}" server_cmo

let gen_rule_for_module ~extra_ppx_args ~internal_prefix ~subdir_name
    ~server_objs_dir ~server_rel_prefix ~impl fname =
  let target = Filename.basename fname in
  let fname_no_ext = Filename.remove_extension fname in
  let input = Filename.concat server_rel_prefix fname in
  if Filename.extension fname_no_ext = ".pp" then []
  else
    let args =
      extra_ppx_args
      @
      if impl then
        let server_cmo =
          server_cmo_arg ~internal_prefix ~subdir_name ~server_objs_dir
            ~server_rel_prefix ~fname_no_ext
        in
        [ "--impl"; "-server-cmo"; server_cmo ]
      else [ "--intf" ]
    in
    with_subdir_opt ~subdir_name
      (gen_eliom_ppx_rule ~ppx_exe:(ppx_exe ~subdir_name) ~target ~input ~args)

(** Relative path to server modules from the generated client modules. *)
let server_rel_prefix = ".."

let gen_rule_for_file ~extra_ppx_args ~internal_prefix ~subdir_name
    ~server_objs_dir fname =
  match Filename.extension fname with
  | ".eliom" ->
      gen_rule_for_module ~extra_ppx_args ~internal_prefix ~subdir_name
        ~server_objs_dir ~server_rel_prefix ~impl:true fname
  | ".eliomi" ->
      gen_rule_for_module ~extra_ppx_args ~internal_prefix ~subdir_name
        ~server_objs_dir ~server_rel_prefix ~impl:false fname
  | _ -> []

let run ~extra_ppx_args ?(internal_prefix = "") ?(subdir_name = "")
    ?(server_objs_dir = "") files =
  List.concat_map
    (gen_rule_for_file ~extra_ppx_args ~internal_prefix ~subdir_name
       ~server_objs_dir)
    files
  |> Sexpgen.pp_list Format.std_formatter
