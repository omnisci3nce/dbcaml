open Serde

type state = { value: string }

let make value = { value }

module De = struct
  type kind =
    | First
    | Rest

  type state = {
    reader: Parser.t;
    mutable kind: kind;
  }

  let nest { reader; _ } = { reader; kind = First }

  let deserialize_int8 _self state = Parser.read_int8 state.reader

  let deserialize_int16 _self state = Parser.read_int state.reader

  let deserialize_int31 _self state = Parser.read_int state.reader

  let deserialize_int32 _self state = Parser.read_int32 state.reader

  let deserialize_int64 _self state = Parser.read_int64 state.reader

  let deserialize_float _self state = Parser.read_float state.reader

  let deserialize_bool _self state = Parser.read_bool state.reader

  let deserialize_string _self state = Parser.read_string state.reader

  let deserialize_option self { reader; _ } de =
    match Parser.peek reader with
    | Some 'n' ->
      let* () = Parser.read_null reader in
      Ok None
    | _ ->
      let* v = De.deserialize self de in
      Ok (Some v)

  let deserialize_identifier self _state visitor =
    let* str = De.deserialize_string self in
    Visitor.visit_string self visitor str

  let deserialize_sequence self s ~size de =
    let* () = Parser.read_open_bracket s.reader in
    let* v = De.deserialize self (de ~size) in
    let* () = Parser.read_close_bracket s.reader in
    Ok v

  let deserialize_element self s de =
    match Parser.peek s.reader with
    | Some ']' -> Ok None
    | _ ->
      let* () =
        if s.kind = First then
          Ok ()
        else
          Parser.read_comma s.reader
      in
      s.kind <- Rest;
      let* v = De.deserialize self de in
      Ok (Some v)

  let deserialize_unit_variant _self _state = Ok ()

  let deserialize_newtype_variant self { reader; _ } de =
    let* () = Parser.read_colon reader in
    De.deserialize self de

  let deserialize_tuple_variant self { reader; _ } ~size de =
    let* () = Parser.read_colon reader in
    De.deserialize_sequence self size de

  let deserialize_record_variant self { reader; _ } ~size de =
    let* () = Parser.read_colon reader in
    De.deserialize_record self "" size (de ~size)

  let deserialize_variant self { reader; _ } visitor ~name:_ ~variants:_ =
    Parser.skip_space reader;
    match Parser.peek reader with
    | Some '{' ->
      let* () = Parser.read_object_start reader in
      Parser.skip_space reader;
      let* value = Visitor.visit_variant self visitor in
      Parser.skip_space reader;
      let* () = Parser.read_object_end reader in
      Ok value
    | Some '"' -> Visitor.visit_variant self visitor
    | _ -> assert false

  let deserialize_record self { reader; _ } ~name:_ ~size:_ fields =
    Parser.skip_space reader;
    match Parser.peek reader with
    | Some '{' ->
      let* () = Parser.read_object_start reader in
      Parser.skip_space reader;
      let* value = De.deserialize self fields in
      Parser.skip_space reader;
      let* () = Parser.read_object_end reader in
      Ok value
    | Some c -> failwith (Format.sprintf "what: %c" c)
    | None -> failwith "unexpected eof"

  let deserialize_key self s visitor =
    Parser.skip_space s.reader;
    match Parser.peek s.reader with
    | Some '}' -> Ok None
    | _ ->
      let* () =
        if s.kind = First then
          Ok ()
        else
          Parser.read_comma s.reader
      in
      s.kind <- Rest;
      let* str = De.deserialize_string self in
      let* key = Visitor.visit_string self visitor str in
      let* () = Parser.read_colon s.reader in
      Ok (Some key)

  let deserialize_field self s ~name:_ de =
    Parser.skip_space s.reader;
    De.deserialize self de
end
