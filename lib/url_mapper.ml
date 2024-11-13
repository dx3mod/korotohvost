module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let expire_condition =
    "(expire_at > DATETIME(current_timestamp, 'localtime') or expire_at is \
     NULL)"

  let insert_alias =
    (t3 string string string ->. unit)
      "INSERT INTO aliases (alias, original_url, expire_at) VALUES (?, ?, \
       DATETIME(current_timestamp, 'localtime', ?))"

  let update_clicks =
    (string ->. unit) "UPDATE aliases SET clicks = clicks + 1 WHERE alias = ?"

  let select_original_url_by_alias =
    (string ->? string)
    @@ "SELECT (original_url) FROM aliases WHERE alias = ? and "
    ^ expire_condition

  let select_alias_record =
    (string ->? t4 string string int (option string))
    @@ "SELECT * FROM aliases WHERE alias = ? and " ^ expire_condition
end

let insert_alias (module Db : Caqti_lwt.CONNECTION) ~alias ~original_url ~expire
    =
  let expire =
    match expire with
    | `Never -> "NULL"
    | `Minutes minutes -> Printf.sprintf "+%d minutes" minutes
  in

  Db.exec Q.insert_alias (alias, original_url, expire)

let find_original_url_by_alias (module Db : Caqti_lwt.CONNECTION) alias =
  Db.find_opt Q.select_original_url_by_alias alias

let find_alias_record (module Db : Caqti_lwt.CONNECTION) alias =
  Db.find_opt Q.select_alias_record alias

let update_clicks (module Db : Caqti_lwt.CONNECTION) alias =
  Db.exec Q.update_clicks alias
