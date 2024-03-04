module Bs = Bytestring

type authentication_md5_password = { salt: string }

type authentication_sasl_continue = {
  salt: string;
  iterations: int;
  nonce: string;
  message: string;
}

type authentication_sasl_final = { verifier: string }

type authentication =
  | Ok
  | CleartextPassword
  | Md5Password of authentication_md5_password
  | Sasl of string
  | SaslContinue of authentication_sasl_continue
  | SaslFinal of authentication_sasl_final

exception Protocol_error of string

let decode_authentication _conn buf =
  let auth_message = Bs.to_string buf |> String.split_on_char '\n' in
  let auth_type = List.nth auth_message 1 |> String.trim in

  match auth_type with
  | "SCRAM-SHA-256" -> print_endline "matched on SCRAM-SHA-256"
  | "MD5" -> print_endline "matched on MD5"
  | "Password" -> print_endline "matched on password"
  | s -> Printf.printf "no match: %s" s
