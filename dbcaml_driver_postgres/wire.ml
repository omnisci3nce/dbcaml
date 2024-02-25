type state = { value: string }

let make value = { value }

module De = struct
  type kind =
    | First
    | Rest

  type state = {
    value: string;
    kind: kind;
  }
end
