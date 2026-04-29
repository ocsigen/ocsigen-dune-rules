open Eliom_content.Html

let%server application_name = "my_app"
let%client application_name = Eliom_client.get_application_name ()

module%shared App = Eliom_registration.App (struct
  let application_name = application_name
  let global_data_path = None
end)

let _main_service =
  let run () () =
    Lwt.return
      F.(
        html
          (head (title (txt "my_app")) [])
          (body [ My_lib.counter_element ~init_value:42 ]))
  in
  let service =
    Eliom_service.create ~path:(Eliom_service.Path [])
      ~meth:(Eliom_service.Get Eliom_parameter.unit) ()
  in
  App.register ~service run

let _ =
  Ocsigen_server.start
    ~ports:[ (`All, 8080) ]
    ~command_pipe:"local/var/run/my_app" ~logdir:"local/var/log/my_app"
    ~datadir:"local/var/data/my_app" ~default_charset:(Some "utf-8")
    [ Ocsigen_server.host ~regexp:".*" [ Eliom.run () ] ]
