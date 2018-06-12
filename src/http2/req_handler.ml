open Lwt
open Helpers

(** Request Callback Function :
    Lwt_io.input_channel,Lwt_io.output_channel->Lwt_unix.sockaddr -> unit Lwt.t
*)
let req_callback (ic,oc) addr = 
    (*Lwt_io.read_lines ic |> Lwt_stream.iter_s (fun line ->
    Logs.debug (fun m-> m "handler + %s" line);*)
    Logs.debug (fun m-> m "HTTP/1.1 200 OK \r\nContent-Type: text/html\r\nContent-Length: 0\r\n\r\n\r\n");
    Lwt_io.write_line oc "HTTP/1.1 200 OK \r\nContent-Type: text/html\r\nContent-Length: 0\r\n\r\n\r\n"(*line)*)

(** Request Handler Function :
    Lwt_io.input_channel,Lwt_io.output_channel->Lwt_unix.sockaddr -> unit Lwt.t
*)
let req_handler (ic,oc) addr = 
    try%lwt 
        Logs.debug(fun m -> m "entered req handler"); 
        let res = req_callback (ic,oc) addr in
        Logs.debug(fun m -> m "finished req handler");
        res
    with 
        | Tls_lwt.Tls_alert a ->
            Logs.debug (fun m-> m "handler: %s" (Tls.Packet.alert_type_to_string a))  |> Lwt.return
        | Tls_lwt.Tls_failure a ->
            Logs.debug (fun m-> m "handler: %s" (Tls.Engine.string_of_failure a)) |> Lwt.return
        | Unix.Unix_error (e, f, p) ->
            Logs.debug (fun m-> m "handler: %s" (string_of_unix_err e f p)) |> Lwt.return
        | exn -> Logs.debug (fun m-> m "handler: %s" (Printexc.to_string exn)) |> Lwt.return