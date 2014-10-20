
src/ppx_string.native: src/ppx_string.ml
	ocamlfind ocamlopt -o $@ $< -package ppx_tools -package ppx_deriving -package ppx_tools.metaquot -linkpkg

src_test/app.native: src_test/app.ml src/ppx_string.native
	ocamlfind ocamlopt -o $@ $< -ppx ./src/ppx_string.native

test: src_test/app.native
	./src_test/app.native

clean:
	rm -f {src,src_test}/*.{cmi,cmx,o,native}

