let pf = Printf.printf
let spf = Printf.sprintf

let gen_eliom_ppx_rule ~target ~input ~args =
  (* The [chdir] instruction is needed to obtain the correct path for
     [-loc-filename] to be used in error messages. *)
  pf
    {|(rule
 (with-stdout-to %s
  (chdir %%{workspace_root}
   (run ocsigen-ppx-client -as-pp -loc-filename %%{dep:%s} %s %%{dep:%s}))))
|}
    target input (String.concat " " args) input

let gen_rule_for_module ~server_rel_prefix ~impl fname =
  let fname_no_ext = Filename.remove_extension fname in
  let fbase = Filename.basename fname_no_ext in
  let input = Filename.concat server_rel_prefix fname in
  if Filename.extension fname_no_ext = ".pp" then ()
  else
    let target, args =
      if impl then
        let server_cmo = Filename.concat server_rel_prefix fname_no_ext in
        (fbase ^ ".ml", [ "--impl"; "-server-cmo"; spf "%%{cmo:%s}" server_cmo ])
      else (fbase ^ ".mli", [ "--intf" ])
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
