%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

extern YYSTYPE yylval;

char* copy_string(char* s) {
    char* result = strdup(s);
    if (!result) {
        fprintf(stderr, "Error: Memory allocation failed\n");
        exit(1);
    }
    return result;
}
%}

%option noyywrap
%option yylineno

COMMENT   \/\/[^\n]*
KEYWORD   (main_SK|const_SK|if_SK|else_SK|elseif_SK|switch_SK|case_SK|default_SK|for_SK|while_SK|do_SK|break_SK|continue_SK|goto_SK|return_SK|auto_SK|register_SK|static_SK|extern_SK|volatile_SK|struct_SK|union_SK|enum_SK|typedef_SK|sizeof_SK|print_SK)
TYPE      (char_SK|int_SK|float_SK|double_SK|void_SK|short_SK|long_SK|signed_SK|unsigned_SK|string_SK)
IDENT     135[a-zA-Z_][a-zA-Z0-9_]*
INTEGER   [0-9]+
DECIMAL   [0-9]+\.[0-9]+
STRING    \"([^\\\"]|\\.)*\"
COMP_OP   (==|!=|>|>=|<|<=)
ASSIGN_OP =
PUNCT     [,;:.]
BRACKET   [(){}\[\]]

%%

{COMMENT}   { printf("COMMENT: %s\n", yytext); }

"if_SK"     { return IF; }
"else_SK"   { return ELSE; }
"for_SK"    { return FOR; }
"while_SK"  { return WHILE; }
"do_SK"     { return DO; }
"return_SK" { return RETURN; }
"print_SK"  { return PRINT; }
"main_SK"   { return MAIN; }

{TYPE}      { 
               printf("TYPE: %s\n", yytext);
               yylval.str = copy_string(yytext);
               return TYPE; 
            }

{COMP_OP}   { 
               printf("COMP_OP: %s\n", yytext);
               yylval.str = copy_string(yytext);
               return COMP_OP; 
            }

{ASSIGN_OP} { 
               printf("ASSIGN_OP: %s\n", yytext);
               yylval.str = copy_string(yytext);
               return ASSIGN_OP; 
            }

";"         { printf("SEMICOLON\n"); return SEMICOLON; }
","         { printf("COMMA\n"); return COMMA; }
"{"         { printf("LBRACE\n"); return '{'; }
"}"         { printf("RBRACE\n"); return '}'; }
"("         { printf("LPAREN\n"); return '('; }
")"         { printf("RPAREN\n"); return ')'; }
"["         { printf("LBRACKET\n"); return '['; }
"]"         { printf("RBRACKET\n"); return ']'; }
"++"        { printf("INC\n"); return INC; }
"--"        { printf("DEC\n"); return DEC; }
"!"         { printf("LOGICAL_NOT\n"); return LOGICAL_NOT; }
"~"         { printf("BITWISE_NOT\n"); return BITWISE_NOT; }
"+"         { printf("PLUS\n"); return '+'; }
"-"         { printf("MINUS\n"); return '-'; }
"*"         { printf("MULTIPLY\n"); return '*'; }
"/"         { printf("DIVIDE\n"); return '/'; }

{IDENT}     { 
               printf("IDENT: %s\n", yytext); 
               yylval.str = copy_string(yytext);
               return IDENT;
            }

{INTEGER}   { 
               printf("INTEGER: %s\n", yytext); 
               yylval.str = copy_string(yytext);
               return INTEGER;
            }

{DECIMAL}   { 
               printf("DECIMAL: %s\n", yytext); 
               yylval.str = copy_string(yytext);
               return DECIMAL;
            }

{STRING}    { 
               printf("STRING: %s\n", yytext); 
               yylval.str = copy_string(yytext);
               return STRING;
            }

[ \t\n]     { 
               if (yytext[0] == '\n') printf("NEWLINE\n");
            }

.           { 
               fprintf(stderr, "ERROR: Invalid token '%s' at line %d\n", yytext, yylineno);
               return INVALID_TOKEN;  
            }

%%