Contributing
============

If you find any bugs or other issues with the code, please make an issue at `https://github.com/phd-code/phd-code.github.io <https://github.com/phd-code/phd-code.github.io>`_. Feedback is always welcome and appreciated!

Building the Documentation
==========================

If you are making changes to the documentation, the Sphinx documentation can be built locally using the files in the ``docs_source`` and ``docs`` folders. The home directory of the repository, ``phd-code.github.io`` contains the Sphinx ``Makefile`` and ``build_docs`` script. Note that this will require Sphinx, which can be installed `here <https://www.sphinx-doc.org/en/master/usage/installation.html>`_. You may also need to install a few packages, which can be done via the following command::

	python -m pip install -r docs_source/requirements.txt

Once the necessary packages are installed, the following command will autodocument the code and generate the necessary docstrings (assuming that the filestructure has been preserved)::
	
	sphinx-apidoc -fo ./docs_source/phd_code_docs/ ./phd

Then, ``make html`` will build the documentation at the specified local directory (specified within the ``Makefile`` or on the command line). Once you are ready to push an updated version of the documentation, running the bash script (``bash build_docs.sh``) command will repeat the aforementioned two steps and push the documentation to the 'main' branch of the code repository.