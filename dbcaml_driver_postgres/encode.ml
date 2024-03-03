(* Function to encode an int32 to a 4-byte string *)
let int32 i =
  let b = Bytes.create 4 in
  Bytes.set b 0 (char_of_int (Int32.to_int (Int32.shift_right i 24) land 0xFF));
  Bytes.set b 1 (char_of_int (Int32.to_int (Int32.shift_right i 16) land 0xFF));
  Bytes.set b 2 (char_of_int (Int32.to_int (Int32.shift_right i 8) land 0xFF));
  Bytes.set b 3 (char_of_int (Int32.to_int i land 0xFF));
  b
