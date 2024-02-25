let ( let* ) = Result.bind

(* let wait_for_result c = *)
(*   c#consume_input; *)
(*   while c#is_busy do *)
(*     ignore (Unix.select [Obj.magic c#socket] [] [] (10000.0)); *)
(*     c#consume_input *)
(*   done *)

(* let fetch_result c = *)
(*   wait_for_result c; *)
(*   c#get_result *)

(* let fetch_single_result c = *)
(*   match fetch_result c with *)
(*   | None -> assert false *)
(*   | Some r -> *)
(*     assert (fetch_result c = None); *)
(*     r *)

module Postgres = struct
  type config = { conninfo: string }

  let connect config =
    let conn = Pg.make ~conninfo:config.conninfo () in
    let socket = Pg.socket conn in

    (*
     * Create the execute function that also use the PGOCaml.connection to send a request to Postgres database. 
     * This function is used by the Connection.make function to create a new connection
     *)
    let execute
        (conn : Pg.t) (params : Dbcaml.Connection.param list) query :
        (string list list, Dbcaml.Res.execution_error) Dbcaml.Res.result =
      try
        let params = Pg.make_params conn params in
        let* query_id = Pg.prepare_query conn query params in
        let* status = Pg.send_prepared_query conn query_id params in

        (* TODO: investigate single-row mode *)
        match result#status with
        | Command_ok
        | Tuples_ok ->
          let res = result#get_all_lst in

          let rows = List.map (fun x -> List.map unescape_bytea x) res in
          Ok rows
        | Fatal_error -> Error (Dbcaml.Res.FatalError result#error)
        | Bad_response
        | Nonfatal_error ->
          Error (Dbcaml.Res.BadResponse result#error)
        | _ -> Error Dbcaml.Res.NoRows
      with
      | Postgresql.Error e ->
        Error (Dbcaml.Res.GeneralError (string_of_error e))
      | e -> Error (Dbcaml.Res.GeneralError (Printexc.to_string e))
    in

    (* Create a new connection while we also want to use to create a PID *)
    let* conn = Dbcaml.Connection.make ~conn:c ~execute () in

    Ok conn
end

let deserialize de input =
  let state = Wire.make input in
  Serde.deserialize (module Wire.De) state de

let connection conninfo =
  Dbcaml.Driver.Driver { driver = (module Postgres); config = { conninfo } }
