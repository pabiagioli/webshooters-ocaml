open Lwt
open Cohttp
open Cohttp_lwt_unix
open Cmdliner

let src = Logs.Src.create "cohttp.lwt.server" ~doc:"Cohttp Lwt server"
module Log = (val Logs.src_log src : Logs.LOG)

(* Server Params *)

let verb = Logs_cli.level ()

let host =
  let doc = "IP address to listen on." in
  Arg.(value & opt string "::" & info ["s"] ~docv:"HOST" ~doc)

let port =
  let doc = "TCP port to listen on." in
  Arg.(value & opt int 8080 & info ["p"] ~docv:"PORT" ~doc)

let tls =
  let doc = "TLS certificate files." in
  Arg.(value & opt (some (pair string string)) None & info ["tls"] ~docv:"CERT,KEY" ~doc)

(* Server Params *)

(* Connection Handlers *)

let conn_closed (ch,_conn) =
    Log.debug (fun m -> m "connection %s closed"
      (Sexplib.Sexp.to_string_hum (Conduit_lwt_unix.sexp_of_flow ch)))

let callback (ch,_conn) req body =
    try
    let uri = req |> Request.uri |> Uri.to_string in
    let meth = req |> Request.meth |> Code.string_of_method in
    let headers = req |> Request.headers |> Header.to_string in
    let path = Uri.path (Cohttp.Request.uri req) in
    (* Log the request to the console *)
      Log.debug (fun m -> m
        "%s %s %s"
        (Cohttp.(Code.string_of_method (Request.meth req)))
        path
        (Sexplib.Sexp.to_string_hum (Conduit_lwt_unix.sexp_of_flow ch)));
    body |> Cohttp_lwt.Body.to_string >|= (fun body ->
      (Printf.sprintf "Uri: %s\nMethod: %s\nHeaders\nHeaders: %s\nBody: %s"
         uri meth headers body))
    >>= (fun body -> Server.respond_string ~status:`OK ~body:body ())
    with
    |_ -> Server.respond_string ~status:`OK ~body:"body" ()
    

(* Connection Handlers *)

(* Server *)

let start_server port host tls () =
  Log.info (fun m -> m "Listening for HTTP request on: %s %d" host port);
  (*let info = Printf.sprintf "Served by Cohttp/Lwt listening on %s:%d" host port in*)
  let config = Server.make ~conn_closed ~callback  () in
  let mode = match tls with
    | Some (c, k) -> `TLS_native (
      (* `TLS means that conduit will do:
       match Sys.getenv "CONDUIT_TLS" with
       | "native" | "Native" | "NATIVE" -> Native
       | _ -> OpenSSL *)
      `Crt_file_path c, `Key_file_path k, `No_password, `Port port)
    | None -> `TCP (`Port port)
  in
  Conduit_lwt_unix.init ~src:host ()
  >>= fun ctx ->
  let ctx = Cohttp_lwt_unix.Net.init ~ctx () in
  Server.create ~ctx ~mode config

let lwt_start_server port host verbose tls =
  if verbose <> None then begin
    (* activate_debug sets the reporter *)
    Cohttp_lwt_unix.Debug.activate_debug ();
    Logs.set_level verbose
  end;
  Lwt_main.run (start_server port host tls ())

(* Server *)

(* CLI *)
let usage = "usage " ^ Sys.argv.(0) ^ " [DOCROOT]"

let cmd =
  let doc = "a simple http server" in
  let man = [
    `S "DESCRIPTION";
    `P "$(tname) sets up a simple http server with lwt as backend";
    `S "BUGS";
    `P "Report them via e-mail to <mirageos-devel@lists.xenproject.org>, or \
        on the issue tracker at <https://github.com/mirage/ocaml-cohttp/issues>";
  ] in
  Term.(pure lwt_start_server $ port $ host $ verb $ tls),
  Term.info "cohttp-server" ~version:Cohttp.Conf.version ~doc ~man

(* CLI *)

(* Main *)

let () =
  match Term.eval cmd with
  | `Error _ -> exit 1
  | _ -> exit 0

(* Main *)