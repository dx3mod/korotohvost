let render ~alias ~domain ~https ~(short_url_record : Short_url_mapper.Record.t)
    =
  let open Dream_html in
  let open HTML in
  let short_url =
    Printf.sprintf "%s://%s/s/%s"
      (if https then "https" else "http")
      domain alias
  in

  let unix_time_to_date time =
    let time = Unix.localtime time in

    let day = time.Unix.tm_mday in
    let month = time.Unix.tm_mon + 1 in
    let year = time.Unix.tm_year + 1900 in

    Printf.sprintf "%d.%d.%d" day month year
  in

  html
    [ lang "en" ]
    [
      head [] [ title [] "%s" alias ];
      body []
        [
          p []
            [
              txt "The your short URL ";
              a [ href "%s" short_url ] [ txt "%s" short_url ];
              txt " redirects to ";
              a
                [ href "%s" short_url_record.original_url ]
                [ txt "%s" short_url_record.original_url ];
              txt ".";
              br [];
              txt "Views: %d." !(short_url_record.metrics.views);
              br [];
              txt "Expire: %s."
                (match short_url_record.expire with
                | Never -> "Never"
                | Date time -> unix_time_to_date time);
              br [];
              txt "Back to ";
              a [ href "/" ] [ txt "home" ];
              txt ".";
            ];
        ];
    ]
