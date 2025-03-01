%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Symbol Table Structure
struct SymbolEntry {
    char name[50];
    char type[20];
    char scope[20];
    char value[20];
    struct SymbolEntry *next;
};

struct SymbolEntry *symbolTable = NULL;

void add_to_symbol_table(char *name, char *type, char *scope, char *value) {
    struct SymbolEntry *current = symbolTable;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            return; // Identifier already exists, do not add again
        }
        current = current->next;
    }

    struct SymbolEntry *newEntry = (struct SymbolEntry*) malloc(sizeof(struct SymbolEntry));
    strcpy(newEntry->name, name);
    strcpy(newEntry->type, type);
    strcpy(newEntry->scope, scope);
    strcpy(newEntry->value, value);
    newEntry->next = symbolTable;
    symbolTable = newEntry;
}

void print_symbol_table() {
    struct SymbolEntry *current = symbolTable;
    printf("\n=== Symbol Table ===\n");
    printf("+----------------------+------------+------------+------------+\n");
    printf("| %-20s | %-10s | %-10s | %-10s |\n", "Name", "Type", "Scope", "Value");
    printf("+----------------------+------------+------------+------------+\n");
    while (current != NULL) {
        printf("| %-20s | %-10s | %-10s | %-10s |\n", current->name, current->type, current->scope, current->value);
        current = current->next;
    }
    printf("+----------------------+------------+------------+------------+\n");
}
%}

%option noyywrap

COMMENT   \/\/[^\n]*
KEYWORD   (main_SK|const_SK|char_SK|int_SK|float_SK|double_SK|void_SK|short_SK|long_SK|signed_SK|unsigned_SK|if_SK|else_SK|elseif_SK|switch_SK|case_SK|default_SK|for_SK|while_SK|do_SK|break_SK|continue_SK|goto_SK|return_SK|auto_SK|register_SK|static_SK|extern_SK|volatile_SK|struct_SK|union_SK|enum_SK|typedef_SK|sizeof_SK|print_SK)
IDENT     135[a-zA-Z0-9_]+
INTEGER   [0-9]+
DECIMAL   [0-9]+\.[0-9]+
STRING    \"([^\\\"]|\\.)*\"
OPERATOR  (\+|\-|\*|\/|\%|\=\=|\!\=|\>|\>\=|\<|\<\=|\&\&|\|\||\=|\+\+|\-\-|\&|\||\^|\~|\<\<|\>\>|\!\=|\?|\:|\-\>|\.)
PUNCT     [,;:.]
BRACKET   [(){}\[\]]

%%

{COMMENT}   ;  // Ignore comments
{KEYWORD}   { printf("KEYWORD: %s\n", yytext); }
{IDENT}     { 
               printf("IDENT: %s\n", yytext); 
               add_to_symbol_table(yytext, "unknown", "global", "unknown"); 
             }
{INTEGER}   { printf("INTEGER: %s\n", yytext); }
{DECIMAL}   { printf("DECIMAL: %s\n", yytext); }
{STRING}    { printf("STRING: %s\n", yytext); }
{OPERATOR}  { printf("OPERATOR: %s\n", yytext); }
{PUNCT}     { printf("PUNCT: %s\n", yytext); }
{BRACKET}   { printf("BRACKET: %s\n", yytext); }
[ \t\n]     ;  // Ignore whitespace
.           { fprintf(stderr, "ERROR: Invalid token '%s' at line %d\n", yytext, yylineno); }

%%

int main() {
    yylex();
    print_symbol_table();
    return 0;
}