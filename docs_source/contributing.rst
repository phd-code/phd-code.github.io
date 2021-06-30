Contributing
============

If you find any bugs or other issues with the code, please make an issue at `https://github.com/phd-code/phd-code.github.io <https://github.com/phd-code/phd-code.github.io>`_. Feedback is always welcome and appreciated!

Building the Documentation
==========================

If you are making changes to the documentation, the Sphinx documentation can be built locally using the files in the ``docs_source`` and ``docs`` folders. The home directory of the repository, ``phd-code.github.io`` will contain the ``Makefile`` which enables two commands for building the documentation. Note that this will require Sphinx, which can be installed `here <https://www.sphinx-doc.org/en/master/usage/installation.html>`_. You may also need to install a few packages, which can be done via the following command::

	python -m pip install -r docs_source/requirements.txt

Once the necessary packages are installed, ``make html`` will autodocument the code, generate the necessary docstrings, and build the documentation at the specified local directory (specified within the ``Makefile`` or on the command line). If you are ready to push an updated version of the documentation, the ``make doc_html_push`` command will repeat the aforementioned two steps and push the documentation to the 'main' branch of the code repository.