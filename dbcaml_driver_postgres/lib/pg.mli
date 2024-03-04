module Bs = Bytestring

type t

(* FIXME: we shouldn't add this error types here. I just need it to be able to compile until I figure stuff out *)

(* Connect to the database *)
val connect :
  string ->
  ( t,
    [> `Closed
    | `Connection_closed
    | `Eof
    | `Exn of exn
    | `Msg of string
    | `No_info
    | `Noop
    | `Process_down
    | `Timeout
    | `Unix_error of Unix.error
    | `Would_block
    ] )
  result

val send :
  t ->
  string ->
  ( t,
    [> `Closed
    | `Connection_closed
    | `Eof
    | `Exn of exn
    | `Msg of string
    | `No_info
    | `Noop
    | `Process_down
    | `Timeout
    | `Unix_error of Unix.error
    | `Would_block
    ] )
  result

val receive :
  t ->
  ( t * Bs.t,
    [> `Closed
    | `Connection_closed
    | `Eof
    | `Exn of exn
    | `Msg of string
    | `No_info
    | `Noop
    | `Process_down
    | `Timeout
    | `Unix_error of Unix.error
    | `Would_block
    ] )
  result
