# webshooters-ocaml
WebShooters made in OCaml

## Build
```
$ opam install cohttp cohttp-lwt-unix logs tls conduit cmdliner
$ make clear all
```

## Run HTTPS Server
- First create the CA certificates
```
$ ./certs-generator.sh
```
- Then run the default command
```
$ ./run-https.sh
```
