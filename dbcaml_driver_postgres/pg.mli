module Bs = Bytestring

type t

(* Connect to the database *)
val connect : string -> (t, [> ]) result

val prepare : t -> string -> (t * Bs.t, [> ]) result
