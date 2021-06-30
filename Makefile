SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = ./docs_source
BUILDDIR      = ./docs
AUTODOCDIR    = ./docs_source/phd_code_docs/
CODEDIR	      = ./phd

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help default doc_html_push html

# $(O) is meant as a shortcut for $(SPHINXOPTS).
# Generates docstrings from the code modules and deposits in documentation source dir
# Builds sphinx documentation using generated docstrings
# Copies docstrings to gh-pages recognized directory
# Pushes updated documentation to main branch of Github repo

default: html

doc_html_push:
	sphinx-apidoc -fo "$(AUTODOCDIR)" "$(CODEDIR)"
	$(SPHINXBUILD) "$(SOURCEDIR)" "$(BUILDDIR)"
	cp -a docs/html/. docs
	echo "Build finished. HTML pages copied to docs directory"
	git add docs/*
	git add docs_source/*
	git commit -m "Docs updated and rebuilt"
	git push -u origin main

html:
	sphinx-apidoc -fo "$(AUTODOCDIR)" "$(CODEDIR)"
	$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" html $(O)
