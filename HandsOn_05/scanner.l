%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

int lineno = 1;
%}

%%

"//"[^\n]*              { }

\n                      { lineno++; }

[ \t\r]+                { }

"#include"              { return INCLUDE; }
"#define"               { return DEFINE; }
"int"                   { return INT; }
"func"                  { return FUNC; }
"return"                { return RETURN; }
"if"                    { return IF; }

[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return ID; }
[0-9]+                  { yylval.num = atoi(yytext);   return NUM; }
\"[^\"]*\"              { yylval.str = strdup(yytext); return STRING; }

"+"                     { return PLUS;   }
"-"                     { return MINUS;  }
"*"                     { return TIMES;  }
"/"                     { return DIVIDE; }
"="                     { return ASSIGN; }
"("                     { return LPAREN; }
")"                     { return RPAREN; }
"{"                     { return LBRACE; }
"}"                     { return RBRACE; }
";"                     { return SEMI;   }
","                     { return COMMA;  }
"<"                     { return LT;     }
">"                     { return GT;     }
"."                     { return DOT;    }

.                       { }

%%

int yywrap(void) { return 1; }
