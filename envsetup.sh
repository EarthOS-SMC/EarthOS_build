#!/bin/bash

if ! [ -s Makefile ]; then
	ln -s build/Makefile Makefile
fi
if ! [[ "$PATH" == *"$PWD/build/bin"* ]]; then
	export PATH=$PATH:$PWD/build/bin
fi
mkdir -p out
export OUT="$PWD/out"
