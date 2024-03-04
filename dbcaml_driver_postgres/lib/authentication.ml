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
  print_endline (Bs.to_string buf);
  let first_line =
    String.split_on_char '\n' (Bs.to_string buf)
    |> List.hd
    |> String.trim
    |> String.uppercase_ascii
  in
  Printf.printf ";%s;" first_line;

  match first_line with
  | "R" -> print_endline "is R"
  | s -> print_endline s
