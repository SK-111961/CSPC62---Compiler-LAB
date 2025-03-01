#!/bin/bash

echo "Compiling the Lexer..."
flex lexer.l
gcc lex.yy.c -o lexer

if [ $? -ne 0 ]; then
    echo "Compilation failed. Please check your Lex code."
    exit 1
fi

echo "Lexer compiled successfully."

if [ $# -eq 1 ]; then
    input_file=$1
    echo "Running the Lexer with input file: $input_file"
    ./lexer < "$input_file"
else
    echo "No input file provided. Running the Lexer without input."
    ./lexer
fi