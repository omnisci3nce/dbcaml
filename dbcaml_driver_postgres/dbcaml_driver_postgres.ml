let ( let* ) = Result.bind

module Postgres = struct
  type config = { conninfo: string }

  let connect config =
    let* conn = Pg.connect config.conninfo in

    let execute
        (_ : Riot.Net.Socket.stream_socket) (_ : Dbcaml.Connection.param list) _
        : (bytes, Dbcaml.Res.execution_error) Dbcaml.Res.result =
      Error (Dbcaml.Res.GeneralError "Not implemented")
    in

    (* Create a new connection while we also want to use to create a PID *)
    let* conn = Dbcaml.Connection.make ~conn ~execute () in

    Ok conn
end

let connection conninfo =
  Dbcaml.Driver.Driver { driver = (module Postgres); config = { conninfo } }
