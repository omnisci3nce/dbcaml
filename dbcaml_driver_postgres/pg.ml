open Riot

(* let wait_for_result c = *)
(*   c#consume_input; *)
(*   while c#is_busy do *)
(*     ignore (Unix.select [Obj.magic c#socket] [] [] (10000.0)); *)
(*     c#consume_input *)
(*   done *)

(* let fetch_result c = *)
(*   wait_for_result c; *)
(*   c#get_result *)

(* let fetch_single_result c = *)
(*   match fetch_result c with *)
(*   | None -> assert false *)
(*   | Some r -> *)
(*     assert (fetch_result c = None); *)
(*     r *)

type params = {
  values: string array;
  types: Postgresql.oid array;
}

type query_id = string

let make ~conninfo () = new Postgresql.connection ~conninfo ()

let socket conn =
  let sock : Net.Tcp_stream.t = Obj.magic conn#socket in
  sock

let make_params (conn : Postgresql.connection) params : params =
  let (values, types) =
    params
    |> List.map (fun x ->
           match x with
           | Dbcaml.Connection.String s ->
             (conn#escape_string s, Postgresql.oid_of_ftype TEXT)
           | Dbcaml.Connection.Number i ->
             (string_of_int i, Postgresql.oid_of_ftype INT8)
           | Dbcaml.Connection.Float f ->
             (string_of_float f, Postgresql.oid_of_ftype FLOAT8)
           | Dbcaml.Connection.Bool b ->
             (string_of_bool b, Postgresql.oid_of_ftype BOOL)
           | Dbcaml.Connection.Null ->
             (Postgresql.null, Postgresql.oid_of_ftype TEXT))
    |> List.split
  in

  { values = Array.of_list values; types = Array.of_list types }

let prepare_query (conn : Postgresql.connection) query params =
  let query_id = Printf.sprintf "dbcaml_%s" (Base64.encode_string query) in

  conn#send_prepare query_id ~param_types:params.types query;

  match conn#status with
  | Postgresql.Ok -> Ok query_id
  | _ ->
    let error_message : string = conn#error_message in
    Error error_message

let send_prepared_query (conn : Postgresql.connection) query_id params =
  try
    conn#send_query_prepared ~params:params.values query_id;

    (* let result = fetch_single_result c in *)
    Ok query_id
  with
  | Postgresql.Error _ ->
    let error_message : string = conn#error_message in
    Error error_message
