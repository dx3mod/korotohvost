open Lwt.Infix
open Korotohvost

module Routes (Env : sig
  val title : string
  val domain : string
end) =
struct
  open Env

  let index _ = Pages.render_index ~title |> Dream.html

  let make_alias req =
    let make_alias ~expire ~original_url ~alias =
      Dream.sql req @@ fun db ->
      Url_mapper.insert_alias db ~alias ~original_url ~expire
      >>= Caqti_lwt.or_fail
    in

    match%lwt Dream.form ~csrf:false req with
    | `Ok
        [
          ("expire", expire);
          ("original-url", original_url);
          ("short-url", alias);
        ] -> (
        try%lwt
          make_alias ~expire:(Expiration.of_string expire) ~original_url ~alias;%lwt
          Dream.redirect req (Printf.sprintf "/i/%s" alias)
        with Caqti_error.Exn e ->
          Dream.log "%a" Caqti_error.pp e;
          Pages.render_failed ~title ~header:"Failed to create alias for URL!"
          @@ Printf.sprintf "The '%s' alias already exist!" alias
          |> Dream.html ~status:`Bad_Request)
    | _ -> Dream.empty `Bad_Request

  let redirect_to_original_url req =
    let alias = Dream.param req "alias" in
    Dream.sql req @@ fun db ->
    match%lwt
      Url_mapper.find_original_url_by_alias db alias >>= Caqti_lwt.or_fail
    with
    | Some original_url ->
        Url_mapper.update_clicks db alias >>= Caqti_lwt.or_fail;%lwt
        Dream.redirect req original_url
    | None ->
        Pages.render_not_found_short_url ~alias
          "Not found this URL in our storage..."
        |> Dream.html ~status:`Not_Found

  let get_alias_record req =
    let alias = Dream.param req "alias" in
    Dream.sql req @@ fun db ->
    match%lwt Url_mapper.find_alias_record db alias >>= Caqti_lwt.or_fail with
    | Some (alias, original_url, clicks, expire_at) ->
        Pages.render_short_url_info ~alias ~original_url ~clicks ~expire_at
          ~domain
        |> Dream.html
    | None ->
        Pages.render_not_found_short_url ~alias
          "Not found this URL in our storage..."
        |> Dream.html ~status:`Not_Found
end

module Make_cli_vars () = struct
  let title = ref "my-title"
  let host = ref "localhost"
  let port = ref 8080
  let domain = ref "localhost"
  let database = ref ""

  let speclist =
    [
      ("--port", Arg.Set_int port, "port (default 8080)");
      ("--host", Arg.Set_string host, "hostname (default localhost)");
      ("--title", Arg.Set_string title, "your title");
      ("--domain", Arg.Set_string domain, "for publish (default localhost:8080)");
      ("--database", Arg.Set_string database, "path to sqlite3 file");
    ]
end

let () =
  let module Cli_vars = Make_cli_vars () in
  Arg.parse Cli_vars.speclist ignore "...";

  if !Cli_vars.database = "" then
    failwith "Set --database path to sqlite3 file!";

  let module R = Routes (struct
    let title = !Cli_vars.title
    let domain = Cli_vars.(Printf.sprintf "%s:%d" !domain !port)
  end) in
  Dream.run ~port:!Cli_vars.port ~interface:!Cli_vars.host
  @@ Dream.logger
  @@ Dream.sql_pool ("sqlite3:" ^ !Cli_vars.database)
  @@ Dream.router
       [
         Dream.get "/" R.index;
         Dream.post "/s" R.make_alias;
         Dream.get "/s/:alias" R.redirect_to_original_url;
         Dream.get "/i/:alias" R.get_alias_record;
         Dream.get "/static/**" (Dream.static "static/public");
       ]
