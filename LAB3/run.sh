#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

FILENAME=$1
bison -y -vd parser.y
flex lexer.l  
gcc lex.yy.c y.tab.c -o compiler

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

rm lex.yy.c y.tab.c y.tab.h
./compiler < $FILENAME

if [ $? -ne 0 ]; then
    echo "Error occurred while processing $FILENAME"
    exit 1
fi

dot -Tpng parse_tree.dot -o parse_tree.png