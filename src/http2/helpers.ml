let string_of_unix_err err f p =
  Printf.sprintf "Unix_error (%s, %s, %s)"
    (Unix.error_message err) f p