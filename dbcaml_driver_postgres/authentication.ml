module Bs = Bytestring

type authentication =
  | Ok
  | CleartextPassword
  | Md5Password of { salt: bytes }
  | Sasl of bytes
  | SaslContinue of {
      salt: bytes;
      iterations: int;
      nonce: string;
      message: string;
    }
  | SaslFinal of { verifier: bytes }

let authentication _conn data =
  Printf.printf
    "%ld"
    (Bytes.get_int32_be (Bytes.of_string (Bs.to_string data)) 0)
