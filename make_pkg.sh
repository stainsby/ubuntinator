#!/bin/sh -e

mkdir -p dist && rm -rf dist/* && \
    cp -a files dist && cp README.md LICENSE dist/files && \
    cd dist/files && tar czfv ../ubuntinator.tar.gz *

