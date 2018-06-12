open Opium.Std

let print_param = get "/hello/:name" 
begin 
fun req ->
    `String ("Hello " ^ param req "name" ^ " y lalalala") |> respond'
end

let _ =
  App.empty
  |> print_param
  |> App.run_command