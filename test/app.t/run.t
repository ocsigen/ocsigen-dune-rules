  $ dune build --profile release

  $ ls _build/default/app/my_app.bc _build/default/app/client/my_app.bc.js
  _build/default/app/client/my_app.bc.js
  _build/default/app/my_app.bc

  $ dune runtest
