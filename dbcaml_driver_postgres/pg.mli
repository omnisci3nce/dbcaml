open Riot

type params

type query_id

val make : conninfo:string -> unit -> Postgresql.connection

val socket : Postgresql.connection -> Net.Socket.stream_socket

val make_params :
  Postgresql.connection -> Dbcaml.Connection.param list -> params

val prepare_query :
  Postgresql.connection -> string -> params -> (query_id, string) result

val send_prepared_query :
  Postgresql.connection -> query_id -> params -> (query_id, string) result
