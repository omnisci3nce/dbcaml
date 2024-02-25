open Riot

type t = Postgresql.connection

type query_id = string

type params = {
  values : string array;
  types : Postgresql.oid array
}

let make ~conninfo () = new Postgresql.connection ~conninfo ()

let socket conn = 
  let sock: Net.Tcp_stream.t = Obj.magic (conn#socket) in
  sock

let map_params conn params = 
  let open Postgresql in
  let values, types = params
        |> List.map (fun x ->
            match x with
               | Dbcaml.Connection.String s ->
                   (conn#escape_string s, oid_of_ftype TEXT)
               | Dbcaml.Connection.Number i ->
                   (string_of_int i, oid_of_ftype INT8)
               | Dbcaml.Connection.Float f ->
                   (string_of_float f, oid_of_ftype FLOAT8)
               | Dbcaml.Connection.Bool b ->
                   (string_of_bool b, oid_of_ftype BOOL)
               | Dbcaml.Connection.Null -> (null, oid_of_ftype TEXT))
        |> List.split
  in
  {
    values = Array.of_list values;
    types  = Array.of_list types
}

let prepare_query conn query params = 
  let query_id = Printf.sprintf "dbcaml_%s" (Base64.encode_string query) in
  let result: int = conn#send_prepare query_id ~param_types:params.types query in
  (* ... *)
  (* assert ((fetch_single_result c)#status = Command_ok); *)
  Ok query_id

let send_prepared_query conn query_id params = 
  conn#send_query_prepared ~params:params.values query_id;
  (* let result = fetch_single_result c in *)
  Ok ()
