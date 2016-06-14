#!/bin/sh

mkdir -p dist
( cd files && tar czfv ../dist/ubuntinator.tar.gz * )
