let pf = Printf.printf
let spf = Printf.sprintf

(** Extra arguments to pass to [ocsigen-ppx-client] for every rule.
    Currently used by [--internal-prefix]. *)
let extra_ppx_args = ref []

(** When non-empty, wrap generated rules in a [(subdir DIR ...)] stanza
    so the preprocessed files land in [DIR/].  Used together with
    [(include_subdirs qualified)]. *)
let subdir_name = ref ""

let gen_eliom_ppx_rule ~target ~input ~args =
  (* The [chdir] instruction is needed to obtain the correct path for
     [-loc-filename] to be used in error messages. *)
  let all_args = !extra_ppx_args @ args in
  if !subdir_name <> ""
  then
    pf
      {|(subdir %s
 (rule
  (with-stdout-to %s
   (chdir %%{workspace_root}
    (run ocsigen-ppx-client -as-pp -loc-filename %%{dep:%s} %s %%{dep:%s})))))
|}
      !subdir_name (Filename.basename target) input
      (String.concat " " all_args)
      input
  else
    pf
      {|(rule
 (with-stdout-to %s
  (chdir %%{workspace_root}
   (run ocsigen-ppx-client -as-pp -loc-filename %%{dep:%s} %s %%{dep:%s}))))
|}
      target input (String.concat " " all_args) input

let gen_rule_for_module ~server_rel_prefix ~impl fname =
  let target = Filename.basename fname in
  let fname_no_ext = Filename.remove_extension fname in
  let input = Filename.concat server_rel_prefix fname in
  if Filename.extension fname_no_ext = ".pp" then ()
  else
    let args =
      if impl then
        let server_cmo = Filename.concat server_rel_prefix fname_no_ext in
        [ "--impl"; "-server-cmo"; spf "%%{cmo:%s}" server_cmo ]
      else [ "--intf" ]
    in
    gen_eliom_ppx_rule ~target ~input ~args

(** Relative path to server modules from the generated client modules. *)
let server_rel_prefix = ".."

let gen_rule_for_file fname =
  match Filename.extension fname with
  | ".eliom" -> gen_rule_for_module ~server_rel_prefix ~impl:true fname
  | ".eliomi" -> gen_rule_for_module ~server_rel_prefix ~impl:false fname
  | _ -> ()

let run files = List.iter gen_rule_for_file files
