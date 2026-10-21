open Eliom.Content.Html

let%server application_name = "my_app"
let%client application_name = Eliom.Client.get_application_name ()

module%shared App = Eliom.Registration.App (struct
  let application_name = application_name
  let global_data_path = None
end)

let _main_service =
  let run () () =
    Lwt.return
      F.(
        html
          (head (title (txt "my_app")) [])
          (body [ My_lib.Counter.counter_element ~init_value:42 ]))
  in
  let service =
    Eliom.Service.create ~path:(Eliom.Service.Path [])
      ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()
  in
  App.register ~service run

let _ =
  Ocsigen.Server.start
    ~ports:[ (`All, 8080) ]
    ~default_charset:(Some "utf-8")
    [
      Ocsigen.Server.host ~regexp:".*"
        [ Staticmod.run ~dir:"dist/var/www/my_app" (); Eliom.App.run () ];
    ]
