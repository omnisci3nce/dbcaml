let ( let* ) = Result.bind

module Postgres = struct
  type config = { conninfo: string }

  let connect config =
    let conn = Pg.make ~conninfo:config.conninfo () in
    let _ = Pg.socket conn in

    (*
     * Create the execute function that also use the PGOCaml.connection to send a request to Postgres database. 
     * This function is used by the Connection.make function to create a new connection
     *)
    let execute
        (conn : Postgresql.connection)
        (params : Dbcaml.Connection.param list)
        query : (bytes, Dbcaml.Res.execution_error) Dbcaml.Res.result =
      try
        let params = Pg.make_params conn params in

        let query_id = Pg.prepare_query conn query params in

        let _ = Pg.send_prepared_query conn (Result.get_ok query_id) params in

        let socket = Pg.socket conn in
        let _ = socket in

        Error (Dbcaml.Res.GeneralError "Not implemented")
      with
      | Postgresql.Error e ->
        Error (Dbcaml.Res.GeneralError (Postgresql.string_of_error e))
      | e -> Error (Dbcaml.Res.GeneralError (Printexc.to_string e))
    in

    (* Create a new connection while we also want to use to create a PID *)
    let* conn = Dbcaml.Connection.make ~conn ~execute () in

    Ok conn
end

let deserialize de input =
  let state = Wire.make input in
  Serde.deserialize (module Wire.De) state de

let connection conninfo =
  Dbcaml.Driver.Driver { driver = (module Postgres); config = { conninfo } }
