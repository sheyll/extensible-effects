GHCS = 7.8.4 7.10.3 8.0.2 8.2.2 8.4.1

# default ghc-verison for targets, can be overwritten by make-
GHC = 8.2.2
STACK_YAML_ARG = --stack-yaml=stack/stack-$(GHC).yaml
STACK_CMD = stack $(STACK_YAML_ARG)

.PHONY: all
all: build test package doc tags

.PHONY: build
build:
	$(STACK_CMD) build

.PHONY: test
test: build
	$(STACK_CMD) test --test-arguments="-a 1000 \
			--maximum-unsuitable-generated-tests=100000 --color"

.PHONY: bench
bench:
	$(STACK_CMD) bench --benchmark-arguments="-o benchmark/benchmarks.html"

.PHONY: doc
doc:
	$(STACK_CMD) haddock --haddock-internal

.PHONY: tags
tags:
	haskdogs --hasktags-args=-ex

.PHONY: devel
devel: test
	{ \
	DIRS="*.hs *.cabal ./src ./test ./benchmark"; \
	EVENTS="-e modify -e move -e delete"; \
	EXCLUDE="\.#"; \
	while inotifywait -qq $$EVENTS -r $$DIRS --exclude $$EXCLUDE; do \
		make test && make doc; \
	done; \
	}

.PHONY: package
package: test
	# check and bundle the package
	stack sdist
	# outputs to .stack-work/install/<machine-architecture>/<snapshot>/doc

	# check that the generated source-distribution can be built & installed
	# TODO: where to put build?
	{ \
	set -e; set -x; \
	export SRC_TGZ=$$(stack sdist 2>&1 | tail -n 1) ; \
	export PACKAGE=$${SRC_TGZ%.tar.gz}; \
	export PACKAGE=$${PACKAGE##*/}; \
	mkdir -p .build/; cd .build/; \
	cp $$SRC_TGZ .; \
	tar xf $$SRC_TGZ; \
	cd $$PACKAGE; \
	pwd; \
	stack init; \
	stack build; \
	stack test; \
	cd ../..; \
	rm -r .build; \
	}


.PHONY: test-all
test-all: build package

.PHONY: ci-test
ci-test:
	# run tests for all ghc versions given in different ghc-versions
	{ \
	set -e; \
	for ghc in $(GHCS); do \
		echo "Testing GHC verison $$ghc"; \
		stack --stack-yaml="stack/stack-$$ghc.yaml" clean; \
		stack --stack-yaml="stack/stack-$$ghc.yaml" build; \
		stack --stack-yaml="stack/stack-$$ghc.yaml" test; \
	done; \
	}

.PHONY: stack-clean
stack-clean:
	$(STACK_CMD) clean

# nightly targets

.PHONY: nightly-build
nightly-build:
	stack --resolver=nightly build

.PHONY: nightly-test
nightly-test: nightly-build
	stack --resolver=nightly test

.PHONY: nightly-bench
nightly-bench: nightly-build nightly-test
	stack --resolver=nightly bench

.PHONY: nightly-clean
nightly-clean:
	stack --resolver=nightly clean
