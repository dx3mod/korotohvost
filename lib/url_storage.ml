type expire = Never | Date of float

module type S = sig
  val create :
    orig:string -> short:string -> expire:expire -> (unit, [> `Exist ]) result

  val get : short:string -> (string, [> `Expired | `Not_found ]) result
end

module In_memory_storage () = struct
  module Table = Hashtbl.Make (String)

  type url_map = { original_url : string; expire : expire }

  let table : url_map Table.t = Table.create 100

  let check_on_expire url_map =
    match url_map.expire with
    | Date date when Unix.time () >= date -> `Expired
    | Never | Date _ -> `Live_yet

  let create ~orig ~short ~expire =
    let check short =
      let url_map = Table.find table short in
      check_on_expire url_map
    in

    match check short with
    | (exception Not_found) | `Expired ->
        Table.add table short { original_url = orig; expire };
        Ok ()
    | `Live_yet -> Error `Exist

  let get ~short =
    try
      let url_map = Table.find table short in
      match check_on_expire url_map with
      | `Live_yet -> Ok url_map.original_url
      | `Expired -> Error `Expired
    with Not_found -> Error `Not_found
end
