let mustache_of_file filename =
  In_channel.(with_open_text filename input_all) |> Mustache.of_string

let index = mustache_of_file "static/templates/index.mustache.html"

let render_index ~title =
  Mustache.render index (`O [ ("title", `String title) ])

let short_url_info =
  mustache_of_file "static/templates/short-url-result.mustache.html"

let render_short_url_info ~alias ~original_url ~domain ~clicks ~expire_at =
  Mustache.render short_url_info
    (`O
      [
        ("alias", `String alias);
        ("original_url", `String original_url);
        ("domain", `String domain);
        ( "metrics",
          `O
            [
              ("views", `String (string_of_int clicks));
              ("expire", `String (Option.value ~default:"Never" expire_at));
            ] );
      ])

let not_found_short_url =
  mustache_of_file "static/templates/not-found-short-url.mustache.html"

let render_not_found_short_url ~alias message =
  Mustache.render not_found_short_url
    (`O [ ("short-url-alias", `String alias); ("message", `String message) ])

let failed_page = mustache_of_file "static/templates/failed.mustache.html"

let render_failed ~title ~header message =
  Mustache.render failed_page
    (`O
      [
        ("title", `String title);
        ("header", `String header);
        ("message", `String message);
      ])
