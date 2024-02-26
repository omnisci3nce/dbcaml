open Riot

let ( let* ) = Result.bind

type t = Net.Socket.stream_socket

type query_id = string

(*
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
*)

let connect conninfo =
  let* net_addr = Net.Addr.parse conninfo in

  let* conn = Net.Tcp_stream.connect net_addr in

  Ok conn
