%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


struct SymbolEntry {
    char name[50];
    char type[20];          
    char scope[50];         
    char kind[20];          
    int array_dimensions;   
    int array_sizes[3];     
    char value[50];         
    int is_initialized;     
    int param_count;
    char param_types[10][20];
    int overload_id; 
    struct SymbolEntry *next;

};

struct SymbolEntry *symbolTable = NULL;
char current_scope[50] = "global";
char current_function_return_type[20] = "";


struct ParseTreeNode {
    char type[50];          
    char value[100];        
    char data_type[20];     
    int is_lvalue;          
    struct ParseTreeNode *children[10];
    int num_children;
    int node_id;
    int param_count;
    char param_types[10][20];
    int arg_count;
    char arg_types[10][20];
};

struct ParseTreeNode* root = NULL;


void add_to_symbol_table(char *name, char *type, char *scope, char *kind, char *value);
struct SymbolEntry* lookup_symbol(char *name, char *scope);
void update_symbol_table(char *name, char *type, char *scope, char *value);
void print_symbol_table();
void print_semantic_error(const char *error_msg, int line_no);
char* check_type_compatibility(char *type1, char *type2, char *operation);
int is_compatible_type(char *expected, char *actual);
int is_numeric_type(char *type);
extern int yylex(void);
extern int yylineno;
void yyerror(const char *s);

struct ParseTreeNode* create_node(const char* type, const char* value);
void add_child(struct ParseTreeNode* parent, struct ParseTreeNode* child);
void print_tree(struct ParseTreeNode* node, int depth, char* prefix);

int token_count = 0;
void print_token(const char* token_name, const char* token_value);

FILE* dotFile = NULL;
int node_count = 0;
void open_dot_file();
void close_dot_file();
int create_dot_node(const char* label);
void create_dot_edge(int parent, int child);


void add_to_symbol_table(char *name, char *type, char *scope, char *kind, char *value) {
    struct SymbolEntry *current = lookup_symbol(name, scope);
    
    if (current != NULL) {
        print_semantic_error("Redeclaration of variable", yylineno);
        return;
    }
    
    struct SymbolEntry *newEntry = (struct SymbolEntry*) malloc(sizeof(struct SymbolEntry));
    if (!newEntry) {
        fprintf(stderr, "Error: Memory allocation failed for symbol table entry\n");
        exit(1);
    }
    
    strcpy(newEntry->name, name);
    strcpy(newEntry->type, type);
    strcpy(newEntry->scope, scope);
    strcpy(newEntry->kind, kind);
    strcpy(newEntry->value, value);
    newEntry->is_initialized = 0;
    newEntry->array_dimensions = 0;
    
    newEntry->next = symbolTable;
    symbolTable = newEntry;
}

struct SymbolEntry* lookup_symbol(char *name, char *scope) {
    struct SymbolEntry *current = symbolTable;
    
    
    while (current != NULL) {
        if (strcmp(current->name, name) == 0 && strcmp(current->scope, scope) == 0) {
            return current;
        }
        current = current->next;
    }
    
    
    if (strcmp(scope, "global") != 0) {
        current = symbolTable;
        while (current != NULL) {
            if (strcmp(current->name, name) == 0 && strcmp(current->scope, "global") == 0) {
                return current;
            }
            current = current->next;
        }
    }
    
    return NULL;
}

void update_symbol_table(char *name, char *type, char *scope, char *value) {
    struct SymbolEntry *entry = lookup_symbol(name, current_scope);
    
    if (!entry) {
        entry = lookup_symbol(name, "global");
    }
    
    if (entry) {
        if (type != NULL && strlen(type) > 0) strcpy(entry->type, type);
        if (value != NULL && strlen(value) > 0) strcpy(entry->value, value);
        entry->is_initialized = 1;
    } else {
        print_semantic_error("Use of undeclared variable", yylineno);
        add_to_symbol_table(name, type ? type : "unknown", scope ? scope : current_scope, "variable", value ? value : "");
    }
}

void print_symbol_table() {
    struct SymbolEntry *current = symbolTable;
    printf("\n=== Symbol Table ===\n");
    printf("+------+----------------------+------------+------------+------------+------------+-------------+\n");
    printf("| %-4s | %-20s | %-10s | %-10s | %-10s | %-10s | %-11s |\n", 
           "ID", "Name", "Type", "Scope", "Kind", "Params", "Initialized");
    printf("+------+----------------------+------------+------------+------------+------------+-------------+\n");
    while (current != NULL) {
        char params[100] = "";
        for(int i=0; i<current->param_count; i++) {
            strcat(params, current->param_types[i]);
            if(i < current->param_count-1) strcat(params, ",");
        }
        
        printf("| %-4d | %-20s | %-10s | %-10s | %-10s | %-10s | %-11s |\n", 
               current->overload_id, current->name, current->type, 
               current->scope, current->kind, params, 
               current->is_initialized ? "Yes" : "No");
        current = current->next;
    }
    printf("+------+----------------------+------------+------------+------------+------------+-------------+\n");
}


void print_semantic_error(const char *error_msg, int line_no) {
    fprintf(stderr, "Semantic Error at line %d: %s\n", line_no, error_msg);
}


char* check_type_compatibility(char *type1, char *type2, char *operation) {
    
    if (!type1 || !type2 || strlen(type1) == 0 || strlen(type2) == 0) {
        return "unknown";
    }
    
    
    if (strcmp(type1, type2) == 0) {
        return type1;
    }
    
    
    if (strcmp(operation, "+") == 0 && 
        (strcmp(type1, "string_SK") == 0 || strcmp(type2, "string_SK") == 0)) {
        return "string_SK";
    }
    
    
    if (is_numeric_type(type1) && is_numeric_type(type2)) {
        if (strcmp(type1, "double_SK") == 0 || strcmp(type2, "double_SK") == 0) {
            return "double_SK";
        } else if (strcmp(type1, "float_SK") == 0 || strcmp(type2, "float_SK") == 0) {
            return "float_SK";
        } else if (strcmp(type1, "long_SK") == 0 || strcmp(type2, "long_SK") == 0) {
            return "long_SK";
        } else {
            return "int_SK"; 
        }
    }
    
    return "incompatible";
}

int is_compatible_type(char *expected, char *actual) {
    if(strcmp(expected, actual) == 0) return 1;
    if(is_numeric_type(expected) && is_numeric_type(actual)) return 1;
    return 0;
}

int is_numeric_type(char *type) {
    return (type && (
        strcmp(type, "int_SK") == 0 ||
        strcmp(type, "float_SK") == 0 ||
        strcmp(type, "double_SK") == 0 ||
        strcmp(type, "long_SK") == 0 ||
        strcmp(type, "short_SK") == 0 ||
        strcmp(type, "unsigned_SK") == 0 ||
        strcmp(type, "signed_SK") == 0
    ));
}

struct ParseTreeNode* create_node(const char* type, const char* value) {
    struct ParseTreeNode* node = (struct ParseTreeNode*)malloc(sizeof(struct ParseTreeNode));
    if (!node) {
        fprintf(stderr, "Error: Memory allocation failed for parse tree node\n");
        exit(1);
    }
    strcpy(node->type, type);
    strcpy(node->value, value ? value : "");
    strcpy(node->data_type, ""); 
    node->is_lvalue = 0;         
    node->num_children = 0;
    
    node->node_id = create_dot_node(value && strlen(value) > 0 ? value : type);
    
    return node;
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
        add_to_symbol_table($2, $1, current_scope, "variable", "");
        $$ = create_node("VAR_DECLARATION", "");
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", $2);
        add_child($$, type_node);
        add_child($$, id_node);
    }
    | TYPE IDENT ASSIGN_OP expression SEMICOLON {
        add_to_symbol_table($2, $1, current_scope, "variable", "");
        
        
        if (strcmp(check_type_compatibility($1, $4->data_type, "="), "incompatible") == 0) {
            print_semantic_error("Type mismatch in initialization", yylineno);
        }
        
        
        struct SymbolEntry* entry = lookup_symbol($2, current_scope);
        if (entry) entry->is_initialized = 1;
        
        $$ = create_node("VAR_DECLARATION_INIT", "");
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", $2);
        struct ParseTreeNode* assign_node = create_node("ASSIGN", $3);
        add_child($$, type_node);
        add_child($$, id_node);
        add_child($$, assign_node);
        add_child(assign_node, $4);
    }
    | TYPE IDENT '[' INTEGER ']' SEMICOLON {
        
        struct SymbolEntry* newEntry = (struct SymbolEntry*) malloc(sizeof(struct SymbolEntry));
        strcpy(newEntry->name, $2);
        strcpy(newEntry->type, $1);
        strcpy(newEntry->scope, current_scope);
        strcpy(newEntry->kind, "array");
        strcpy(newEntry->value, "");
        newEntry->is_initialized = 0;
        newEntry->array_dimensions = 1;
        newEntry->array_sizes[0] = atoi($4);
        newEntry->next = symbolTable;
        symbolTable = newEntry;
        
        $$ = create_node("ARRAY_DECLARATION", "");
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", $2);
        struct ParseTreeNode* size_node = create_node("SIZE", $4);
        add_child($$, type_node);
        add_child($$, id_node);
        add_child($$, size_node);
    }
    | error SEMICOLON {
        yyerror("Syntax error in variable declaration - recovered at semicolon");
        yyerrok;
        $$ = create_node("ERROR", "var_declaration");
    }
    ;

function_declaration:
    TYPE IDENT '(' parameter_list ')' {
        struct SymbolEntry *func = lookup_symbol($2, "global");
        int overload_id = 0;
        
        while(func && strcmp(func->name, $2) == 0) {
            overload_id++;
            func = func->next;
        }
    
        add_to_symbol_table($2, $1, "global", "function", "");
        struct SymbolEntry *new_func = lookup_symbol($2, "global");
        new_func->overload_id = overload_id;
        
        new_func->param_count = $4->param_count;
        for(int i=0; i<$4->param_count; i++) {
            strcpy(new_func->param_types[i], $4->param_types[i]);
        }
    } compound_stmt {
        $$ = create_node("FUNCTION_DECLARATION", "");
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", $2);
        add_child($$, type_node);
        add_child($$, id_node);
        add_child($$, $4);
        add_child($$, $7);
        
        
        strcpy(current_scope, "global");
        strcpy(current_function_return_type, "");
    }
    | TYPE MAIN '(' parameter_list ')' {
        
        strcpy(current_function_return_type, $1);
        
        add_to_symbol_table("main", $1, "global", "function", "");
        
        strcpy(current_scope, "function_main");
    } compound_stmt {
        $$ = create_node("FUNCTION_DECLARATION", "");
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", "main");
        add_child($$, type_node);
        add_child($$, id_node);
        add_child($$, $4);
        add_child($$, $7);
        
        
        strcpy(current_scope, "global");
        strcpy(current_function_return_type, "");
    }
    ;

parameter:
    TYPE IDENT {
        // Add to symbol table
        add_to_symbol_table($2, $1, current_scope, "parameter", "");
        
        // Create node with type information
        $$ = create_node("PARAMETER", "");
        strcpy($$->data_type, $1);  // Store type in data_type field
        
        struct ParseTreeNode* type_node = create_node("TYPE", $1);
        struct ParseTreeNode* id_node = create_node("IDENTIFIER", $2);
        add_child($$, type_node);
        add_child($$, id_node);
    }
    ;

parameter_list:
    parameter_list COMMA parameter {
        $$ = $1;
        $$->param_count++;
        strcpy($$->param_types[$$->param_count-1], $3->data_type);
        add_child($$, $3);
    }
    | parameter {
        $$ = create_node("PARAMETER_LIST", "");
        $$->param_count = 1;
        strcpy($$->param_types[0], $1->data_type);
        add_child($$, $1);
    }
    | {
        $$ = create_node("PARAMETER_LIST", "empty");
        $$->param_count = 0;
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
        
        struct SymbolEntry* var_entry = lookup_symbol($1->value, current_scope);
        if (!var_entry) {
            var_entry = lookup_symbol($1->value, "global");
        }
        
        if (!var_entry) {
            print_semantic_error("Assignment to undeclared variable", yylineno);
        } else {
            
            if (strcmp(check_type_compatibility(var_entry->type, $3->data_type, "="), "incompatible") == 0) {
                print_semantic_error("Type mismatch in assignment", yylineno);
            }
            
            
            if (strcmp(var_entry->kind, "array") == 0) {
                print_semantic_error("Cannot assign directly to an array", yylineno);
            }
            
            
            var_entry->is_initialized = 1;
        }
        
        $$ = create_node("ASSIGNMENT_STATEMENT", "");
        add_child($$, $1);
        struct ParseTreeNode* op_node = create_node("ASSIGN_OP", $2);
        add_child($$, op_node);
        add_child($$, $3);
    }
    ;

expression_stmt:
    simple_expression SEMICOLON {
        $$ = create_node("EXPRESSION_STATEMENT", "");
        add_child($$, $1);
    }
    ;

for_stmt:
    FOR '(' expression SEMICOLON expression SEMICOLON expression ')' statement {
        
        if (strcmp($5->data_type, "") != 0 && 
            !is_numeric_type($5->data_type) && 
            strcmp($5->data_type, "incompatible") != 0) {
            print_semantic_error("Condition expression in for loop must be numeric or boolean", yylineno);
        }
        
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
    ;

if_stmt:
    IF '(' expression ')' statement %prec IFX {
        
        if (strcmp($3->data_type, "") != 0 && 
            !is_numeric_type($3->data_type) && 
            strcmp($3->data_type, "incompatible") != 0) {
            print_semantic_error("Condition expression in if statement must be numeric or boolean", yylineno);
        }
        
        $$ = create_node("IF_STATEMENT", "");
        struct ParseTreeNode* cond_node = create_node("CONDITION", "");
        add_child(cond_node, $3);
        add_child($$, cond_node);
        add_child($$, $5);
    }
    | IF '(' expression ')' statement ELSE statement {
        
        if (strcmp($3->data_type, "") != 0 && 
            !is_numeric_type($3->data_type) && 
            strcmp($3->data_type, "incompatible") != 0) {
            print_semantic_error("Condition expression in if statement must be numeric or boolean", yylineno);
        }
        
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
    ;

while_stmt:
    WHILE '(' expression ')' statement {
        
        if (strcmp($3->data_type, "") != 0 && 
            !is_numeric_type($3->data_type) && 
            strcmp($3->data_type, "incompatible") != 0) {
            print_semantic_error("Condition expression in while loop must be numeric or boolean", yylineno);
        }
        
        $$ = create_node("WHILE_STATEMENT", "");
        struct ParseTreeNode* cond_node = create_node("CONDITION", "");
        add_child(cond_node, $3);
        add_child($$, cond_node);
        add_child($$, $5);
    }
    | DO statement WHILE '(' expression ')' SEMICOLON {
        
        if (strcmp($5->data_type, "") != 0 && 
            !is_numeric_type($5->data_type) && 
            strcmp($5->data_type, "incompatible") != 0) {
            print_semantic_error("Condition expression in do-while loop must be numeric or boolean", yylineno);
        }
        
        $$ = create_node("DO_WHILE_STATEMENT", "");
        struct ParseTreeNode* body_node = create_node("BODY", "");
        struct ParseTreeNode* cond_node = create_node("CONDITION", "");
        add_child(body_node, $2);
        add_child(cond_node, $5);
        add_child($$, body_node);
        add_child($$, cond_node);
    }
    ;

return_stmt:
    RETURN SEMICOLON {
        
        if (strlen(current_function_return_type) > 0 && 
            strcmp(current_function_return_type, "void_SK") != 0) {
            print_semantic_error("Function with non-void return type must return a value", yylineno);
        }
        
        $$ = create_node("RETURN_STATEMENT", "void");
    }
    | RETURN expression SEMICOLON {
        
        if (strlen(current_function_return_type) > 0) {
            if (strcmp(current_function_return_type, "void_SK") == 0) {
                print_semantic_error("Void function cannot return a value", yylineno);
            } else if (strcmp(check_type_compatibility(current_function_return_type, $2->data_type, "return"), "incompatible") == 0) {
                print_semantic_error("Return type mismatch", yylineno);
            }
        }
        
        $$ = create_node("RETURN_STATEMENT", "");
        add_child($$, $2);
    }
    ;

print_stmt:
    PRINT '(' expression ')' SEMICOLON {
        $$ = create_node("PRINT_STATEMENT", "");
        add_child($$, $3);
    }
    ;

call:
    IDENT '(' args ')' {
        struct SymbolEntry *candidate = NULL;
        int best_match = -1;
        
        struct SymbolEntry *current = symbolTable;
        while(current) {
            if(strcmp(current->name, $1) == 0 && 
               current->param_count == $3->arg_count) {
                
                int match_score = 0;
                for(int i=0; i<current->param_count; i++) {
                    if(strcmp(current->param_types[i], $3->arg_types[i]) == 0) {
                        match_score += 2;
                    } else if(check_type_compatibility(current->param_types[i], $3->arg_types[i], "call")) {
                        match_score += 1;
                    }
                }
                
                if(match_score > best_match) {
                    best_match = match_score;
                    candidate = current;
                }
            }
            current = current->next;
        }
        
        if(!candidate) {
            print_semantic_error("No matching overload for function", yylineno);
            $$ = create_node("FUNCTION_CALL", $1);
            strcpy($$->data_type, "unknown"); // Default type to prevent crash
        } else {
            $$ = create_node("FUNCTION_CALL", $1);
            strcpy($$->data_type, candidate->type);
        }
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
        $$->arg_count++;
        strcpy($$->arg_types[$$->arg_count-1], $3->data_type);
        add_child($$, $3);
    }
    | expression {
        $$ = create_node("ARG_LIST", "");
        $$->arg_count = 1;
        strcpy($$->arg_types[0], $1->data_type);
        add_child($$, $1);
    }
    ;

expression:
    variable ASSIGN_OP expression {
        
        struct SymbolEntry* var_entry = lookup_symbol($1->value, current_scope);
        if (!var_entry) {
            var_entry = lookup_symbol($1->value, "global");
        }
        
        if (!var_entry) {
            print_semantic_error("Assignment to undeclared variable", yylineno);
            strcpy($$->data_type, "unknown");
        } else {
            
            if (strcmp(check_type_compatibility(var_entry->type, $3->data_type, "="), "incompatible") == 0) {
                print_semantic_error("Type mismatch in assignment expression", yylineno);
            }
            
            
            if (strcmp(var_entry->kind, "array") == 0) {
                print_semantic_error("Cannot assign directly to an array", yylineno);
            }
            
            
            var_entry->is_initialized = 1;
            strcpy($$->data_type, var_entry->type);
        }
        
        $$ = create_node("ASSIGNMENT_EXPRESSION", "");
        add_child($$, $1);
        struct ParseTreeNode* op_node = create_node("ASSIGN_OP", $2);
        add_child($$, op_node);
        add_child($$, $3);
    }
    | simple_expression {
        $$ = $1;
    }
    ;

variable:
    IDENT {
        
        struct SymbolEntry* var_entry = lookup_symbol($1, current_scope);
        if (!var_entry) {
            var_entry = lookup_symbol($1, "global");
        }
        
        if (!var_entry) {
            print_semantic_error("Use of undeclared variable", yylineno);
            $$ = create_node("VARIABLE", $1);
            strcpy($$->data_type, "unknown");
        } else {
            
            if (!var_entry->is_initialized && strcmp(var_entry->kind, "parameter") != 0) {
                print_semantic_error("Use of uninitialized variable", yylineno);
            }
            
            $$ = create_node("VARIABLE", $1);
            strcpy($$->data_type, var_entry->type);
            $$->is_lvalue = 1; 
        }
    }
    | IDENT '[' expression ']' {
        
        struct SymbolEntry* array_entry = lookup_symbol($1, current_scope);
        if (!array_entry) {
            array_entry = lookup_symbol($1, "global");
        }
        
        if (!array_entry) {
            print_semantic_error("Use of undeclared array", yylineno);
            $$ = create_node("ARRAY_ACCESS", $1);
            strcpy($$->data_type, "unknown");
        } else if (strcmp(array_entry->kind, "array") != 0) {
            print_semantic_error("Subscripted value is not an array", yylineno);
            $$ = create_node("ARRAY_ACCESS", $1);
            strcpy($$->data_type, "unknown");
        } else {
            
            if (!is_numeric_type($3->data_type)) {
                print_semantic_error("Array index must be an integer", yylineno);
            }
            
            $$ = create_node("ARRAY_ACCESS", $1);
            add_child($$, $3);
            strcpy($$->data_type, array_entry->type);
            $$->is_lvalue = 1; 
        }
    }
    ;

simple_expression:
    additive_expression {
        $$ = $1;
    }
    | additive_expression COMP_OP additive_expression {
        
        if (!is_numeric_type($1->data_type) || !is_numeric_type($3->data_type)) {
            if (strcmp($1->data_type, $3->data_type) != 0) {
                print_semantic_error("Type mismatch in comparison operation", yylineno);
            }
        }
        
        $$ = create_node("COMPARISON", $2);
        add_child($$, $1);
        add_child($$, $3);
        strcpy($$->data_type, "int_SK"); 
    }
    ;

additive_expression:
    additive_expression '+' term {
        
        char* result_type = check_type_compatibility($1->data_type, $3->data_type, "+");
        if (strcmp(result_type, "incompatible") == 0) {
            print_semantic_error("Type mismatch in addition operation", yylineno);
        }
        
        $$ = create_node("ADDITION", "+");
        add_child($$, $1);
        add_child($$, $3);
        strcpy($$->data_type, result_type);
    }
    | additive_expression '-' term {
        
        if (!is_numeric_type($1->data_type) || !is_numeric_type($3->data_type)) {
            print_semantic_error("Type mismatch in subtraction operation", yylineno);
        }
        
        $$ = create_node("SUBTRACTION", "-");
        add_child($$, $1);
        add_child($$, $3);
        strcpy($$->data_type, check_type_compatibility($1->data_type, $3->data_type, "-"));
    }
    | term {
        $$ = $1;
    }
    ;

term:
    term '*' factor {
        
        if (!is_numeric_type($1->data_type) || !is_numeric_type($3->data_type)) {
            print_semantic_error("Type mismatch in multiplication operation", yylineno);
        }
        
        $$ = create_node("MULTIPLICATION", "*");
        add_child($$, $1);
        add_child($$, $3);
        strcpy($$->data_type, check_type_compatibility($1->data_type, $3->data_type, "*"));
    }
    | term '/' factor {
        
        if (!is_numeric_type($1->data_type) || !is_numeric_type($3->data_type)) {
            print_semantic_error("Type mismatch in division operation", yylineno);
        }
        
        
        if (strcmp($3->type, "INTEGER") == 0 && strcmp($3->value, "0") == 0) {
            print_semantic_error("Division by zero", yylineno);
        }
        
        $$ = create_node("DIVISION", "/");
        add_child($$, $1);
        add_child($$, $3);
        strcpy($$->data_type, check_type_compatibility($1->data_type, $3->data_type, "/"));
    }
    | factor {
        $$ = $1;
    }
    ;

factor:
    '(' expression ')' {
        $$ = create_node("PARENTHESIZED_EXPR", "");
        add_child($$, $2);
        strcpy($$->data_type, $2->data_type);
    }
    | INTEGER {
        $$ = create_node("INTEGER", $1);
        strcpy($$->data_type, "int_SK");
    }
    | DECIMAL {
        $$ = create_node("DECIMAL", $1);
        strcpy($$->data_type, "float_SK");
    }
    | STRING {
        $$ = create_node("STRING", $1);
        strcpy($$->data_type, "string_SK");
    }
    | variable {
        $$ = $1;
    }
    | call {
        $$ = $1;
    }
    | '-' factor %prec UMINUS {
        
        if (!is_numeric_type($2->data_type)) {
            print_semantic_error("Unary minus requires numeric operand", yylineno);
        }
        
        $$ = create_node("UNARY_MINUS", "-");
        add_child($$, $2);
        strcpy($$->data_type, $2->data_type);
    }
    | postfix_expr {
        $$ = $1;
    }
    ;

postfix_expr:
    variable INC {
        
        if (!is_numeric_type($1->data_type)) {
            print_semantic_error("Increment requires numeric operand", yylineno);
        }
        
        if (!$1->is_lvalue) {
            print_semantic_error("Increment requires an lvalue", yylineno);
        }
        
        $$ = create_node("POSTFIX_INCREMENT", "++");
        add_child($$, $1);
        strcpy($$->data_type, $1->data_type);
    }
    | variable DEC {
        
        if (!is_numeric_type($1->data_type)) {
            print_semantic_error("Decrement requires numeric operand", yylineno);
        }
        
        if (!$1->is_lvalue) {
            print_semantic_error("Decrement requires an lvalue", yylineno);
        }
        
        $$ = create_node("POSTFIX_DECREMENT", "--");
        add_child($$, $1);
        strcpy($$->data_type, $1->data_type);
    }
    ;

%%


void add_child(struct ParseTreeNode* parent, struct ParseTreeNode* child) {
    if (parent && child && parent->num_children < 10) {
        parent->children[parent->num_children++] = child;
        create_dot_edge(parent->node_id, child->node_id);
    }
}

void print_tree(struct ParseTreeNode* node, int depth, char* prefix) {
    if (!node) return;
    
    
    printf("%s", prefix);
    
    
    printf("%s", node->type);
    
    
    if (strlen(node->value) > 0) {
        if (strcmp(node->type, "COMPARISON") == 0) {
            printf(" (%s)", node->value);
        } else if (strcmp(node->type, "VARIABLE") == 0 || 
                  strcmp(node->type, "STRING") == 0 || 
                  strcmp(node->type, "INTEGER") == 0) {
            printf(" (%s)", node->value);
        } else {
            printf(": %s", node->value);
        }
    }
    
    printf("\n");
    
    
    if (node->num_children > 0) {
        for (int i = 0; i < node->num_children; i++) {
            
            char new_prefix[1024];
            strcpy(new_prefix, prefix);
            
            if (i == node->num_children - 1) {
                strcat(new_prefix, "    ");  
            } else {
                strcat(new_prefix, "│   ");  
            }
            
            print_tree(node->children[i], depth + 1, new_prefix);
        }
    }
}

void open_dot_file() {
    dotFile = fopen("parse_tree.dot", "w");
    if (!dotFile) {
        fprintf(stderr, "Error: Unable to open dot file\n");
        return;
    }
    
    fprintf(dotFile, "digraph ParseTree {\n");
    fprintf(dotFile, "  node [shape=box, style=filled, fillcolor=lightblue];\n");
}

void close_dot_file() {
    if (dotFile) {
        fprintf(dotFile, "}\n");
        fclose(dotFile);
        printf("Parse tree written to parse_tree.dot\n");
    }
}

int create_dot_node(const char* label) {
    if (dotFile) {
        
        char escaped_label[200] = "";
        int j = 0;
        for (int i = 0; i < strlen(label) && j < 198; i++) {
            if (label[i] == '"' || label[i] == '\\') {
                escaped_label[j++] = '\\';
            }
            escaped_label[j++] = label[i];
        }
        escaped_label[j] = '\0';
        
        fprintf(dotFile, "  node%d [label=\"%s\"];\n", node_count, escaped_label);
    }
    return node_count++;
}

void create_dot_edge(int parent, int child) {
    if (dotFile) {
        fprintf(dotFile, "  node%d -> node%d;\n", parent, child);
    }
}


void yyerror(const char *s) {
    fprintf(stderr, "Parse Error at line %d: %s\n", yylineno, s);
}


int main(int argc, char **argv) {
    open_dot_file();
    
    if (yyparse() == 0) {
        printf("\nParsing completed successfully!\n");
        
        printf("\n=== Parse Tree ===\n");
        if (root) {
            print_tree(root, 0, "");
        }
        
        print_symbol_table();
    } else {
        printf("\nParsing failed!\n");
    }

    close_dot_file();
    return 0;
}