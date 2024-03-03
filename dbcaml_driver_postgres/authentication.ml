type authentication =
  | Ok
  | CleartextPassword
  | Md5Password of authentication_md5_password
  | Sasl of bytes
  | SaslContinue of authentication_sasl_continue
  | SaslFinal of authentication_sasl_final

and authentication_md5_password = { salt: bytes }

and authentication_sasl_continue = {
  salt: bytes;
  iterations: int;
  nonce: string;
  message: string;
}

and authentication_sasl_final = { verifier: bytes }

let authentication conn data = print_endline ""
