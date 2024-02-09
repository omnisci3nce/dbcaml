type ('success, 'error) result =
  | Ok of 'success
  | Error of 'error

type connection_error =
  | ConnectionError of string
  | AuthenticationError of string
  | GeneralError of string

type execution_error =
  | ExecutionError of string
  | NoRows
  | GeneralError of string

let connection_error_to_string = function
  | ConnectionError msg -> Printf.sprintf "DBCaml Connection Error: %s" msg
  | AuthenticationError msg ->
    Printf.sprintf "DBCaml Authentication Error: %s" msg
  | GeneralError msg -> Printf.sprintf "DBCaml General Connection Error: %s" msg

let execution_error_to_string = function
  | ExecutionError msg -> Printf.sprintf "DBCaml Execution Error: %s" msg
  | NoRows -> Printf.sprintf "DBCaml Execution Error: No rows in result"
  | GeneralError msg -> Printf.sprintf "DBCaml Execution Error: %s" msg
