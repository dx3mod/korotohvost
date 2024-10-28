let render ~title_service =
  let open Dream_html in
  let open HTML in
  html
    [ lang "en" ]
    [
      head [] [ title [] "%s" title_service ];
      body []
        [
          h1 [] [ txt "Welcome to %s!" title_service ];
          p []
            [
              txt "This site powered by ";
              a
                [ href "https://github.com/dx3mod/korotohvost" ]
                [ txt "korotohvost" ];
              txt ".";
            ];
          br [];
          h4 [] [ txt "Make a your short URL" ];
          form
            [ method_ `POST; action "/make" ]
            [
              (* csrf_tag req; *)
              label [ for_ "original-url" ] [ txt "Original URL"; br [] ];
              input [ name "original-url"; id "original-url"; required ];
              br [];
              br [];
              label [ for_ "short-url" ] [ txt "Short URL"; br [] ];
              input [ name "short-url"; id "short-url"; required ];
              br [];
              br [];
              input [ type_ "submit"; value "Make" ];
            ];
        ];
    ]
