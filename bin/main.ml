open Korotohvost

module type Environment = sig
  val title : string
  val https : bool
  val domain : string
end

module Routes (Env : Environment) (Url_map : Short_url_mapper.S) = struct
  let index_page =
    let page = Index_page.render ~title_service:Env.title in
    fun _ -> Dream_html.respond page

  let redirect_to_origin_url req =
    let short_url = Dream.param req "url" in

    match Url_map.get_original_url short_url with
    | Ok original_url -> Dream.redirect req original_url
    | Error `Expired -> Dream.html ~status:`Not_Found "This URL was expired."
    | Error `Not_found ->
        Dream.html ~status:`Not_Found "Not found this URL in our storage..."

  let make_short req =
    match%lwt Dream.form ~csrf:false req with
    | `Ok [ ("original-url", original_url); ("short-url", alias) ] -> (
        match Url_map.create_short_url ~original_url ~alias ~expire:Never with
        | Error `Exist ->
            Dream.html ~status:`Bad_Request "The short URL is already exist!"
        | Ok () -> Dream.redirect req (Printf.sprintf "/i/%s" alias))
    | _ -> Dream.empty `Bad_Request

  let get_short_url_info req =
    let alias = Dream.param req "url" in
    let short_url_record = Url_map.get_alias_record alias in
    (* let short_url_stats = Url_map.get_stats_of_short_url url_alias in *)
    match short_url_record with
    | None ->
        Dream.html ~status:`Not_Found
        @@ Printf.sprintf "Not found information about alias <b>%s</b>." alias
    | Some short_url_record ->
        let open Env in
        Short_url_page.render ~alias ~domain ~https ~short_url_record
        |> Dream_html.respond
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
         ]
