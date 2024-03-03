module Bs = Bytestring
open Riot

open Logger.Make (struct
  let namespace = ["dbcaml"; "dbcaml_postgres_driver"]
end)

let ( let* ) = Result.bind

type t =
  | Conn : {
      writer: 'socket IO.Writer.t;
      reader: 'socket IO.Reader.t;
      uri: Uri.t;
      addr: Net.Addr.stream_addr;
    }
      -> t

(*  2. Set correct bytes length *)
let send (Conn { writer; _ } as conn) data =
  debug (fun f ->
      let bufs = Bs.to_iovec data in
      f "sending %d octets (iovec)" (Rio.Iovec.length bufs));

  let message_length =
    Encode.int32
      (Int32.of_int
         (String.length data
         (* for protocol version *)
         + 4
         (* for message length itself *)
         + 4))
  in

  let buf = Bs.to_string (Bytes.to_string message_length ^ data) in
  let* () = IO.write_all writer ~buf in
  Ok conn

let receive (Conn { reader; _ } as conn) =
  let* data = Bs.with_bytes (fun buf -> IO.read reader buf) in
  Ok (conn, data)

let make_connection ~reader ~writer ~uri ~addr =
  Conn { writer; reader; uri; addr }
(*
module Auth = struct
  let () = Mirage_crypto_rng_unix.initialize (module Mirage_crypto_rng.Fortuna)

  let make_default authenticator = Tls.Config.client ~authenticator ()

  let default () =
    let time () = Some (Ptime_clock.now ()) in
    let decode_pem ca =
      let ca = Cstruct.of_string ca in
      let cert = X509.Certificate.decode_pem ca in
      Result.get_ok cert
    in
    let cas = List.map decode_pem Ca_store.certificates in
    let authenticator = X509.Authenticator.chain_of_trust ~time cas in
    make_default authenticator
end
*)

let connect conninfo =
  let uri = Uri.of_string conninfo in
  let* addr = Riot.Net.Addr.of_uri uri in
  let* sock = Net.Tcp_stream.connect addr in

  (* FIXME: I don't think we can use SSL on localhost. Maybe listen on some "sslmode" flag?
      let config = Auth.default () in
      let* host =
        let host = Uri.host_with_default ~default:"0.0.0.0" uri in
        let* domain_name = Domain_name.of_string host in
        Domain_name.host domain_name
      in
     let tls_sock = SSL.of_client_socket ~host ~config sock in
     let (reader, writer) = SSL.(to_reader tls_sock, to_writer tls_sock) in
  *)
  let (reader, writer) = Net.Tcp_stream.(to_reader sock, to_writer sock) in

  let conn = make_connection ~reader ~writer ~addr ~uri in

  Ok conn
