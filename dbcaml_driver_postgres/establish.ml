module Bs = Bytestring

let ( let* ) = Result.bind

let start conn username database =
  let* _ = Bs.of_string (Printf.sprintf "user=%s" username) |> Pg.send conn in
  let* _ =
    Bs.of_string (Printf.sprintf "database=%s" database) |> Pg.send conn
  in

  let* (_, data) = Pg.receive conn in

  print_endline (Printf.sprintf "response: %s" (Bs.to_string data));

  Ok data
