  $ ocsigen-dune-rules .
  (rule
   (with-stdout-to a.ml
    (run ../tools/eliom_ppx_client.exe --impl -server-cmo %{cmo:../a} %{dep:../a.eliom})))
    (rule
   (with-stdout-to b.ml
    (run ../tools/eliom_ppx_client.exe --impl -server-cmo %{cmo:../b} %{dep:../b.eliom})))
    (rule
   (with-stdout-to b.mli
    (run ../tools/eliom_ppx_client.exe --intf %{dep:../b.eliomi})))
    
