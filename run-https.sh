#!/bin/sh

#./certs-generator.sh
make clean all
./mainserver.native -s0.0.0.0 -p8443  --verbosity=info --tls=server.pem,server.key
