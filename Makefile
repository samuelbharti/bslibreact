PATH_PKG_R := pkg-r
PATH_PKG_PY := pkg-py
PATH_PKG_JS := pkg-js
RSCRIPT ?= Rscript

.PHONY: setup
setup: js-setup r-setup py-setup pre-commit-setup  ## Set up the whole development environment

.PHONY: pre-commit-setup
pre-commit-setup:  ## Install pre-commit hooks (prek)
	prek install

.PHONY: check
check: js-lint js-test r-check py-check version-check  ## Everything CI runs


## ---- js ---------------------------------------------------------------

.PHONY: js-setup
js-setup:  ## [js] Install JS dependencies
	@echo "Installing JS dependencies"
	npm install

.PHONY: js-setup-ci
js-setup-ci:  ## [js] Install JS dependencies as CI
	npm ci

.PHONY: js-lint
js-lint:  ## [js] Type check JS code
	cd $(PATH_PKG_JS) && npm run lint

.PHONY: js-format
js-format:  ## [js] Format JS code
	cd $(PATH_PKG_JS) && npm run format

.PHONY: js-format-check
js-format-check:  ## [js] Check JS formatting
	cd $(PATH_PKG_JS) && npm run format-check

.PHONY: js-build
js-build:  ## [js] Build JS code (IIFE and npm ESM)
	cd $(PATH_PKG_JS) && npm run build

.PHONY: js-test
js-test:  ## [js] Run JS tests
	cd $(PATH_PKG_JS) && npm test


## ---- r ------------------------------------------------------------------

.PHONY: r-setup
r-setup:  ## [r] Install R dependencies
	cd $(PATH_PKG_R) && $(RSCRIPT) -e "pak::local_install_dev_deps()"

.PHONY: r-document
r-document:  ## [r] Regenerate NAMESPACE and man/ from roxygen comments
	cd $(PATH_PKG_R) && $(RSCRIPT) -e "devtools::document()"

.PHONY: r-format
r-format:  ## [r] Format R code
	air format $(PATH_PKG_R)/

.PHONY: r-check-format
r-check-format:  ## [r] Check R formatting
	air format --check $(PATH_PKG_R)/

.PHONY: r-check-tests
r-check-tests:  ## [r] Run R tests
	cd $(PATH_PKG_R) && $(RSCRIPT) -e "devtools::test()"

.PHONY: r-check-package
r-check-package:  ## [r] R CMD check (fails on NOTEs)
	cd $(PATH_PKG_R) && $(RSCRIPT) -e "devtools::check(document = FALSE, error_on = 'note')"

.PHONY: r-check
r-check: r-check-format r-check-tests r-check-package  ## [r] All R checks

.PHONY: r-update-dist
r-update-dist:  ## [r] Vendor the built JS bundle into pkg-r
	@echo "Updating vendored bundle in $(PATH_PKG_R)/inst/lib/bslib-react"
	rm -rf $(PATH_PKG_R)/inst/lib/bslib-react
	mkdir -p $(PATH_PKG_R)/inst/lib/bslib-react
	cp $(PATH_PKG_JS)/dist/bslib-react.js $(PATH_PKG_R)/inst/lib/bslib-react/
	@if [ -f $(PATH_PKG_JS)/dist/bslib-react.css ]; then \
		cp $(PATH_PKG_JS)/dist/bslib-react.css $(PATH_PKG_R)/inst/lib/bslib-react/; \
	fi

.PHONY: r-markup
r-markup:  ## [r] Render the R markup catalog
	$(RSCRIPT) tools/markup/render-r.R --out .cache/markup/r.json

.PHONY: r-docs-render
r-docs-render:  ## [r] Build R docs (pkgdown)
	cd $(PATH_PKG_R) && $(RSCRIPT) -e "pkgdown::build_site()"


## ---- py -----------------------------------------------------------------

.PHONY: py-setup
py-setup:  ## [py] Install Python dependencies
	uv sync --all-extras --all-groups

.PHONY: py-check-format
py-check-format:  ## [py] Check Python formatting
	uv run ruff check pkg-py examples --config pyproject.toml
	uv run ruff format --check pkg-py examples --config pyproject.toml

.PHONY: py-format
py-format:  ## [py] Format Python code
	uv run ruff check --fix pkg-py examples --config pyproject.toml
	uv run ruff format pkg-py examples --config pyproject.toml

.PHONY: py-check-types
py-check-types:  ## [py] Type check Python code
	uv run pyright

.PHONY: py-check-tests
py-check-tests:  ## [py] Run Python tests
	uv run pytest

.PHONY: py-check
py-check: py-check-format py-check-types py-check-tests  ## [py] All Python checks

.PHONY: py-update-dist
py-update-dist:  ## [py] Vendor the built JS bundle into pkg-py
	@echo "Updating vendored bundle in $(PATH_PKG_PY)/src/bslib_react/www"
	rm -rf $(PATH_PKG_PY)/src/bslib_react/www
	mkdir -p $(PATH_PKG_PY)/src/bslib_react/www
	cp $(PATH_PKG_JS)/dist/bslib-react.js $(PATH_PKG_PY)/src/bslib_react/www/
	@if [ -f $(PATH_PKG_JS)/dist/bslib-react.css ]; then \
		cp $(PATH_PKG_JS)/dist/bslib-react.css $(PATH_PKG_PY)/src/bslib_react/www/; \
	fi

.PHONY: py-markup
py-markup:  ## [py] Render the Python markup catalog
	uv run python tools/markup/render_py.py --out .cache/markup/py.json

.PHONY: py-build
py-build:  ## [py] Build the Python package
	uv build


## ---- shared ---------------------------------------------------------------

.PHONY: update-dist
update-dist: js-build r-update-dist py-update-dist  ## Build the JS bundle and vendor it into pkg-r and pkg-py

.PHONY: markup
markup: r-markup py-markup  ## Render both markup catalogs into .cache/markup/

.PHONY: markup-force
markup-force:  ## Re-render both markup catalogs even if the cache looks fresh
	rm -rf .cache/markup
	$(MAKE) markup

.PHONY: examples
examples:  ## Build every example app's client bundle
	cd examples/01-hello && npm install && npm run build
	cd examples/volcano-plot && npm install && npm run build

.PHONY: gallery-apps
gallery-apps:  ## [gallery] Build every example's react/ client bundle (dev only, for screenshots)
	cd gallery && npm install && npm run build:apps

.PHONY: gallery
gallery:  ## [gallery] Build the full gallery site (shell plus shinylive exports) into gallery/dist
	cd gallery && npm install && npm run build

.PHONY: gallery-dev
gallery-dev:  ## [gallery] Run the gallery shell's dev server
	cd gallery && npm install && npm run dev

.PHONY: version-check
version-check:  ## Assert DESCRIPTION, pyproject.toml, and package.json agree on version
	@r=$$(sed -n 's/^Version: //p' pkg-r/DESCRIPTION); \
	p=$$(sed -n 's/^version = "\(.*\)"/\1/p' pyproject.toml | head -1); \
	j=$$(cd pkg-js && npm pkg get version | tr -d '"'); \
	if [ "$$r" != "$$p" ] || [ "$$r" != "$$j" ]; then \
		echo "versions differ: R $$r, py $$p, js $$j"; exit 1; \
	fi; \
	echo "version ok: $$r"

.PHONY: help
help:  ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; { \
		printf "%-20s %s\n", $$1, $$2 \
	}'

.DEFAULT_GOAL := help
