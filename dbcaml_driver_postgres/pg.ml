open Riot

open Logger.Make (struct
  let namespace = ["dbcaml"; "dbcaml_postgres_driver"]
end)

let ( let* ) = Result.bind

type t = Net.Socket.stream_socket

type query_id = string

let connect conninfo =
  let* addr = Riot.Net.Addr.parse conninfo in
  let* conn = Net.Tcp_stream.connect addr in

  Ok conn
