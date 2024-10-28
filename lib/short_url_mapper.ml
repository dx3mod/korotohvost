module Record = struct
  type t = { original_url : string; metrics : metrics; expire : expire }
  and metrics = { views : int ref }
  and expire = Never | Date of float
end

module type S = sig
  val create_short_url :
    original_url:string ->
    alias:string ->
    expire:Record.expire ->
    (unit, [> `Exist ]) result

  val get_original_url : string -> (string, [> `Expired | `Not_found ]) result
  val get_alias_record : string -> Record.t option
end

module In_memory () = struct
  module Records = Hashtbl.Make (String)

  let urls : Record.t Records.t = Records.create 100

  let check_record_on_expire short_url_record =
    match short_url_record.Record.expire with
    | Date date when Unix.time () >= date -> `Expired
    | Never | Date _ -> `Live_yet

  let create_short_url ~original_url ~alias ~expire =
    let check alias =
      let url_map = Records.find urls alias in
      check_record_on_expire url_map
    in

    match check alias with
    | (exception Not_found) | `Expired ->
        Records.add urls alias
          { original_url; expire; metrics = { views = ref 0 } };
        Ok ()
    | `Live_yet -> Error `Exist

  let get_original_url alias =
    try
      let short_url_record = Records.find urls alias in
      match check_record_on_expire short_url_record with
      | `Live_yet ->
          incr short_url_record.metrics.views;
          Ok short_url_record.original_url
      | `Expired -> Error `Expired
    with Not_found -> Error `Not_found

  let get_alias_record alias = Records.find_opt urls alias
end
