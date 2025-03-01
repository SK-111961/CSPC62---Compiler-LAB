%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Symbol Table Structure
struct SymbolEntry {
    char name[50];
    struct SymbolEntry *next;
};

struct SymbolEntry *symbolTable = NULL;

void add_to_symbol_table(char *name) {
    struct SymbolEntry *newEntry = (struct SymbolEntry*) malloc(sizeof(struct SymbolEntry));
    strcpy(newEntry->name, name);
    newEntry->next = symbolTable;
    symbolTable = newEntry;
}

void print_symbol_table() {
    struct SymbolEntry *current = symbolTable;
    printf("\n=== Symbol Table ===\n");
    while (current != NULL) {
        printf("Identifier: %s\n", current->name);
        current = current->next;
    }
}
%}

%option noyywrap

KEYWORD   (loop_SK|if_SK|else_SK|int_SK|float_SK|char_SK|struct_SK|return_SK)
IDENT     135[a-zA-Z0-9_]+
NUMBER    [0-9]+(\.[0-9]+)?
STRING    \"([^\\\"]|\\.)*\"
OPERATOR  (\+|\-|\*|\/|\=\=|\!\=|\>|\<|\&\&|\|\||\=)
PUNCT     [,;:.]
BRACKET   [(){}\[\]]

%%

{KEYWORD}   { printf("KEYWORD: %s\n", yytext); }
{IDENT}     { 
               printf("IDENT: %s\n", yytext); 
               add_to_symbol_table(yytext); 
             }
{NUMBER}    { printf("NUMBER: %s\n", yytext); }
{STRING}    { printf("STRING: %s\n", yytext); }
{OPERATOR}  { printf("OPERATOR: %s\n", yytext); }
{PUNCT}     { printf("PUNCT: %s\n", yytext); }
{BRACKET}   { printf("BRACKET: %s\n", yytext); }
[ \t\n]     ;  // Ignore whitespace
.           { fprintf(stderr, "ERROR: Invalid token '%s'\n", yytext); }

%%

int main() {
    yylex();
    print_symbol_table();
    return 0;
}