#!/usr/bin/env bash

# このファイルの場所を $SHELL_HOME に格納
SHELL_HOME=$(cd $(dirname $0);pwd)

cd $SHELL_HOME
cd ..

find . -path "./local" -prune -o -name "*.pm"     -print0 | xargs -0 perltidy
find . -path "./local" -prune -o -name "*.pl"     -print0 | xargs -0 perltidy
find . -path "./local" -prune -o -name "*.PL"     -print0 | xargs -0 perltidy
find . -path "./local" -prune -o -name "*.t"      -print0 | xargs -0 perltidy
find . -path "./local" -prune -o -name "*.conf"   -print0 | xargs -0 perltidy
find . -path "./local" -prune -o -name "cpanfile" -print0 | xargs -0 perltidy
