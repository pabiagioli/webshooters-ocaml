BUILDCMD= ocamlbuild 
PARAMS= -j 4 -use-ocamlfind -pkg cohttp-lwt-unix
SRC= -I src

.PHONY: all
all:    
		$(BUILDCMD) $(PARAMS) $(SRC) mainserver.native

clean: 
		$(BUILDCMD) -clean