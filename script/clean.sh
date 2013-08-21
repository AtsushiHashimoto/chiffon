#!/bin/bash

# このファイルの場所を $SHELL_HOME に格納
SHELL_HOME=$(cd $(dirname $0);pwd)

cd $SHELL_HOME
cd ..

find . -name "*.bak" -print0 | xargs -0 rm
find . -name "*.old" -print0 | xargs -0 rm
