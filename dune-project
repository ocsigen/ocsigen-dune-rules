(lang dune 3.14)

(name ocsigen-dune-rules)

(cram enable)

(generate_opam_files true)

(authors "Jules Aguillon <jules@j3s.fr>")

(maintainers "Jules Aguillon <jules@j3s.fr>")

(license MIT)

(package
 (name ocsigen-dune-rules)
 (synopsis
  "Generate Dune rules for building a client/server application or library")
 (depends
  ocaml
  cmdliner
  ocsigen-ppx-rpc
  (eliom
   (>= "12.0.0"))
  (ocsigenserver :with-test)
  (ocsipersist-sqlite :with-test)
  (js_of_ocaml :with-test)
  (js_of_ocaml-lwt :with-test)
  (js_of_ocaml-ppx :with-test)
  ; Bigstringaf is a transitive dependency of 'uri' and cause this errors below
  ; version 0.7.0:
  ;     Error: missing dependency 'caml_string_unsafe_set'
  (bigstringaf
   (and
    :with-test
    (>= 0.7.0)))))
