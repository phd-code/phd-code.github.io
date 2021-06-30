SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = ./docs_source
BUILDDIR      = ./docs
AUTODOCDIR    = ./docs_source/phd_code_docs/
CODEDIR	      = ./phd

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# $(O) is meant as a shortcut for $(SPHINXOPTS).
# Generates docstrings from the code modules and deposits in documentation source dir
# Builds sphinx documentation using generated docstrings
# Copies docstrings to gh-pages recognized directory
# Pushes updated documentation to main branch of Github repo

%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)