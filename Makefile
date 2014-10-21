
src/ppx_string.native: src/ppx_string.ml
	ocamlfind ocamlopt -o $@ $< -package ppx_tools -package ppx_deriving -package ppx_tools.metaquot -linkpkg

src_test/app.native: src_test/app.ml src/ppx_string.native
	ocamlfind ocamlopt -o $@ $< -ppx ./src/ppx_string.native

test: src_test/app.native
	./src_test/app.native

clean:
	rm -f {src,src_test}/*.{cmi,cmx,o,native}


################################################################################
# Emacs flymake

BUILD_DIR = build

FLYMAKE_LOG=$(BUILD_DIR)/flymake-log.txt
FLYMAKE_BUILD=$(BUILD_DIR)/flymake-last-build.txt

.PHONY: flymake.ml.check
flymake.ml.check:
	@(ocamlfind ocamlopt -package ppx_tools -package ppx_deriving -package ppx_tools.metaquot -c $(CHK_SOURCES) -o /tmp/flymake_temp.cmx 2>&1) | sed 's/_flymake//g' | tee $(FLYMAKE_BUILD)

.PHONY: flymake.mli.check
flymake.mli.check: flymake.ml.check

.PHONY: flymake_log
flymake_log:
	@echo "$(shell date '+%Y-%m-%d %H:%M:%S') checking $(CHK_SOURCES)" >> $(FLYMAKE_LOG)

.PHONY: check-syntax
check-syntax: $(BUILD_DIR)/.exists flymake_log flymake$(suffix $(CHK_SOURCES)).check

