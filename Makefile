
PPX_STRING_PACKAGES = -package ppx_tools -package ppx_tools.metaquot -package sedlex
OCAMLOPT_FLAGS += -bin-annot -annot

.PHONY: all
all: src/ppx_string_interpolate src_test/app

src_test/%.cmx: src_test/%.ml
	ocamlfind ocamlopt -c -o $@ $< $(OCAMLOPT_FLAGS) $(PPX_STRING_PACKAGES) -ppx ./src/ppx_string_interpolate

src_test/%: src_test/%.cmx src/ppx_string_interpolate
	ocamlfind ocamlopt -o $@ $< $(OCAMLOPT_FLAGS) -ppx ./src/ppx_string_interpolate -linkpkg

%.cmx: %.ml
	ocamlfind ocamlopt -c -o $@ $< $(OCAMLOPT_FLAGS) $(PPX_STRING_PACKAGES)

src/ppx_string_interpolate: src/ppx_string_interpolate.cmx
	ocamlfind ocamlopt -o $@ $< $(OCAMLOPT_FLAGS) $(PPX_STRING_PACKAGES) -linkpkg

.PHONY: clean
clean:
	rm -f {src,src_test}/*.{cmi,cmx,o} src/ppx_string_interpolate src_test/app
	$(foreach case, $(FAIL_CASES), rm -f src_test/fail_$(case).{out,test})


INSTALL_FILES = META src/ppx_string_interpolate

.PHONY: install
install:
	ocamlfind install ppx_string_interpolate $(INSTALL_FILES)

.PHONY: uninstall
uninstall:
	ocamlfind remove ppx_string_interpolate

################################################################################
# Tests

FAIL_CASES = invalid_var invalid_var_name no_closing_paren unescaped_dollar dollar_at_end_of_string

src_test/fail_%.test src_test/fail_%.out: src_test/fail_%.ml
	-(ocamlfind ocamlopt -o $@ $< -ppx ./src/ppx_string_interpolate 2>&1) > $(@:.test=.out)
	grep "File \"$(<)\", line 4" $(@:.test=.out) > /dev/null
	touch $@

.PHONY: test
test: src_test/app $(foreach case, $(FAIL_CASES), src_test/fail_$(case).test)
	./src_test/app

$(BUILD_DIR)/.exists:
	mkdir -p $(BUILD_DIR)
	touch $@

################################################################################
# Emacs flymake

BUILD_DIR = build

FLYMAKE_LOG=$(BUILD_DIR)/flymake-log.txt
FLYMAKE_BUILD=$(BUILD_DIR)/flymake-last-build.txt

.PHONY: flymake.ml.check
flymake.ml.check:
	@(ocamlfind ocamlopt  $(OCAMLOPT_FLAGS) $(PPX_STRING_PACKAGES) -c $(CHK_SOURCES) -o /tmp/flymake_temp.cmx 2>&1) | sed 's/_flymake//g' | tee $(FLYMAKE_BUILD)

.PHONY: flymake.mli.check
flymake.mli.check: flymake.ml.check

.PHONY: flymake_log
flymake_log:
	@echo "$(shell date '+%Y-%m-%d %H:%M:%S') checking $(CHK_SOURCES)" >> $(FLYMAKE_LOG)

.PHONY: check-syntax
check-syntax: $(BUILD_DIR)/.exists flymake_log flymake$(suffix $(CHK_SOURCES)).check

