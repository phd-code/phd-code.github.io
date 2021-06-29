# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = ./docs_source
BUILDDIR      = ./docs
AUTODOCDIR    = ./docs_source/phd_code_docs
CODEDIR	      = ./phd

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@sphinx-apidoc -fo $(AUTODOCDIR) $(CODEDIR)
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
	@cp -a docs/html/. docs
	@echo "Build finished. HTML pages copied to docs directory"
	@git add docs/*
	@git add docs_source/*
	@git commit -m "Docs updated and rebuilt"
	@git push -u origin main

#html:
#	$(SPHINXBUILD) -b html $(SPHINXOPTS) $(BUILDDIR)/docs
#	@echo
#	@echo "Build finished. The HTML pages are in $(BUILDDIR)"

#github:
#      @make html
#      @cp -a _build/html/. ../docs
