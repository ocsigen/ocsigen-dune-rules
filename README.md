# ocsigen-dune-rules

[![OCaml-CI Build Status](https://img.shields.io/endpoint?url=https://ocaml.ci.dev/badge/ocsigen/ocsigen-dune-rules/main&logo=ocaml)](https://ocaml.ci.dev/github/ocsigen/ocsigen-dune-rules)

Generate Dune rules for building a client/server application or library.

## Usage

The following `dune` file builds the client and server parts of your library.
Place it in a directory containing `*.eliom` files.

`app/dune`:
```dune
(executable
 (name my_app)
 (modes byte native)
 (preprocess
  (pps eliom.ppx.server ocsigen-ppx-rpc --rpc-raw))
 (libraries
  eliom.server
  ocsigenserver
  ocsipersist-sqlite
  js_of_ocaml
  my_lib.server))

(subdir
 client
 (executable
  (name my_app)
  (modes js byte)
  (preprocess
   (pps eliom.ppx.client js_of_ocaml-ppx))
  (js_of_ocaml)
  (libraries eliom.client js_of_ocaml js_of_ocaml-lwt my_lib.client))
 (dynamic_include ../dune.client))

(rule
 (deps
  (glob_files *.eliom)
  (glob_files *.eliomi))
 (action
  (with-stdout-to
   dune.client
   (run ocsigen-dune-rules gen .))))

(rule
 (alias runtest)
 (action
  (run
   ocsigen-dune-rules
   check-modules
   --client
   %{dep:client/my_app.bc}
   --server
   %{dep:my_app.bc})))
```

You must also tell Dune that `*.eliom` files contain source code by adding this to your `dune-project` file:

`dune-project`:
```dune
(dialect
 (name "eliom-server")
 (implementation
  (extension "eliom"))
 (interface
  (extension "eliomi")))
```

See [`test/app.t`](test/app.t) for both application and library examples.
See [ocsigen-toolkit](https://github.com/ocsigen/ocsigen-toolkit/tree/master) for a real world example.
