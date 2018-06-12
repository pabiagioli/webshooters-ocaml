open Lwt
open Req_handler
open Helpers

let max_pending_reqs = 10

(** Accept TLS and Configure Socket *)
let accept sock tls =
  let config = Tls.Config.(server ~reneg:true ~certificates:(`Single tls) ~ciphers:Ciphers.supported ()) in 
  Lwt.return (Lwt_main.run (Tls_lwt.accept_ext config sock))

(** __Request Listener Function :__
    ```Lwt_unix.file_descr->Tls.Config.certchain -> [> `L of string ] Lwt.t```
*)
let rec req_listener socket tls = 
  try%lwt
    Logs.debug(fun m -> m "entered req listener"); 
    let%lwt listener = Lwt.map (fun r -> `R r) (accept socket tls ) in
    match listener with 
        | `R (channels, addr) -> 
        begin 
            Lwt.async(fun ()-> req_handler channels addr);
            req_listener socket tls
        end
        | `L (msg) ->  
            req_listener socket tls 
  with
   | Unix.Unix_error (e, f, p) ->  Logs.debug (fun m-> m "unix error"); return (`L (string_of_unix_err e f p))
   | Tls_lwt.Tls_alert a -> Logs.debug (fun m-> m "tls alert"); return (`L (Tls.Packet.alert_type_to_string a))
   | Tls_lwt.Tls_failure f -> Logs.debug (fun m-> m "tls failure"); return (`L (Tls.Engine.string_of_failure f))
   | exn -> return (`L (Printexc.to_string exn) )

(** __Create Server Socket Function :__
    ```string-> int -> Lwt_unix.file_descr Lwt.t```
*)
let create_srv_socket addr port =
  Logs.debug (fun m-> m "opening tcp socket on %s %d" addr port);
  let sockaddr = Unix.ADDR_INET (Unix.inet_addr_of_string addr, port) in
  let socket = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Lwt_unix.setsockopt socket Unix.SO_REUSEADDR true;
  let%lwt _ = Lwt_unix.bind socket sockaddr in
  Logs.debug (fun m-> m "max pending reqs: %d" max_pending_reqs);
  Lwt_unix.listen socket max_pending_reqs;
  Lwt.return socket

(**
    __Start Server Function :__
    ``` int -> string -> Lwt_io.file_name -> Lwt_io.file_name -> unit -> <fun>
*)
let start_server port host cert priv_key () =
  let%lwt socket = create_srv_socket host port in
  let tls = Lwt_main.run (X509_lwt.private_of_pems ~cert ~priv_key) in
  req_listener socket tls