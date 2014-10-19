
ifeq "$(COVERAGE)" "1"
OCAMLBUILD_FLAGS += -tag 'package(bisect)' -tag 'syntax(camlp4o)' -tag 'syntax(bisect pp)'

coverage: test
	bisect-report -I _build bisect*.out -html coverage_report
endif

all:
	ocamlbuild -use-ocamlfind $(OCAMLBUILD_FLAGS) src_test/app.native

test: all
	rm -f bisect*.out
	./app.native

clean:
	ocamlbuild -clean
	rm -f bisect*.out

