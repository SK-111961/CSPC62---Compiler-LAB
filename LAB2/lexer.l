%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

extern YYSTYPE yylval;

// Memory management helper
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

{COMMENT}   ;  // Ignore comments

"if_SK"     { return IF; }
"else_SK"   { return ELSE; }
"for_SK"    { return FOR; }
"while_SK"  { return WHILE; }
"do_SK"     { return DO; }
"return_SK" { return RETURN; }
"print_SK"  { return PRINT; }

{TYPE}      { 
               yylval.str = copy_string(yytext);
               return TYPE; 
            }

{COMP_OP}   { 
               printf("COMP_OP: %s\n", yytext);
               yylval.str = copy_string(yytext);
               return COMP_OP; 
            }

{ASSIGN_OP} { 
               yylval.str = copy_string(yytext);
               return ASSIGN_OP; 
            }

";"         { return SEMICOLON; }
","         { return COMMA; }
"{"         { return '{'; }
"}"         { return '}'; }
"("         { return '('; }
")"         { return ')'; }
"++"        { return INC; }  /* Changed from INCR_OP to INC to match parser */
"--"        { return DEC; }  /* Changed from DECR_OP to DEC to match parser */
"!"         { return LOGICAL_NOT; }
"~"         { return BITWISE_NOT; }
"+"         { return '+'; }
"-"         { return '-'; }
"*"         { return '*'; }
"/"         { return '/'; }

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

[ \t\n]     ;  // Ignore whitespace
.           { fprintf(stderr, "ERROR: Invalid token '%s' at line %d\n", yytext, yylineno); }

%%

// main() is in the parser file