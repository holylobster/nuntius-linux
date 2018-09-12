#!/bin/sh
# Run this to generate all the initial makefiles, etc.
set -e

autopoint --force
AUTOPOINT='intltoolize --automake --copy' autoreconf --force --install --verbose $@
