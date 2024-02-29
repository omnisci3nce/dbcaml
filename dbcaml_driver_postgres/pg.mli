module Bs = Bytestring

type t

val connect : string -> (t, Rio.io_error) result

val prepare : t -> string -> (t * Bs.t, Rio.io_error) result
