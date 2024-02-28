type t

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
