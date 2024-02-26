open Riot

open Logger.Make (struct
  let namespace = ["Dbcaml example"]
end)

let () =
  Riot.run @@ fun () ->
  let _ = Logger.start () |> Result.get_ok in

  Logger.set_log_level (Some Logger.Info);

  Logger.info (fun f -> f "Starting application");

  let driver =
    Dbcaml_driver_postgres.connection
      "postgresql://postgres:mysecretpassword@localhost:6432/development"
  in

  let _ = Dbcaml.Driver.connect driver in

  sleep 1.1;

  ()

(*
    (* Fetch 1 row from the database *)
    (match
       Voj.fetch_one
         pool_id
         ~params:[Dbcaml.Connection.Number 1]
         "select * from users where id = $1"
     with
    | Ok x ->
      let rows = Voj.Row.row_to_type x in
      (* Iterate over each column and print it's values *)
      List.iter (fun x -> print_endline x) rows
    | Error x -> print_endline (Dbcaml.Res.execution_error_to_string x));

    (* Fetch multiple rows from the database *)
    (match
       Voj.fetch_many
         pool_id
         ~params:[Dbcaml.Connection.Number 1]
         "select * from users where id = $1"
     with
    | Ok x ->
      List.iter
        (fun x ->
          let rows = Voj.Row.row_to_type x in
          (* Iterate over each column and print it's values *)
          List.iter (fun x -> print_endline x) rows)
        x
    | Error x -> print_endline (Dbcaml.Res.execution_error_to_string x));

    (* Exec a query to the database *)
    (match
       Voj.exec
         pool_id
         ~params:[Dbcaml.Connection.Number 1]
         "select * from users where id = $1"
     with
    | Ok _ -> print_endline "Executed successfully"
    | Error x -> print_endline (Dbcaml.Res.execution_error_to_string x));

    () *)
