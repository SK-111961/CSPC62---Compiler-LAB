%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Symbol Table Structure
struct SymbolEntry {
    char name[50];
    char type[20];
    char scope[50];
    char value[50];  // Increased size to handle longer values
    struct SymbolEntry *next;
};

struct SymbolEntry *symbolTable = NULL;
char current_scope[50] = "global";  // Track current scope

// Function declarations
void add_to_symbol_table(char *name, char *type, char *scope, char *value);
void update_symbol_table(char *name, char *type, char *scope, char *value);
void print_symbol_table();
extern int yylex(void);
extern int yylineno;  // Line number from flex
void yyerror(const char *s);

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

void update_symbol_table(char *name, char *type, char *scope, char *value) {
    struct SymbolEntry *current = symbolTable;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            if (type != NULL && strlen(type) > 0) strcpy(current->type, type);
            if (scope != NULL && strlen(scope) > 0) strcpy(current->scope, scope);
            if (value != NULL && strlen(value) > 0) strcpy(current->value, value);
            return;
        }
        current = current->next;
    }
    // If not found, add a new entry
    add_to_symbol_table(name, type ? type : "unknown", scope ? scope : "global", value ? value : "");
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

/* Define value types for our grammar symbols */
%union {
    char *str;
    int num;
}

/* Define tokens with appropriate types */
%token <str> IDENT TYPE
%token <str> INTEGER STRING DECIMAL
%token <str> ASSIGN_OP COMP_OP
%token IF ELSE FOR WHILE DO RETURN PRINT SEMICOLON COMMA
%token INC DEC LOGICAL_NOT BITWISE_NOT
%token '+' '-' '*' '/'


/* Define non-terminal types for ALL rules that produce values */
%type <str> expression variable declaration
%type <str> var_declaration function_declaration
%type <str> simple_expression additive_expression term factor postfix_expr
%type <str> parameter compound_stmt
%type <str> statement expression_stmt if_stmt while_stmt for_stmt return_stmt print_stmt assignment_stmt

/* Precedence rules to resolve the shift/reduce conflict */
%nonassoc IFX
%nonassoc ELSE
%left '+' '-'
%left '*' '/'
%right UMINUS  /* Unary minus precedence */

%%

/* Top-level rule now allows both declarations and statements */
program:
    global_declaration_list
    ;

global_declaration_list:
    global_declaration_list global_declaration
    | global_declaration
    ;

global_declaration:
    declaration
    | statement
    ;

declaration:
    var_declaration { $$ = $1; }
    | function_declaration { $$ = $1; }
    ;

var_declaration:
    TYPE IDENT SEMICOLON {
        add_to_symbol_table($2, $1, current_scope, "");
        $$ = $2;  /* Return identifier name */
    }
    | TYPE IDENT ASSIGN_OP expression SEMICOLON {
        add_to_symbol_table($2, $1, current_scope, $4);
        $$ = $2;  /* Return identifier name */
    }
    ;

/* Function declaration remains unchanged */
function_declaration:
    TYPE IDENT '(' parameter_list ')' compound_stmt {
        add_to_symbol_table($2, $1, "function", "");
        $$ = $2;
    }
    ;

parameter_list:
    parameter_list COMMA parameter
    | parameter
    | /* empty */
    ;

parameter:
    TYPE IDENT {
        add_to_symbol_table($2, $1, "parameter", "");
        $$ = $2;
    }
    ;

compound_stmt:
    '{' {
        char old_scope[50];
        strcpy(old_scope, current_scope);
        sprintf(current_scope, "block_%d", yylineno);
    }
    local_declarations statement_list 
    '}' {
        strcpy(current_scope, "global");
        $$ = strdup("compound");
    }
    ;

local_declarations:
    local_declarations var_declaration
    | /* empty */
    ;

statement_list:
    statement_list statement
    | /* empty */
    | error SEMICOLON { yyerror("Syntax error ignored and recovered"); }
    ;

statement:
    assignment_stmt
    | expression_stmt
    | compound_stmt
    | if_stmt
    | while_stmt
    | for_stmt
    | return_stmt
    | print_stmt
    | SEMICOLON /* Allow empty statements */
    ;

assignment_stmt:
    variable ASSIGN_OP expression SEMICOLON {
        update_symbol_table($1, "unknown", current_scope, $3);
        $$ = strdup("assignment_stmt");
    }
    ;

expression_stmt:
    expression SEMICOLON
    ;

for_stmt:
    FOR '(' expression SEMICOLON expression SEMICOLON expression ')' statement {
        $$ = strdup("for_stmt");
    }
    ;

if_stmt:
    IF '(' expression ')' statement %prec IFX {
        $$ = strdup("if_stmt");
    }
    | IF '(' expression ')' statement ELSE statement {
        $$ = strdup("if_else_stmt");
    }
    ;

while_stmt:
    WHILE '(' expression ')' statement {
        $$ = strdup("while_stmt");
    }
    | DO statement WHILE '(' expression ')' SEMICOLON {
        $$ = strdup("do_while_stmt");
    }
    ;

return_stmt:
    RETURN SEMICOLON {
        $$ = strdup("return_void");
    }
    | RETURN expression SEMICOLON {
        $$ = $2;
    }
    ;

print_stmt:
    PRINT '(' expression ')' SEMICOLON {
        $$ = strdup("print_stmt");
    }
    ;

/* Expression: support assignment as well as simple expressions */
expression:
    variable ASSIGN_OP expression {
        update_symbol_table($1, "unknown", current_scope, $3);
        $$ = $3;
    }
    | simple_expression {
        $$ = $1;
    }
    ;

/* Variable remains the same */
variable:
    IDENT {
        $$ = $1;
    }
    ;

/* Allow postfix expressions in factors */
postfix_expr:
    variable { $$ = $1; }
    | variable INC {
         char result[100];
         sprintf(result, "%s++", $1);
         $$ = strdup(result);
    }
    | variable DEC {
         char result[100];
         sprintf(result, "%s--", $1);
         $$ = strdup(result);
    }
    ;

/* Factor now supports prefix (unary) operators as well as postfix_expr */
factor:
      '-' factor %prec UMINUS {
        char result[100];
        sprintf(result, "-%s", $2);
        $$ = strdup(result);
    }
    | '+' factor {
        char result[100];
        sprintf(result, "+%s", $2);
        $$ = strdup(result);
    }
    | LOGICAL_NOT factor {
        char result[100];
        sprintf(result, "!%s", $2);
        $$ = strdup(result);
    }
    | BITWISE_NOT factor {
        char result[100];
        sprintf(result, "~%s", $2);
        $$ = strdup(result);
    }
    | INC variable {
        char result[100];
        sprintf(result, "++%s", $2);
        $$ = strdup(result);
    }
    | DEC variable {
        char result[100];
        sprintf(result, "--%s", $2);
        $$ = strdup(result);
    }
    | '(' expression ')' {
        $$ = $2;
    }
    | postfix_expr {
        $$ = $1;
    }
    | INTEGER {
        $$ = $1;
    }
    | DECIMAL {
        $$ = $1;
    }
    | STRING {
        $$ = $1;
    }
    ;

/* Simple expression: arithmetic or comparisons */
simple_expression:
    additive_expression {
        $$ = $1;
    }
    | additive_expression COMP_OP additive_expression {
        char result[100];
        sprintf(result, "%s %s %s", $1, $2, $3);
        $$ = strdup(result);
    }
    ;

/* Standard arithmetic productions */
additive_expression:
    term {
        $$ = $1;
    }
    | additive_expression '+' term {
        char result[100];
        sprintf(result, "%s + %s", $1, $3);
        $$ = strdup(result);
    }
    | additive_expression '-' term {
        char result[100];
        sprintf(result, "%s - %s", $1, $3);
        $$ = strdup(result);
    }
    ;

term:
    factor {
        $$ = $1;
    }
    | term '*' factor {
        char result[100];
        sprintf(result, "%s * %s", $1, $3);
        $$ = strdup(result);
    }
    | term '/' factor {
        char result[100];
        sprintf(result, "%s / %s", $1, $3);
        $$ = strdup(result);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s at line %d\n", s, yylineno);
}

int main() {
    yyparse();
    print_symbol_table();
    return 0;
}