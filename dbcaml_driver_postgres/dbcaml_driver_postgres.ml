open Postgresql

let ( let* ) = Result.bind

let wait_for_result c =
  c#consume_input;
  while c#is_busy do
    ignore (Unix.select [Obj.magic c#socket] [] [] (-1.0));
    c#consume_input
  done

let fetch_result c =
  wait_for_result c;
  c#get_result

let fetch_single_result c =
  match fetch_result c with
  | None -> assert false
  | Some r ->
    assert (fetch_result c = None);
    r

module Postgres = struct
  type config = { conninfo: string }

  let connect config =
    let c = new connection ~conninfo:config.conninfo () in

    (*
     * Create the execute function that also use the PGOCaml.connection to send a request to Postgres database. 
     * This function is used by the Connection.make function to create a new connection
     *)
    let execute
        (conn : connection) (params : Dbcaml.Connection.param list) query :
        (string list list, Dbcaml.Res.execution_error) Dbcaml.Res.result =
      try
        let p =
          params
          |> List.map (fun x ->
                 match x with
                 | Dbcaml.Connection.String s ->
                   (conn#escape_string s, oid_of_ftype TEXT)
                 | Dbcaml.Connection.Number i ->
                   (string_of_int i, oid_of_ftype INT8)
                 | Dbcaml.Connection.Float f ->
                   (string_of_float f, oid_of_ftype FLOAT8)
                 | Dbcaml.Connection.Bool b ->
                   (string_of_bool b, oid_of_ftype BOOL)
                 | Dbcaml.Connection.Null -> (null, oid_of_ftype TEXT))
          |> Array.of_list
        in

        let array_params = Array.map fst p in
        let param_types = Array.map snd p in

        let stmt = Printf.sprintf "dbcaml_%s" (Base64.encode_string query) in

        c#send_prepare stmt ~param_types query;

        assert ((fetch_single_result c)#status = Command_ok);

        c#send_query_prepared ~params:array_params stmt;

        let result = fetch_single_result c in

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

(*Create a new postgres driver using the module Postgress and the config provided *)

let connection conninfo =
  Dbcaml.Driver.Driver { driver = (module Postgres); config = { conninfo } }
