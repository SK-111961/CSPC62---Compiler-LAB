%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

// Symbol Table Structure
struct SymbolEntry {
    char name[50];
    char type[20];
    char scope[20];
    char value[20];
    struct SymbolEntry *next;
};

struct SymbolEntry *symbolTable = NULL;
char current_scope[50] = "global"; // Track current scope
char current_type[20] = "unknown"; // Track current type context

void add_to_symbol_table(char *name, char *type, char *scope, char *value) {
    struct SymbolEntry *current = symbolTable;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0 && strcmp(current->scope, scope) == 0) {
            return; // Identifier already exists in this scope, do not add again
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
        printf("| %-20s | %-10s | %-10s | %-10s |\n", 
               current->name, current->type, current->scope, current->value);
        current = current->next;
    }
    printf("+----------------------+------------+------------+------------+\n");
}

// Function to reset current type
void reset_current_type() {
    strcpy(current_type, "unknown");
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

"char_SK"   { 
    strcpy(current_type, "char"); 
    printf("KEYWORD: %s\n", yytext); 
}
"int_SK"    { 
    strcpy(current_type, "int"); 
    printf("KEYWORD: %s\n", yytext); 
}
"float_SK"  { 
    strcpy(current_type, "float"); 
    printf("KEYWORD: %s\n", yytext); 
}
"double_SK" { 
    strcpy(current_type, "double"); 
    printf("KEYWORD: %s\n", yytext); 
}
"void_SK"   { 
    strcpy(current_type, "void"); 
    printf("KEYWORD: %s\n", yytext); 
}

{KEYWORD}   { 
    printf("KEYWORD: %s\n", yytext); 
    reset_current_type();
}

{IDENT}     { 
    printf("IDENT: %s\n", yytext); 
    add_to_symbol_table(yytext, current_type, current_scope, "unknown"); 
}

{INTEGER}   { 
    printf("INTEGER: %s\n", yytext); 
    // If previous token was an identifier, update its value
    if (symbolTable && strcmp(symbolTable->type, "unknown") != 0) {
        strcpy(symbolTable->value, yytext);
    }
}

{DECIMAL}   { 
    printf("DECIMAL: %s\n", yytext); 
    // If previous token was an identifier, update its value
    if (symbolTable && strcmp(symbolTable->type, "unknown") != 0) {
        strcpy(symbolTable->value, yytext);
    }
}

{STRING}    { 
    printf("STRING: %s\n", yytext); 
    // If previous token was an identifier, update its value
    if (symbolTable && strcmp(symbolTable->type, "unknown") != 0) {
        strcpy(symbolTable->value, yytext);
    }
}

{OPERATOR}  { printf("OPERATOR: %s\n", yytext); }
{PUNCT}     { printf("PUNCT: %s\n", yytext); }

"{"         { 
    printf("BRACKET: %s\n", yytext); 
    // When entering a new block, increment scope
    strcat(current_scope, "_block"); 
}

"}"         { 
    printf("BRACKET: %s\n", yytext); 
    // When exiting a block, remove last block level from scope
    char *last_underscore = strrchr(current_scope, '_');
    if (last_underscore) {
        *last_underscore = '\0';
    }
    reset_current_type();
}

{BRACKET}   { printf("BRACKET: %s\n", yytext); }
[ \t\n]     ;  // Ignore whitespace
.           { fprintf(stderr, "ERROR: Invalid token '%s'\n", yytext); }

%%

int main() {
    yylex();
    print_symbol_table();
    return 0;
}