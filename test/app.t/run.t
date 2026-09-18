To update this test, run these two bash commands:

dune exec -- ocsigen-dune-rules gen-application --server-libraries ocsipersist-sqlite,ocsigenserver.ext.staticmod --eliom-libraries my_lib my_app > test/app.t/app/dune
dune exec -- ocsigen-dune-rules gen-library --wrapped true my_lib > test/app.t/lib/dune

  $ dune build --profile release

  $ ls _build/default/app/my_app.cmxa _build/default/app/client/my_app.bc.js
  _build/default/app/client/my_app.bc.js
  _build/default/app/my_app.cmxa

  $ dune runtest
