#!/bin/bash
#
# Helper for setting up the test environment on Travis.
#
# High level variables action as configuration should be defined in .travis.yml
#
# If running the tests requires a virtualenv, it creates it at `~/.venv` as the
# test run step will activate the virtualenv from that location.
#
set -e
set -x

#
# Create a virtualenv if required.
#
if [[ "$(uname -s)" == 'Darwin' ]]; then
    # On OSX we run the tests in a virtualenv using the default Python version
    # provide by the OS.
    curl -O https://bootstrap.pypa.io/get-pip.py
    python get-pip.py --user
    python -m pip install --user virtualenv
    python -m virtualenv ~/.venv
elif [ "$TRAVIS_PYTHON_VERSION" = "pypy" ]; then
    if [ -f "$PYENV_ROOT/bin/pyenv" ]; then
        # pyenv already exists. Just updated it.
        pushd "$PYENV_ROOT"
        git pull
        popd
    else
        rm -rf "$PYENV_ROOT"
        git clone --depth 1 https://github.com/yyuu/pyenv.git "$PYENV_ROOT"
    fi

    "$PYENV_ROOT/bin/pyenv" install --skip-existing "$PYPY_VERSION"
    virtualenv --python="$PYENV_ROOT/versions/$PYPY_VERSION/bin/python" ~/.venv
fi

#
# Activate the virtualenv if required.
#
if [ -f ~/.venv/bin/activate ]; then
    # Initialize the virtualenv created at install time.
    source ~/.venv/bin/activate

    if [[ "${TOXENV}" == "py35-alldeps-withcov-macos,codecov-publish" ]]; then

        brew update;
        brew upgrade openssl;
        brew install pyenv;
        PYENV_ROOT="$HOME/.pyenv";
        PATH="$PYENV_ROOT/bin:$PATH";
        eval "$(pyenv init -)";
        pyenv install -s 3.5.2;
        pyenv global system 3.5.2;
        pyenv rehash;

    fi
fi

# Temporary workaround for https://github.com/pypa/setuptools/issues/776;
# install (and thereby cache a built wheel of) cryptography.
pip install -U pip 'setuptools<26'
pip install cryptography

#
# Do the actual install work.
#
pip install $@
