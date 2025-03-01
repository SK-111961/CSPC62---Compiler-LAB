#!/bin/bash

yacc -vd parser.y
if [ $? -ne 0 ]; then
    echo "Error: Parser generation failed. Check your Yacc grammar."
    exit 1
fi
echo "Parser generated successfully."

flex lexer.l
if [ $? -ne 0 ]; then
    echo "Error: Lexer generation failed. Check your Lex file."
    exit 1
fi
echo "Lexer generated successfully."


echo "Compiling the parser and lexer..."
gcc y.tab.c lex.yy.c -o compiler
if [ $? -ne 0 ]; then
    echo "Error: Compilation failed. Check your parser code for errors."
    exit 1
fi
echo "Compilation successful. The compiler is ready to use."

if [ $# -eq 1 ]; then
    INPUT_FILE=$1
    echo "Running the compiler on input file: $INPUT_FILE"
    ./compiler < $INPUT_FILE
else
    echo "No input file provided. You can run the compiler using: ./compiler < input_program.sk"
fi