open Lwt
open Cmdliner

(** Server Starter *)
let start_server_impl port host tls () =
  Lwt.return begin 
    match tls with
      | Some (c, k) -> 
        begin 
          Logs.info (fun m->m "Listening for HTTPS requests on: https://%s:%d" host port); 
          Secureserver.start_server port host c k () 
        end
      | None -> failwith "HTTP/2 requires TLS/SSL HTTPS protocol"
  end

let start_server port host verbose tls =
  if verbose <> None then begin
      Logs.set_level verbose;
      Logs.set_reporter (Logs_fmt.reporter ())
    end;
    Lwt_main.run (start_server_impl port host tls ()) 
(** Server Starter *)

(** Server Params *)

let verb = Logs_cli.level ()

let host =
  let doc = "IP address to listen on." in
  Arg.(value & opt string "0.0.0.0" & info ["s"] ~docv:"HOST" ~doc)

let port =
  let doc = "TCP port to listen on." in
  Arg.(value & opt int 8443 & info ["p"] ~docv:"PORT" ~doc)

let tls =
  let doc = "TLS certificate files." in
  Arg.(value & opt (some (pair string string)) None & info ["tls"] ~docv:"CERT,KEY" ~doc)

(* Server Params *)

(** CLI *)
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
  Term.(const start_server $ port $ host $ verb $ tls),
  Term.info "webshooters" ~version:"0.1" ~doc ~man

(* CLI *)

(* Main *)

let () =
  match Term.eval cmd with
  | `Error _ -> exit 1
  | _ -> exit 0

(* Main *)