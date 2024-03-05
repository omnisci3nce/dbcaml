module Bs = Bytestring

open Riot.Logger.Make (struct
  let namespace = ["dbcaml"; "dbcaml_postgres_driver"]
end)

let ( let* ) = Result.bind

let ( let** ) = Option.bind

module Postgres = struct
  type config = { conninfo: string }

  let connect config =
    let* conn = Pg.connect config.conninfo in

    let* startup_response = Startup.start conn "postgres" "development" in

    let _ = Authentication.decode_authentication conn startup_response in

    let execute (_ : Pg.t) (_ : Dbcaml.Connection.param list) _ :
        (bytes, Dbcaml.Res.execution_error) Dbcaml.Res.result =
      Error (Dbcaml.Res.GeneralError "Not implemented")
    in

    (* Create a new connection while we also want to use to create a PID *)
    let* conn = Dbcaml.Connection.make ~conn ~execute () in

    Ok conn
end

let connection conninfo =
  Dbcaml.Driver.Driver { driver = (module Postgres); config = { conninfo } }