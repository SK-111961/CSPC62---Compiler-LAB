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

// Function to add an entry to the symbol table
void add_to_symbol_table(char *name, char *type, char *scope, char *value) {
    struct SymbolEntry *newEntry = (struct SymbolEntry*) malloc(sizeof(struct SymbolEntry));
    strcpy(newEntry->name, name);
    strcpy(newEntry->type, type);
    strcpy(newEntry->scope, scope);
    strcpy(newEntry->value, value);
    newEntry->next = symbolTable;
    symbolTable = newEntry;
}

// Function to update an entry in the symbol table
void update_symbol_table(char *name, char *type, char *scope, char *value) {
    struct SymbolEntry *current = symbolTable;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            strcpy(current->type, type);
            strcpy(current->scope, scope);
            strcpy(current->value, value);
            return;
        }
        current = current->next;
    }
    add_to_symbol_table(name, type, scope, value);
}

// Function to print the symbol table
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

// Function to print the parse tree
void print_parse_tree(const char *node, int level) {
    for (int i = 0; i < level; i++) printf("  ");
    printf("%s\n", node);
}
%}

// Tokens
%token IDENT NUMBER
%token IF_SK ELSE_SK WHILE_SK RETURN_SK PRINT_SK INT_SK FLOAT_SK VOID_SK

// Precedence and Associativity
%left '+' '-'
%left '*' '/'
%right '='

// Grammar Rules
%%

Program: DeclarationList {
    print_parse_tree("Program", 0);
};

DeclarationList: Declaration DeclarationList {
    print_parse_tree("DeclarationList", 1);
} | ;

Declaration: VariableDecl {
    print_parse_tree("Declaration (VariableDecl)", 2);
} | FunctionDecl {
    print_parse_tree("Declaration (FunctionDecl)", 2);
};

VariableDecl: Type IDENT '=' Expression ';' {
    add_to_symbol_table($2, $1, "global", $4);
    print_parse_tree("VariableDecl", 3);
};

FunctionDecl: Type IDENT '(' ParamList ')' Block {
    print_parse_tree("FunctionDecl", 3);
};

ParamList: Param ParamListTail {
    print_parse_tree("ParamList", 4);
} | ;

ParamListTail: ',' Param ParamListTail {
    print_parse_tree("ParamListTail", 5);
} | ;

Param: Type IDENT {
    print_parse_tree("Param", 5);
};

Block: '{' StatementList '}' {
    print_parse_tree("Block", 3);
};

StatementList: Statement StatementList {
    print_parse_tree("StatementList", 4);
} | ;

Statement: VariableDecl {
    print_parse_tree("Statement (VariableDecl)", 5);
} | Assignment {
    print_parse_tree("Statement (Assignment)", 5);
} | IfStmt {
    print_parse_tree("Statement (IfStmt)", 5);
} | WhileStmt {
    print_parse_tree("Statement (WhileStmt)", 5);
} | ReturnStmt {
    print_parse_tree("Statement (ReturnStmt)", 5);
} | PrintStmt {
    print_parse_tree("Statement (PrintStmt)", 5);
} | error ';' {
    printf("Error: Skipping invalid statement\n");
};

Assignment: IDENT '=' Expression ';' {
    update_symbol_table($1, "unknown", "global", $3);
    print_parse_tree("Assignment", 6);
};

IfStmt: IF_SK '(' Expression ')' Block ElseStmt {
    print_parse_tree("IfStmt", 6);
};

ElseStmt: ELSE_SK Block {
    print_parse_tree("ElseStmt", 7);
} | ;

WhileStmt: WHILE_SK '(' Expression ')' Block {
    print_parse_tree("WhileStmt", 6);
};

ReturnStmt: RETURN_SK Expression ';' {
    print_parse_tree("ReturnStmt", 6);
};

PrintStmt: PRINT_SK '(' Expression ')' ';' {
    print_parse_tree("PrintStmt", 6);
};

Expression: Term ExpressionTail {
    print_parse_tree("Expression", 7);
};

ExpressionTail: AddOp Term ExpressionTail {
    print_parse_tree("ExpressionTail", 8);
} | ;

Term: Factor TermTail {
    print_parse_tree("Term", 8);
};

TermTail: MulOp Factor TermTail {
    print_parse_tree("TermTail", 9);
} | ;

Factor: IDENT {
    print_parse_tree("Factor (IDENT)", 9);
} | NUMBER {
    print_parse_tree("Factor (NUMBER)", 9);
} | '(' Expression ')' {
    print_parse_tree("Factor (Expression)", 9);
} | FunctionCall {
    print_parse_tree("Factor (FunctionCall)", 9);
};

FunctionCall: IDENT '(' ArgList ')' {
    print_parse_tree("FunctionCall", 10);
};

ArgList: Expression ArgListTail {
    print_parse_tree("ArgList", 11);
} | ;

ArgListTail: ',' Expression ArgListTail {
    print_parse_tree("ArgListTail", 12);
} | ;

AddOp: '+' {
    print_parse_tree("AddOp (+)", 10);
} | '-' {
    print_parse_tree("AddOp (-)", 10);
};

MulOp: '*' {
    print_parse_tree("MulOp (*)", 10);
} | '/' {
    print_parse_tree("MulOp (/)", 10);
};

Type: INT_SK {
    print_parse_tree("Type (int_SK)", 11);
} | FLOAT_SK {
    print_parse_tree("Type (float_SK)", 11);
} | VOID_SK {
    print_parse_tree("Type (void_SK)", 11);
};

%%

int main() {
    yyparse();
    print_symbol_table();
    return 0;
}