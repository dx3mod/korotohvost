open Korotohvost

module type Environment = sig
  val domain : string
end

module Routes (Env : Environment) (Url_storage : Url_storage.S) = struct
  let index_page _ =
    Dream.html
      {html|Welcome to <a href="https://github.com/dx3mod/korotohvost">korotohvost</a> powered URL shorter service!|html}

  let redirect_to_origin_url req =
    let short_url = Dream.param req "url" in

    match Url_storage.get ~short:short_url with
    | Ok original_url -> Dream.redirect req original_url
    | Error `Expired -> Dream.html ~status:`Not_Found "This URL was expired."
    | Error `Not_found ->
        Dream.html ~status:`Not_Found "Not found this URL in our storage..."

  let make_short req =
    let original_url = Dream.query req "orig" |> Option.get in
    let short_url = Dream.query req "short" |> Option.get in

    let result =
      Url_storage.create ~orig:original_url ~short:short_url ~expire:Never
    in
    match result with
    | Error `Exist ->
        Dream.html ~status:`Bad_Request "The short URL is already exist!"
    | Ok () ->
        Dream.html
        @@ Printf.sprintf "Your URL: https://%s/s/%s." Env.domain short_url
end

let () =
  let open Dream in
  let open
    Routes
      (struct
        let domain = "chads.zip"
      end)
      (Url_storage.In_memory_storage ()) in
  run @@ logger
  @@ router
       [
         get "/" index_page;
         get "/s/:url" redirect_to_origin_url;
         post "/make" make_short;
       ]
