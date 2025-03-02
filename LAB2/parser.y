%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct SymbolEntry {
    char name[50];
    char type[20];
    char scope[50];
    char value[50];
    struct SymbolEntry *next;
};

struct SymbolEntry *symbolTable = NULL;
char current_scope[50] = "global"; 

struct ParseTreeNode {
    char type[50];
    char value[100];
    struct ParseTreeNode *children[10];
    int num_children;
    int node_id;
};

struct ParseTreeNode* root = NULL; 

void add_to_symbol_table(char *name, char *type, char *scope, char *value);
void update_symbol_table(char *name, char *type, char *scope, char *value);
void print_symbol_table();
extern int yylex(void);
extern int yylineno;
void yyerror(const char *s);

struct ParseTreeNode* create_node(const char* type, const char* value);
void add_child(struct ParseTreeNode* parent, struct ParseTreeNode* child);
void print_tree(struct ParseTreeNode* node, int depth);

int token_count = 0;
void print_token(const char* token_name, const char* token_value);

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
            return;
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
}

void update_symbol_table(char *name, char *type, char *scope, char *value) {
    struct SymbolEntry *current = symbolTable;
    int found = 0;
    
    while (current != NULL) {
        if (strcmp(current->name, name) == 0 && strcmp(current->scope, current_scope) == 0) {
            found = 1;
            break;
        }
        current = current->next;
    }
    
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
    } else {
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

void print_token(const char* token_name, const char* token_value) {
    token_count++;
    if (token_value) {
        printf("Token %d: %s (%s)\n", token_count, token_name, token_value);
    } else {
        printf("Token %d: %s\n", token_count, token_name);
    }
}

struct ParseTreeNode* create_node(const char* type, const char* value) {
    struct ParseTreeNode* node = (struct ParseTreeNode*)malloc(sizeof(struct ParseTreeNode));
    if (!node) {
        fprintf(stderr, "Error: Memory allocation failed for parse tree node\n");
        exit(1);
    }
    strcpy(node->type, type);
    strcpy(node->value, value ? value : "");
    node->num_children = 0;
    
    node->node_id = create_dot_node(value && strlen(value) > 0 ? value : type);
    
    return node;
}

void add_child(struct ParseTreeNode* parent, struct ParseTreeNode* child) {
    if (!parent || !child) return;
    
    if (parent->num_children < 10) {
        parent->children[parent->num_children++] = child;
        
        create_dot_edge(parent->node_id, child->node_id);
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

void open_dot_file() {
    dotFile = fopen("parse_tree.dot", "w");
    if (dotFile == NULL) {
        fprintf(stderr, "Error opening dot file\n");
        return;
    }
    fprintf(dotFile, "digraph ParseTree {\n");
    fprintf(dotFile, "  node [shape=box, fontname=\"Arial\"];\n");
    fprintf(dotFile, "  rankdir=LR;\n");  
    node_count = 0;
}

void close_dot_file() {
    if (dotFile) {
        fprintf(dotFile, "}\n");
        fclose(dotFile);
        printf("Parse tree written to parse_tree.dot\n");
    }
}

int create_dot_node(const char* label) {
    int id = node_count++;
    char escaped_label[200];
    
    
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


%define parse.trace


%union {
    char *str;
    int num;
    struct ParseTreeNode *node;
}


%token <str> IDENT TYPE
%token <str> INTEGER STRING DECIMAL
%token <str> ASSIGN_OP COMP_OP
%token IF ELSE FOR WHILE DO RETURN PRINT SEMICOLON COMMA
%token INC DEC LOGICAL_NOT BITWISE_NOT
%token '+' '-' '*' '/'
%token MAIN INVALID_TOKEN  


%type <node> program global_declaration_list global_declaration
%type <node> expression variable declaration
%type <node> var_declaration function_declaration
%type <node> simple_expression additive_expression term factor postfix_expr
%type <node> parameter_list parameter compound_stmt
%type <node> statement_list statement
%type <node> local_declarations
%type <node> expression_stmt if_stmt while_stmt for_stmt return_stmt print_stmt assignment_stmt
%type <node> call args arg_list


%nonassoc IFX
%nonassoc ELSE
%left '+' '-'
%left '*' '/'
%right UMINUS  


%define parse.error verbose

%%


program:
    global_declaration_list {
        $$ = create_node("PROGRAM", "program");
        root = $$;
        
        
        add_child($$, $1);
    }
    ;

global_declaration_list:
    global_declaration_list global_declaration {
        $$ = $1;
        
        add_child($$, $2);
    }
    | global_declaration {
        $$ = create_node("DECLARATIONS", "");
        add_child($$, $1);
    }
    ;

global_declaration:
    declaration {
        $$ = $1;
    }
    | statement {
        $$ = $1;
    }
    | error SEMICOLON { 
        yyerror("Syntax error in global declaration - recovered at semicolon");
        yyerrok; 
        $$ = create_node("ERROR", "global_declaration");
    }
    | error '}' { 
        yyerror("Syntax error in global declaration - recovered at closing brace");
        yyerrok; 
        $$ = create_node("ERROR", "global_declaration");
    }
    ;

declaration:
    var_declaration { 
        $$ = $1;
    }
    | function_declaration { 
        $$ = $1;
    }
    ;

var_declaration:
    TYPE IDENT SEMICOLON {
        add_to_symbol_table($2, $1, current_scope, "");
        $$ = create_node("VAR_DECLARATION", "");
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", $2);
        add_child($$, type_node);
        add_child($$, id_node);
    }
    | TYPE IDENT ASSIGN_OP expression SEMICOLON {
        add_to_symbol_table($2, $1, current_scope, "");
        $$ = create_node("VAR_DECLARATION_INIT", "");
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", $2);
        struct ParseTreeNode* assign_node = create_node("ASSIGN", $3);
        add_child($$, type_node);
        add_child($$, id_node);
        add_child($$, assign_node);
        add_child(assign_node, $4);
    }
    | error SEMICOLON {
        yyerror("Syntax error in variable declaration - recovered at semicolon");
        yyerrok;
        $$ = create_node("ERROR", "var_declaration");
    }
    ;


function_declaration:
    TYPE IDENT '(' parameter_list ')' compound_stmt {
        add_to_symbol_table($2, $1, "function", "");
        $$ = create_node("FUNCTION_DECLARATION", "");
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", $2);
        add_child($$, type_node);
        add_child($$, id_node);
        add_child($$, $4);
        add_child($$, $6);
    }
    | TYPE MAIN '(' parameter_list ')' compound_stmt {
        add_to_symbol_table("main", $1, "function", "");
        $$ = create_node("FUNCTION_DECLARATION", "");
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", "main");
        add_child($$, type_node);
        add_child($$, id_node);
        add_child($$, $4);
        add_child($$, $6);
    }
    | error ')' compound_stmt {
        yyerror("Syntax error in function declaration - recovered at closing parenthesis");
        yyerrok;
        $$ = create_node("ERROR", "function_declaration");
        add_child($$, $3);
    }
    ;

parameter_list:
    parameter_list COMMA parameter {
        $$ = $1;
        add_child($$, $3);
    }
    | parameter {
        $$ = create_node("PARAMETER_LIST", "");
        add_child($$, $1);
    }
    |  {
        $$ = create_node("PARAMETER_LIST", "empty");
    }
    | error ')' {
        yyerror("Syntax error in parameter list - recovered at closing parenthesis");
        yyerrok;
        $$ = create_node("ERROR", "parameter_list");
    }
    ;

parameter:
    TYPE IDENT {
        add_to_symbol_table($2, $1, "parameter", "");
        $$ = create_node("PARAMETER", "");
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", $2);
        add_child($$, type_node);
        add_child($$, id_node);
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
        $$ = create_node("COMPOUND_STATEMENT", "");
        add_child($$, $3);
        add_child($$, $4);
    }
    | '{' error '}' {
        yyerror("Syntax error in compound statement - recovered at closing brace");
        yyerrok;
        $$ = create_node("ERROR", "compound_statement");
    }
    ;

local_declarations:
    local_declarations var_declaration {
        $$ = $1;
        add_child($$, $2);
    }
    |  {
        $$ = create_node("LOCAL_DECLARATIONS", "");
    }
    ;

statement_list:
    statement_list statement {
        $$ = $1;
        add_child($$, $2);
    }
    |{
        $$ = create_node("STATEMENT_LIST", "");
    }
    | error '}' { 
        yyerror("Syntax error in statement block - recovered at closing brace"); 
        yyerrok;
        $$ = create_node("ERROR", "statement_block");
    }
    ;

statement:
    assignment_stmt {
        $$ = $1;
    }
    | expression_stmt {
        $$ = $1;
    }
    | compound_stmt {
        $$ = $1;
    }
    | if_stmt {
        $$ = $1;
    }
    | while_stmt {
        $$ = $1;
    }
    | for_stmt {
        $$ = $1;
    }
    | return_stmt {
        $$ = $1;
    }
    | print_stmt {
        $$ = $1;
    }
    | call SEMICOLON {
        $$ = create_node("FUNCTION_CALL_STATEMENT", "");
        add_child($$, $1);
    }
    | SEMICOLON {
        $$ = create_node("EMPTY_STATEMENT", "");
    }
    | error SEMICOLON { 
        yyerror("Syntax error in statement - recovered at semicolon"); 
        yyerrok;
        $$ = create_node("ERROR", "statement");
    }
    ;

assignment_stmt:
    variable ASSIGN_OP expression SEMICOLON {
        update_symbol_table($1->value, "unknown", current_scope, "");
        $$ = create_node("ASSIGNMENT_STATEMENT", "");
        add_child($$, $1);
        struct ParseTreeNode* op_node = create_node("ASSIGN_OP", $2);
        add_child($$, op_node);
        add_child($$, $3);
    }
    | error SEMICOLON {
        yyerror("Syntax error in assignment - recovered at semicolon");
        yyerrok;
        $$ = create_node("ERROR", "assignment_statement");
    }
    ;

expression_stmt:
    expression SEMICOLON {
        $$ = create_node("EXPRESSION_STATEMENT", "");
        add_child($$, $1);
    }
    ;

for_stmt:
    FOR '(' expression SEMICOLON expression SEMICOLON expression ')' statement {
        $$ = create_node("FOR_STATEMENT", "");
        struct ParseTreeNode* init_node = create_node("INIT_EXPR", "");
        struct ParseTreeNode* cond_node = create_node("CONDITION", "");
        struct ParseTreeNode* iter_node = create_node("ITERATION", "");
        add_child(init_node, $3);
        add_child(cond_node, $5);
        add_child(iter_node, $7);
        add_child($$, init_node);
        add_child($$, cond_node);
        add_child($$, iter_node);
        add_child($$, $9);
    }
    | FOR '(' error ')' statement {
        yyerror("Syntax error in for loop parameters - recovered at closing parenthesis");
        yyerrok;
        $$ = create_node("ERROR", "for_statement");
        add_child($$, $5);
    }
    ;

if_stmt:
    IF '(' expression ')' statement %prec IFX {
        $$ = create_node("IF_STATEMENT", "");
        struct ParseTreeNode* cond_node = create_node("CONDITION", "");
        add_child(cond_node, $3);
        add_child($$, cond_node);
        add_child($$, $5);
    }
    | IF '(' expression ')' statement ELSE statement {
        $$ = create_node("IF_ELSE_STATEMENT", "");
        struct ParseTreeNode* cond_node = create_node("CONDITION", "");
        struct ParseTreeNode* then_node = create_node("THEN", "");
        struct ParseTreeNode* else_node = create_node("ELSE", "");
        add_child(cond_node, $3);
        add_child(then_node, $5);
        add_child(else_node, $7);
        add_child($$, cond_node);
        add_child($$, then_node);
        add_child($$, else_node);
    }
    | IF '(' error ')' statement {
        yyerror("Syntax error in if condition - recovered at closing parenthesis");
        yyerrok;
        $$ = create_node("ERROR", "if_statement");
        add_child($$, $5);
    }
    ;

while_stmt:
    WHILE '(' expression ')' statement {
        $$ = create_node("WHILE_STATEMENT", "");
        struct ParseTreeNode* cond_node = create_node("CONDITION", "");
        add_child(cond_node, $3);
        add_child($$, cond_node);
        add_child($$, $5);
    }
    | DO statement WHILE '(' expression ')' SEMICOLON {
        $$ = create_node("DO_WHILE_STATEMENT", "");
        struct ParseTreeNode* body_node = create_node("BODY", "");
        struct ParseTreeNode* cond_node = create_node("CONDITION", "");
        add_child(body_node, $2);
        add_child(cond_node, $5);
        add_child($$, body_node);
        add_child($$, cond_node);
    }
    | WHILE '(' error ')' statement {
        yyerror("Syntax error in while condition - recovered at closing parenthesis");
        yyerrok;
        $$ = create_node("ERROR", "while_statement");
        add_child($$, $5);
    }
    ;

return_stmt:
    RETURN SEMICOLON {
        $$ = create_node("RETURN_STATEMENT", "void");
    }
    | RETURN expression SEMICOLON {
        $$ = create_node("RETURN_STATEMENT", "");
        add_child($$, $2);
    }
    | RETURN error SEMICOLON {
        yyerror("Syntax error in return statement - recovered at semicolon");
        yyerrok;
        $$ = create_node("ERROR", "return_statement");
    }
    ;

print_stmt:
    PRINT '(' expression ')' SEMICOLON {
        $$ = create_node("PRINT_STATEMENT", "");
        add_child($$, $3);
    }
    | PRINT '(' error ')' SEMICOLON {
        yyerror("Syntax error in print statement - recovered at closing parenthesis");
        yyerrok;
        $$ = create_node("ERROR", "print_statement");
    }
    ;


call:
    IDENT '(' args ')' {
        $$ = create_node("FUNCTION_CALL", $1);
        add_child($$, $3);
    }
    | IDENT '(' error ')' {
        yyerror("Syntax error in function call - recovered at closing parenthesis");
        yyerrok;
        $$ = create_node("ERROR", "function_call");
    }
    ;

args:
    arg_list { 
        $$ = create_node("ARGUMENTS", "");
        add_child($$, $1);
    }
    |  { 
        $$ = create_node("ARGUMENTS", "empty");
    }
    ;

arg_list:
    arg_list COMMA expression {
        $$ = $1;
        add_child($$, $3);
    }
    | expression { 
        $$ = create_node("ARG_LIST", "");
        add_child($$, $1);
    }
    ;


expression:
    variable ASSIGN_OP expression {
        update_symbol_table($1->value, "unknown", current_scope, "");
        $$ = create_node("ASSIGNMENT_EXPRESSION", "");
        add_child($$, $1);
        struct ParseTreeNode* op_node = create_node("ASSIGN_OP", $2);
        add_child($$, op_node);
        add_child($$, $3);
    }
    | simple_expression {
        $$ = $1;
    }
    | call {
        $$ = $1;
    }
    ;

variable:
    IDENT {
        $$ = create_node("VARIABLE", $1);
    }
    ;


postfix_expr:
    variable { 
        $$ = $1;
    }
    | variable INC {
        $$ = create_node("POSTFIX_INCREMENT", "");
        add_child($$, $1);
    }
    | variable DEC {
        $$ = create_node("POSTFIX_DECREMENT", "");
        add_child($$, $1);
    }
    | call { 
        $$ = $1;
    }
    ;


factor:
    '-' factor %prec UMINUS {
        $$ = create_node("UNARY_MINUS", "");
        add_child($$, $2);
    }
    | '+' factor {
        $$ = create_node("UNARY_PLUS", "");
        add_child($$, $2);
    }
    | LOGICAL_NOT factor {
        $$ = create_node("LOGICAL_NOT", "");
        add_child($$, $2);
    }
    | BITWISE_NOT factor {
        $$ = create_node("BITWISE_NOT", "");
        add_child($$, $2);
    }
    | INC variable {
        $$ = create_node("PREFIX_INCREMENT", "");
        add_child($$, $2);
    }
    | DEC variable {
        $$ = create_node("PREFIX_DECREMENT", "");
        add_child($$, $2);
    }
    | '(' expression ')' {
        $$ = create_node("PARENTHESIZED_EXPR", "");
        add_child($$, $2);
    }
    | postfix_expr {
        $$ = $1;
    }
    | INTEGER {
        $$ = create_node("INTEGER_LITERAL", $1);
    }
    | DECIMAL {
        $$ = create_node("DECIMAL_LITERAL", $1);
    }
    | STRING {
        $$ = create_node("STRING_LITERAL", $1);
    }
    | error ')' {
        yyerror("Syntax error in factor - recovered at closing parenthesis");
        yyerrok;
        $$ = create_node("ERROR", "factor");
    }
    ;


simple_expression:
    additive_expression {
        $$ = $1;
    }
    | additive_expression COMP_OP additive_expression {
        $$ = create_node("COMPARISON_EXPRESSION", $2);
        add_child($$, $1);
        add_child($$, $3);
    }
    ;


additive_expression:
    term {
        $$ = $1;
    }
    | additive_expression '+' term {
        $$ = create_node("ADDITION", "+");
        add_child($$, $1);
        add_child($$, $3);
    }
    | additive_expression '-' term {
        $$ = create_node("SUBTRACTION", "-");
        add_child($$, $1);
        add_child($$, $3);
    }
    ;

term:
    factor {
        $$ = $1;
    }
    | term '*' factor {
        $$ = create_node("MULTIPLICATION", "*");
        add_child($$, $1);
        add_child($$, $3);
    }
    | term '/' factor {
        $$ = create_node("DIVISION", "/");
        add_child($$, $1);
        add_child($$, $3);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", yylineno, s);
}


int custom_yylex(void) {
    int token = yylex();
    
    
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
        case MAIN:
            print_token("MAIN", NULL);
            break;
        case INVALID_TOKEN:
            print_token("INVALID_TOKEN", NULL);
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
            print_token("LPAREN", NULL);
            break;
        case ')':
            print_token("RPAREN", NULL);
            break;
        case '{':
            print_token("LBRACE", NULL);
            break;
        case '}':
            print_token("RBRACE", NULL);
            break;
        default:
            print_token("UNKNOWN", NULL);
    }
    
    return token;
}


void free_parse_tree(struct ParseTreeNode* node) {
    if (node == NULL) return;
    
    
    for (int i = 0; i < node->num_children; i++) {
        free_parse_tree(node->children[i]);
    }
    
    
    free(node);
}


void visualize_parse_tree(struct ParseTreeNode* node, int depth, char* prefix, int is_last) {
    if (node == NULL) return;
    
    
    char new_prefix[1024];
    strcpy(new_prefix, prefix);
    
    
    printf("%s", prefix);
    if (is_last) {
        printf("└── ");
        strcat(new_prefix, "    ");
    } else {
        printf("├── ");
        strcat(new_prefix, "│   ");
    }
    
    if (strlen(node->value) > 0) {
        printf("%s (%s)\n", node->type, node->value);
    } else {
        printf("%s\n", node->type);
    }
    
    
    for (int i = 0; i < node->num_children; i++) {
        visualize_parse_tree(node->children[i], depth + 1, new_prefix, i == node->num_children - 1);
    }
}


void free_symbol_table() {
    struct SymbolEntry *current = symbolTable;
    struct SymbolEntry *next;
    
    while (current != NULL) {
        next = current->next;
        free(current);
        current = next;
    }
    
    symbolTable = NULL;
}


int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *input = fopen(argv[1], "r");
        if (!input) {
            fprintf(stderr, "Error: Could not open input file %s\n", argv[1]);
            return 1;
        }
        
        extern FILE *yyin;
        yyin = input;
    }
    
    open_dot_file();
    
    printf("\n=== Starting Parsing ===\n\n");
    
    int parse_result = yyparse();
    
    if (parse_result == 0) {
        printf("\n=== Parsing Completed Successfully ===\n\n");
        
        print_symbol_table();
        
        printf("\n=== Parse Tree (Text Representation) ===\n\n");
        if (root) {
            char prefix[1024] = "";
            visualize_parse_tree(root, 0, prefix, 1);
        } else {
            printf("No parse tree was generated.\n");
        }
    } else {
        printf("\n=== Parsing Failed ===\n\n");
    }
    
    close_dot_file();
    

    if (root) free_parse_tree(root);
    free_symbol_table();
    
    return parse_result;
}