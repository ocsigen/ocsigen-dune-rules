  $ ocsigen-dune-rules gen-library --server-libraries a --client-libraries b --libraries c --server-preprocess p1 --client-preprocess p2 --preprocess p3 --wrapped false my_lib > dune

  $ dune format-dune-file dune > dune.fmt
  $ diff dune dune.fmt

  $ cat dune
  (rule
   (with-stdout-to
    dune.corrected
    (run
     ocsigen-dune-rules
     gen-library
     --server-libraries
     a
     --client-libraries
     b
     --libraries
     c
     --server-preprocess
     p1
     --client-preprocess
     p2
     --preprocess
     p3
     --wrapped
     false
     my_lib
     --dune
     %{dep:dune})))
  
  ; [ocsigen-dune-rules] Do not remove this line.
  ; Below this line, any changes will be overwritten.
  ;
  ; To update the rules below, modify the invocation of ocsigen-dune-rules above
  ; and run:
  ;
  ;     dune runtest --auto-promote
  ;
  
  (rule
   (alias runtest)
   (action
    (diff dune dune.corrected)))
  
  (library
   (public_name my_lib.server)
   (name my_lib)
   (modes byte native)
   (wrapped false)
   (library_flags
    (:standard -linkall))
   (preprocess
    (pps
     eliom.ppx.server
     ocsigen-ppx-rpc
     js_of_ocaml-ppx_deriving_json
     --rpc-raw
     p1
     p3))
   (libraries eliom.server a c))
  
  (subdir
   client
   (library
    (public_name my_lib.client)
    (name my_lib)
    (modes byte)
    (wrapped false)
    (library_flags
     (:standard -linkall))
    (libraries eliom.client js_of_ocaml js_of_ocaml-lwt b c))
   (dynamic_include ../dune.client))
  
  (subdir
   client/ppx
   (rule
    (write-file main.ml "let () = Ppxlib.Driver.standalone ()"))
   (executable
    (name main)
    (libraries
     ppxlib
     eliom.ppx.client
     ocsigen-ppx-rpc
     js_of_ocaml-ppx
     js_of_ocaml-ppx_deriving_json
     p2
     p3)))
  
  (rule
   (deps
    (glob_files *.eliom)
    (glob_files *.eliomi))
   (action
    (with-stdout-to
     dune.client
     (run ocsigen-dune-rules gen-client-modules . -- --rpc-raw))))

Remove the --rpc-raw flag:

  $ ocsigen-dune-rules gen-library --no-rpc-raw --wrapped false my_lib | grep pps
    (pps eliom.ppx.server ocsigen-ppx-rpc js_of_ocaml-ppx_deriving_json))

Warns when passing a default library or preprocessor:

  $ ocsigen-dune-rules gen-library --server-libraries eliom.server --libraries js_of_ocaml --wrapped false my_lib >/dev/null
  Error: client library (use --server-libraries) "js_of_ocaml" is already included by default.
  Error: server library "eliom.server" is already included by default.
  [1]
  $ ocsigen-dune-rules gen-library --server-preprocess eliom.ppx.server --client-preprocess js_of_ocaml-ppx --wrapped false my_lib >/dev/null
  Error: client preprocess "js_of_ocaml-ppx" is already included by default.
  Error: server preprocess "eliom.ppx.server" is already included by default.
  [1]

--wrapped true generates an error for now.

  $ ocsigen-dune-rules gen-library --wrapped true my_lib | grep wrapped
     --wrapped
   (wrapped true)
    (wrapped true)
