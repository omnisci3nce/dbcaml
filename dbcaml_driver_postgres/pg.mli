open Riot

type t = Postgresql.connection

type params = {
  types: Postgresql.ftype array;
  values: string array;
}

type query_id = string

val make : conninfo:string -> unit -> t

val socket : t -> Net.Socket.stream_socket

val make_params : t -> Dbcaml.Connection.param list -> params

val prepare_query :
  t -> string -> params -> (query_id, Dbcaml.Res.execution_error) result

val send_prepared_query :
  t -> query_id -> params -> (query_id, Dbcaml.Res.execution_error) result
