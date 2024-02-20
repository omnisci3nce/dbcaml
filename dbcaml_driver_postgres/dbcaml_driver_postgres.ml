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
    let execute (conn : connection) (params : Dbcaml.Param.t list) query :
        (string list list, Dbcaml.Res.execution_error) Dbcaml.Res.result =
      try
        let array_params =
          params
          |> List.map (fun value ->
                 match value with
                 | Dbcaml.Param.String s -> s
                 | Dbcaml.Param.Number i -> string_of_int i
                 | Dbcaml.Param.Float i -> string_of_float i
                 | Dbcaml.Param.Bool i -> string_of_bool i
                 | Dbcaml.Param.Null -> null
                 | Dbcaml.Param.Array a ->
                   List.map
                     (fun value ->
                       match value with
                       | Dbcaml.Param.String s -> Printf.sprintf "'%s'" s
                       | Dbcaml.Param.Number i ->
                         Printf.sprintf "'%s'" (string_of_int i)
                       | Dbcaml.Param.Float i ->
                         Printf.sprintf "'%s'" (string_of_float i)
                       | Dbcaml.Param.Bool i ->
                         Printf.sprintf "'%s'" (string_of_bool i)
                       | Dbcaml.Param.Null -> Printf.sprintf "'%s'" null
                       | Dbcaml.Param.Array _ -> "")
                     a
                   |> String.concat ",")
          |> List.map (fun x -> conn#escape_string x)
          |> Array.of_list
        in

        conn#send_query ~params:array_params query;

        let result = fetch_single_result c in

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
