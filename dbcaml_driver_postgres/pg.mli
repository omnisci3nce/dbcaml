open Riot

type t

type query_id

val connect : string -> (Net.Socket.stream_socket, [> IO.io_error ]) result
