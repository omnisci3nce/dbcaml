module Bs = Bytestring

let ( let* ) = Result.bind

let startup_param conn key value =
  let* _ = Bs.of_string key |> Pg.send conn in
  let* _ = Bs.of_string value |> Pg.send conn in

  Ok ()

(* Function to encode an int32 to a 4-byte string *)
let encode_int32 i =
  let open Int32 in
  Bs.of_string
    (Printf.sprintf
       "%d%d%d%d"
       (to_int (shift_right i 24) land 0xFF)
       (to_int (shift_right i 16) land 0xFF)
       (to_int (shift_right i 8) land 0xFF)
       (to_int i land 0xFF))

let startup_message username database =
  (* Protocol version 3.0 *)
  let protocol_version = encode_int32 196608l in
  let user_param = "user\000" ^ username ^ "\000" in
  let database_param = "database\000" ^ database ^ "\000" in
  let params = user_param ^ database_param ^ "\000" in
  let message_length =
    encode_int32
      (Int32.of_int
         (String.length params
         (* for protocol version *)
         + 4
         (* for message length itself *)
         + 4))
  in
  Bs.to_string message_length ^ Bs.to_string protocol_version ^ params

let start conn username database =
  let startup_msg = startup_message username database in
  print_endline startup_msg;
  let* _ = Pg.send conn (Bs.of_string startup_msg) in

  let* (_, data) = Pg.receive conn in

  print_endline (Printf.sprintf "response: %s" (Bs.to_string data));

  Ok data
