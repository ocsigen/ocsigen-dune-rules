open%shared Eliom_content.Html
open%client Js_of_ocaml
open%client Js_of_ocaml_lwt

let%shared counter_element ~init_value =
  let btn_plus = D.(button [ txt "+" ])
  and btn_minus = D.(button [ txt "-" ])
  and span_display = D.(span [ txt (string_of_int init_value) ]) in
  ignore
    [%client
      let btn_plus = To_dom.of_button ~%btn_plus
      and btn_minus = To_dom.of_button ~%btn_minus
      and span_display = To_dom.of_span ~%span_display in
      let state = ref ~%init_value in
      let set_state v =
        state := v;
        span_display##.innerText := Js.string (string_of_int v);
        Lwt.return_unit
      in
      Lwt.pick
        [
          Lwt_js_events.clicks btn_plus (fun _ _ -> set_state (!state + 1));
          Lwt_js_events.clicks btn_minus (fun _ _ -> set_state (!state - 1));
        ]];
  F.div [ span_display; btn_plus; btn_minus ]
