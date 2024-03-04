open OUnit2

let test_addition _ = assert_equal "hello" "hello"

let suite = "test_math_utils" >::: ["test_addition" >:: test_addition]

let () = run_test_tt_main suite
