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

// Parse Tree Structure
struct ParseTreeNode {
    char type[50];
    char value[100];
    struct ParseTreeNode *children[10];
    int num_children;
};

struct ParseTreeNode* root = NULL;  // Root of the parse tree

// Function declarations
void add_to_symbol_table(char *name, char *type, char *scope, char *value);
void update_symbol_table(char *name, char *type, char *scope, char *value);
void print_symbol_table();
extern int yylex(void);
extern int yylineno;  // Line number from flex
void yyerror(const char *s);

// Parse tree functions
struct ParseTreeNode* create_node(const char* type, const char* value);
void add_child(struct ParseTreeNode* parent, struct ParseTreeNode* child);
void print_tree(struct ParseTreeNode* node, int depth);

// Token tracking
int token_count = 0;
void print_token(const char* token_name, const char* token_value);

// DOT file functions for parse tree visualization
FILE* dotFile = NULL;
int node_count = 0;
void open_dot_file();
void close_dot_file();
int create_dot_node(const char* label);
void create_dot_edge(int parent, int child);

void add_to_symbol_table(char *name, char *type, char *scope, char *value) {
    struct SymbolEntry *current = symbolTable;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0 && strcmp(current->scope, scope) == 0) {
            // Suppressed the warning output
            return; // Identifier already exists in this scope, do not add again
        }
        current = current->next;
    }
    struct SymbolEntry *newEntry = (struct SymbolEntry*) malloc(sizeof(struct SymbolEntry));
    if (!newEntry) {
        fprintf(stderr, "Error: Memory allocation failed for symbol table entry\n");
        exit(1);
    }
    strcpy(newEntry->name, name);
    strcpy(newEntry->type, type);
    strcpy(newEntry->scope, scope);
    strcpy(newEntry->value, value);
    newEntry->next = symbolTable;
    symbolTable = newEntry;
    // Suppressed the "Added to symbol table" output
}

void update_symbol_table(char *name, char *type, char *scope, char *value) {
    struct SymbolEntry *current = symbolTable;
    int found = 0;
    
    // First look in current scope
    while (current != NULL) {
        if (strcmp(current->name, name) == 0 && strcmp(current->scope, current_scope) == 0) {
            found = 1;
            break;
        }
        current = current->next;
    }
    
    // If not found in current scope, look in global scope
    if (!found) {
        current = symbolTable;
        while (current != NULL) {
            if (strcmp(current->name, name) == 0 && strcmp(current->scope, "global") == 0) {
                found = 1;
                break;
            }
            current = current->next;
        }
    }
    
    if (found) {
        if (type != NULL && strlen(type) > 0) strcpy(current->type, type);
        if (scope != NULL && strlen(scope) > 0) strcpy(current->scope, scope);
        if (value != NULL && strlen(value) > 0) strcpy(current->value, value);
        // Suppressed the "Updated symbol" output
    } else {
        // If not found, add a new entry
        // Suppressed the "Symbol not found" output
        add_to_symbol_table(name, type ? type : "unknown", scope ? scope : current_scope, value ? value : "");
    }
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

// Token tracking function
void print_token(const char* token_name, const char* token_value) {
    token_count++;
    if (token_value) {
        printf("Token %d: %s (%s)\n", token_count, token_name, token_value);
    } else {
        printf("Token %d: %s\n", token_count, token_name);
    }
}

// Parse tree functions implementation
struct ParseTreeNode* create_node(const char* type, const char* value) {
    struct ParseTreeNode* node = (struct ParseTreeNode*)malloc(sizeof(struct ParseTreeNode));
    if (!node) {
        fprintf(stderr, "Error: Memory allocation failed for parse tree node\n");
        exit(1);
    }
    strcpy(node->type, type);
    strcpy(node->value, value ? value : "");
    node->num_children = 0;
    
    // Create node in DOT file
    if (dotFile) {
        int node_id = create_dot_node(value ? value : type);
        // Store node_id in the node structure if needed for connecting later
    }
    
    return node;
}

void add_child(struct ParseTreeNode* parent, struct ParseTreeNode* child) {
    if (parent->num_children < 10) {
        parent->children[parent->num_children++] = child;
        
        // Create edge in DOT file if needed
        // Would need to store node IDs somewhere to reference them here
    }
}

void print_tree(struct ParseTreeNode* node, int depth) {
    if (!node) return;
    
    for (int i = 0; i < depth; i++) printf("  ");
    printf("%s", node->type);
    if (strlen(node->value) > 0) printf(" (%s)", node->value);
    printf("\n");
    
    for (int i = 0; i < node->num_children; i++) {
        print_tree(node->children[i], depth + 1);
    }
}

// DOT file functions implementation
void open_dot_file() {
    dotFile = fopen("parse_tree.dot", "w");
    if (dotFile == NULL) {
        fprintf(stderr, "Error opening dot file\n");
        return;
    }
    fprintf(dotFile, "digraph ParseTree {\n");
    fprintf(dotFile, "  node [shape=box];\n");
    node_count = 0;
}

void close_dot_file() {
    if (dotFile) {
        fprintf(dotFile, "}\n");
        fclose(dotFile);
        printf("Parse tree written to parse_tree.dot\n");
        printf("Generate image with: dot -Tpng parse_tree.dot -o parse_tree.png\n");
    }
}

int create_dot_node(const char* label) {
    int id = node_count++;
    char escaped_label[200];
    
    // Simple escaping for DOT labels
    int j = 0;
    for (int i = 0; label[i] && j < 198; i++) {
        if (label[i] == '"' || label[i] == '\\') {
            escaped_label[j++] = '\\';
        }
        escaped_label[j++] = label[i];
    }
    escaped_label[j] = '\0';
    
    fprintf(dotFile, "  node%d [label=\"%s\"];\n", id, escaped_label);
    return id;
}

void create_dot_edge(int parent, int child) {
    fprintf(dotFile, "  node%d -> node%d;\n", parent, child);
}
%}

/* Enable parse tracing for debugging */
%define parse.trace

/* Define value types for our grammar symbols */
%union {
    char *str;
    int num;
    struct ParseTreeNode *node;
}

/* Define tokens with appropriate types */
%token <str> IDENT TYPE
%token <str> INTEGER STRING DECIMAL
%token <str> ASSIGN_OP COMP_OP
%token IF ELSE FOR WHILE DO RETURN PRINT SEMICOLON COMMA
%token INC DEC LOGICAL_NOT BITWISE_NOT
%token '+' '-' '*' '/'
%token MAIN INVALID_TOKEN  /* Added tokens */

/* Define non-terminal types for ALL rules that produce values */
%type <str> expression variable declaration
%type <str> var_declaration function_declaration
%type <str> simple_expression additive_expression term factor postfix_expr
%type <str> parameter compound_stmt
%type <str> statement expression_stmt if_stmt while_stmt for_stmt return_stmt print_stmt assignment_stmt
%type <str> call args arg_list

/* Precedence rules to resolve the shift/reduce conflict */
%nonassoc IFX
%nonassoc ELSE
%left '+' '-'
%left '*' '/'
%right UMINUS  /* Unary minus precedence */

/* Enable detailed error reporting */
%error-verbose

%%

/* Top-level rule now allows both declarations and statements */
program:
    global_declaration_list {
        // Suppressed
    }
    ;

global_declaration_list:
    global_declaration_list global_declaration {
        // Suppressed
    }
    | global_declaration {
        // Suppressed
    }
    ;

global_declaration:
    declaration {
        // Suppressed
    }
    | statement {
        // Suppressed
    }
    | error SEMICOLON { 
        yyerror("Syntax error in global declaration - recovered at semicolon");
        yyerrok; /* Reset error state */
    }
    | error '}' { 
        yyerror("Syntax error in global declaration - recovered at closing brace");
        yyerrok; 
    }
    ;

declaration:
    var_declaration { 
        $$ = $1; 
        // Suppressed
    }
    | function_declaration { 
        $$ = $1; 
        // Suppressed
    }
    ;

var_declaration:
    TYPE IDENT SEMICOLON {
        add_to_symbol_table($2, $1, current_scope, "");
        $$ = $2;  /* Return identifier name */
        // Suppressed
    }
    | TYPE IDENT ASSIGN_OP expression SEMICOLON {
        add_to_symbol_table($2, $1, current_scope, $4);
        $$ = $2;  /* Return identifier name */
        // Suppressed
    }
    | error SEMICOLON {
        yyerror("Syntax error in variable declaration - recovered at semicolon");
        yyerrok;
        $$ = strdup("error");
    }
    ;

/* Function declaration with main support */
function_declaration:
    TYPE IDENT '(' parameter_list ')' compound_stmt {
        add_to_symbol_table($2, $1, "function", "");
        $$ = $2;
        // Suppressed
    }
    | TYPE MAIN '(' parameter_list ')' compound_stmt {
        add_to_symbol_table("main", $1, "function", "");
        $$ = strdup("main");
        // Suppressed
    }
    | error ')' compound_stmt {
        yyerror("Syntax error in function declaration - recovered at closing parenthesis");
        yyerrok;
        $$ = strdup("error");
    }
    | error '}' {
        yyerror("Syntax error in function body - recovered at closing brace");
        yyerrok;
        $$ = strdup("error");
    }
    ;

parameter_list:
    parameter_list COMMA parameter {
        // Suppressed
    }
    | parameter {
        // Suppressed
    }
    | /* empty */ {
        // Suppressed
    }
    | error ')' {
        yyerror("Syntax error in parameter list - recovered at closing parenthesis");
        yyerrok;
    }
    ;

parameter:
    TYPE IDENT {
        add_to_symbol_table($2, $1, "parameter", "");
        $$ = $2;
        // Suppressed
    }
    ;

compound_stmt:
    '{' {
        char old_scope[50];
        strcpy(old_scope, current_scope);
        sprintf(current_scope, "block_%d", yylineno);
        // Suppressed
    }
    local_declarations statement_list 
    '}' {
        // Suppressed
        strcpy(current_scope, "global");
        $$ = strdup("compound");
    }
    | '{' error '}' {
        yyerror("Syntax error in compound statement - recovered at closing brace");
        yyerrok;
        $$ = strdup("error_compound");
    }
    ;

local_declarations:
    local_declarations var_declaration {
        // Suppressed
    }
    | /* empty */ {
        // Suppressed
    }
    ;

statement_list:
    statement_list statement {
        // Suppressed
    }
    | /* empty */ {
        // Suppressed
    }
    | error SEMICOLON { 
        yyerror("Syntax error in statement - recovered at semicolon"); 
        yyerrok;
    }
    | error '}' { 
        yyerror("Syntax error in statement block - recovered at closing brace"); 
        yyerrok;
    }
    ;

statement:
    assignment_stmt {
        // Suppressed
    }
    | expression_stmt {
        // Suppressed
    }
    | compound_stmt {
        // Suppressed
    }
    | if_stmt {
        // Suppressed
    }
    | while_stmt {
        // Suppressed
    }
    | for_stmt {
        // Suppressed
    }
    | return_stmt {
        // Suppressed
    }
    | print_stmt {
        // Suppressed
    }
    | call SEMICOLON {
        // Suppressed
        $$ = strdup("function_call_stmt");
    }
    | SEMICOLON {
        // Suppressed
    }
    ;

assignment_stmt:
    variable ASSIGN_OP expression SEMICOLON {
        update_symbol_table($1, "unknown", current_scope, $3);
        $$ = strdup("assignment_stmt");
        // Suppressed
    }
    | error SEMICOLON {
        yyerror("Syntax error in assignment - recovered at semicolon");
        yyerrok;
        $$ = strdup("error_assignment");
    }
    ;

expression_stmt:
    expression SEMICOLON {
        // Suppressed
    }
    | error SEMICOLON {
        yyerror("Syntax error in expression statement - recovered at semicolon");
        yyerrok;
    }
    ;

for_stmt:
    FOR '(' expression SEMICOLON expression SEMICOLON expression ')' statement {
        $$ = strdup("for_stmt");
        // Suppressed
    }
    | FOR '(' error ')' statement {
        yyerror("Syntax error in for loop parameters - recovered at closing parenthesis");
        yyerrok;
        $$ = strdup("error_for");
    }
    ;

if_stmt:
    IF '(' expression ')' statement %prec IFX {
        $$ = strdup("if_stmt");
        // Suppressed
    }
    | IF '(' expression ')' statement ELSE statement {
        $$ = strdup("if_else_stmt");
        // Suppressed
    }
    | IF '(' error ')' statement {
        yyerror("Syntax error in if condition - recovered at closing parenthesis");
        yyerrok;
        $$ = strdup("error_if");
    }
    ;

while_stmt:
    WHILE '(' expression ')' statement {
        $$ = strdup("while_stmt");
        // Suppressed
    }
    | DO statement WHILE '(' expression ')' SEMICOLON {
        $$ = strdup("do_while_stmt");
        // Suppressed
    }
    | WHILE '(' error ')' statement {
        yyerror("Syntax error in while condition - recovered at closing parenthesis");
        yyerrok;
        $$ = strdup("error_while");
    }
    ;

return_stmt:
    RETURN SEMICOLON {
        $$ = strdup("return_void");
        // Suppressed
    }
    | RETURN expression SEMICOLON {
        $$ = $2;
        // Suppressed
    }
    | RETURN error SEMICOLON {
        yyerror("Syntax error in return statement - recovered at semicolon");
        yyerrok;
        $$ = strdup("error_return");
    }
    ;

print_stmt:
    PRINT '(' expression ')' SEMICOLON {
        $$ = strdup("print_stmt");
        // Suppressed
    }
    | PRINT '(' error ')' SEMICOLON {
        yyerror("Syntax error in print statement - recovered at closing parenthesis");
        yyerrok;
        $$ = strdup("error_print");
    }
    ;

/* Rule for function calls */
call:
    IDENT '(' args ')' {
        char result[100];
        sprintf(result, "call_%s", $1);
        $$ = strdup(result);
        // Suppressed
    }
    | IDENT '(' error ')' {
        yyerror("Syntax error in function call - recovered at closing parenthesis");
        yyerrok;
        char result[100];
        sprintf(result, "error_call_%s", $1);
        $$ = strdup(result);
    }
    ;

args:
    arg_list { 
        $$ = $1; 
        // Suppressed
    }
    | /* empty */ { 
        $$ = strdup(""); 
        // Suppressed
    }
    ;

arg_list:
    arg_list COMMA expression {
        char result[200];
        sprintf(result, "%s,%s", $1, $3);
        $$ = strdup(result);
        // Suppressed
    }
    | expression { 
        $$ = $1; 
        // Suppressed
    }
    ;

/* Expression: support assignment as well as simple expressions */
expression:
    variable ASSIGN_OP expression {
        update_symbol_table($1, "unknown", current_scope, $3);
        $$ = $3;
        // Suppressed
    }
    | simple_expression {
        $$ = $1;
        // Suppressed
    }
    | call {
        $$ = $1;
        // Suppressed
    }
    | error ')' { 
        yyerror("Syntax error in expression - recovered at closing parenthesis");
        yyerrok; 
        $$ = strdup("error_expression"); 
    }
    ;

/* Variable remains the same */
variable:
    IDENT {
        $$ = $1;
        // Suppressed
    }
    ;

/* Allow postfix expressions in factors */
postfix_expr:
    variable { 
        $$ = $1; 
        // Suppressed
    }
    | variable INC {
         char result[100];
         sprintf(result, "%s++", $1);
         $$ = strdup(result);
         // Suppressed
    }
    | variable DEC {
         char result[100];
         sprintf(result, "%s--", $1);
         $$ = strdup(result);
         // Suppressed
    }
    | call { 
        $$ = $1; 
        // Suppressed
    }
    ;

/* Factor now supports prefix (unary) operators as well as postfix_expr */
factor:
      '-' factor %prec UMINUS {
        char result[100];
        sprintf(result, "-%s", $2);
        $$ = strdup(result);
        // Suppressed
    }
    | '+' factor {
        char result[100];
        sprintf(result, "+%s", $2);
        $$ = strdup(result);
        // Suppressed
    }
    | LOGICAL_NOT factor {
        char result[100];
        sprintf(result, "!%s", $2);
        $$ = strdup(result);
        // Suppressed
    }
    | BITWISE_NOT factor {
        char result[100];
        sprintf(result, "~%s", $2);
        $$ = strdup(result);
        // Suppressed
    }
    | INC variable {
        char result[100];
        sprintf(result, "++%s", $2);
        $$ = strdup(result);
        // Suppressed
    }
    | DEC variable {
        char result[100];
        sprintf(result, "--%s", $2);
        $$ = strdup(result);
        // Suppressed
    }
    | '(' expression ')' {
        $$ = $2;
        // Suppressed
    }
    | postfix_expr {
        $$ = $1;
        // Suppressed
    }
    | INTEGER {
        $$ = $1;
        // Suppressed
    }
    | DECIMAL {
        $$ = $1;
        // Suppressed
    }
    | STRING {
        $$ = $1;
        // Suppressed
    }
    | error ')' {
        yyerror("Syntax error in factor - recovered at closing parenthesis");
        yyerrok;
        $$ = strdup("error_factor");
    }
    ;

/* Simple expression: arithmetic or comparisons */
simple_expression:
    additive_expression {
        $$ = $1;
        // Suppressed
    }
    | additive_expression COMP_OP additive_expression {
        char result[100];
        sprintf(result, "%s %s %s", $1, $2, $3);
        $$ = strdup(result);
        // Suppressed
    }
    ;

/* Standard arithmetic productions */
additive_expression:
    term {
        $$ = $1;
        // Suppressed
    }
    | additive_expression '+' term {
        char result[100];
        sprintf(result, "%s + %s", $1, $3);
        $$ = strdup(result);
        // Suppressed
    }
    | additive_expression '-' term {
        char result[100];
        sprintf(result, "%s - %s", $1, $3);
        $$ = strdup(result);
        // Suppressed
    }
    ;

term:
    factor {
        $$ = $1;
        // Suppressed
    }
    | term '*' factor {
        char result[100];
        sprintf(result, "%s * %s", $1, $3);
        $$ = strdup(result);
        // Suppressed
    }
    | term '/' factor {
        char result[100];
        sprintf(result, "%s / %s", $1, $3);
        $$ = strdup(result);
        // Suppressed
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", yylineno, s);
}

// We need to modify the yylex function in your Flex file to call print_token
// This is a declaration of a replacement function that your code should use
int custom_yylex(void) {
    int token = yylex();
    
    // Print token information based on token type
    switch(token) {
        case IDENT:
            print_token("IDENTIFIER", yylval.str);
            break;
        case TYPE:
            print_token("TYPE", yylval.str);
            break;
        case INTEGER:
            print_token("INTEGER", yylval.str);
            break;
        case DECIMAL:
            print_token("DECIMAL", yylval.str);
            break;
        case STRING:
            print_token("STRING", yylval.str);
            break;
        case ASSIGN_OP:
            print_token("ASSIGN_OP", yylval.str);
            break;
        case COMP_OP:
            print_token("COMP_OP", yylval.str);
            break;
        case IF:
            print_token("IF", NULL);
            break;
        case ELSE:
            print_token("ELSE", NULL);
            break;
        case FOR:
            print_token("FOR", NULL);
            break;
        case WHILE:
            print_token("WHILE", NULL);
            break;
        case DO:
            print_token("DO", NULL);
            break;
        case RETURN:
            print_token("RETURN", NULL);
            break;
        case PRINT:
            print_token("PRINT", NULL);
            break;
        case SEMICOLON:
            print_token("SEMICOLON", NULL);
            break;
        case COMMA:
            print_token("COMMA", NULL);
            break;
        case INC:
            print_token("INCREMENT", NULL);
            break;
        case DEC:
            print_token("DECREMENT", NULL);
            break;
        case LOGICAL_NOT:
            print_token("LOGICAL_NOT", NULL);
            break;
        case BITWISE_NOT:
            print_token("BITWISE_NOT", NULL);
            break;
        case '+':
            print_token("PLUS", NULL);
            break;
        case '-':
            print_token("MINUS", NULL);
            break;
        case '*':
            print_token("MULTIPLY", NULL);
            break;
        case '/':
            print_token("DIVIDE", NULL);
            break;
        case '(':
            print_token("LEFT_PAREN", NULL);
            break;
        case ')':
            print_token("RIGHT_PAREN", NULL);
            break;
        case '{':
            print_token("LEFT_BRACE", NULL);
            break;
        case '}':
            print_token("RIGHT_BRACE", NULL);
            break;
        case MAIN:
            print_token("MAIN", NULL);
            break;
        case INVALID_TOKEN:
            print_token("INVALID_TOKEN", NULL);
            break;
        default:
            if (token > 0 && token < 128) { // ASCII character range
                char ch_str[2] = {token, '\0'};
                print_token("CHAR", ch_str);
            } else {
                print_token("UNKNOWN", NULL);
            }
    }
    
    return token;
}

int main(int argc, char **argv) {
    #ifdef YYDEBUG
    yydebug = 0; // Turn off debug output
    #endif
    
    open_dot_file();
    root = create_node("PROGRAM", "program");
    
    printf("=== Tokens Scanned ===\n");
    
    // To use the custom token tracking, you need to replace yylex with custom_yylex
    // This requires modifying the Flex-generated code or redirecting yylex calls
    
    int parse_result = yyparse();
    
    printf("\n=== Parse Tree ===\n");
    if (root) {
        print_tree(root, 0);
    }
    
    print_symbol_table();
    
    // Finalize parse tree visualization
    close_dot_file();
    
    if (parse_result == 0) {
        printf("\nParsing completed successfully.\n");
    } else {
        printf("\nParsing failed with errors.\n");
    }
    
    return parse_result;
}