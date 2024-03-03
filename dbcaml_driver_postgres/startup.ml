module Bs = Bytestring

let ( let* ) = Result.bind

let startup_message username database =
  (* Protocol version 3.0 *)
  let protocol_version = Encode.int32 196608l in
  let user_param = "user\000" ^ username ^ "\000" in
  let database_param = "database\000" ^ database ^ "\000" in
  let params = user_param ^ database_param ^ "\000" in

  Bytes.to_string protocol_version ^ params

let start conn username database =
  let startup_message = startup_message username database in
  let* _ = Pg.send conn startup_message in

  let* (_, data) = Pg.receive conn in

  Ok data
