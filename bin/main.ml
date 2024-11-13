open Korotohvost

module type Environment = sig
  val title : string
  val https : bool
  val domain : string
end

module Pages = struct
  let mustache_of_file filename =
    In_channel.(with_open_text filename input_all) |> Mustache.of_string

  let index = mustache_of_file "static/templates/index.mustache.html"

  let short_url_info =
    mustache_of_file "static/templates/short-url-result.mustache.html"

  let not_found_short_url =
    mustache_of_file "static/templates/not-found-short-url.mustache.html"
end

module Routes (Env : Environment) (Url_map : Short_url_mapper.S) = struct
  let index_page _ =
    Mustache.render Pages.index (`O [ ("title", `String Env.title) ])
    |> Dream.html

  let redirect_to_origin_url req =
    let short_url_alias = Dream.param req "url" in

    match Url_map.get_original_url short_url_alias with
    | Ok original_url -> Dream.redirect req original_url
    | Error `Expired ->
        Mustache.render Pages.not_found_short_url
          (`O
            [
              ("short-url-alias", `String short_url_alias);
              ("message", `String "This URL was expired.");
            ])
        |> Dream.html ~status:`Not_Found
    | Error `Not_found ->
        Mustache.render Pages.not_found_short_url
          (`O
            [
              ("short-url-alias", `String short_url_alias);
              ("message", `String "Not found this URL in our storage...");
            ])
        |> Dream.html ~status:`Not_Found

  let make_short req =
    match%lwt Dream.form ~csrf:false req with
    | `Ok
        [ ("expire", _); ("original-url", original_url); ("short-url", alias) ]
      -> (
        match Url_map.create_short_url ~original_url ~alias ~expire:Never with
        | Error `Exist ->
            Dream.html ~status:`Bad_Request "The short URL is already exist!"
        | Ok () -> Dream.redirect req (Printf.sprintf "/i/%s" alias))
    | _ -> Dream.empty `Bad_Request

  let get_short_url_info req =
    let short_url_alias = Dream.param req "url" in
    let short_url_record = Url_map.get_alias_record short_url_alias in
    (* let short_url_stats = Url_map.get_stats_of_short_url url_alias in *)
    match short_url_record with
    | None ->
        Mustache.render Pages.not_found_short_url
          (`O
            [
              ("short-url-alias", `String short_url_alias);
              ("message", `String "Not found this URL in our storage...");
            ])
        |> Dream.html ~status:`Not_Found
    | Some short_url_record ->
        Mustache.render Pages.short_url_info
          (`O
            [
              ("alias", `String short_url_alias);
              ("original_url", `String short_url_record.original_url);
              ("domain", `String Env.domain);
              ("https", `String (if Env.https then "https" else "http"));
              ( "metrics",
                `O
                  [
                    ( "views",
                      `String (string_of_int !(short_url_record.metrics.views))
                    );
                  ] );
            ])
        |> Dream.html
end

let () =
  let open Dream in
  let module Url_map = Short_url_mapper.In_memory () in
  let module Routes =
    Routes
      (struct
        let title = "chads shorter"
        let domain = "localhost:8080"
        let https = false
      end)
      (Url_map)
  in
  run @@ logger
  @@ router
       Routes.
         [
           get "/" index_page;
           get "/s/:url" redirect_to_origin_url;
           get "/i/:url" get_short_url_info;
           post "/make" make_short;
           get "/static/**" (static "static/public");
         ]
