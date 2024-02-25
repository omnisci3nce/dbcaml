open Riot

type t
type params
type query_id

val make : conninfo:string -> unit -> t

val socket : t -> Net.Socket.stream_socket

val make_params :
t ->
Dbcaml.Connection.param list ->
params

val prepare_query : t -> string -> params -> (query_id, string) result
