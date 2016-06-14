#!/bin/sh

mkdir -p dist && rm -rf dist/* && ( cd files && tar czfv ../dist/ubuntinator.tar.gz * )
