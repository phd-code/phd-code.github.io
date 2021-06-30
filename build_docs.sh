#!/bin/bash
sphinx-apidoc -fo ./docs_source/phd_code_docs/ ./phd
make html
cp -a docs/html/. docs/
echo "Build finished. HTML pages copied to docs directory"
git add docs/*
git add docs_source/*
git commit -m "Docs updated and rebuilt"
git push -u origin main
