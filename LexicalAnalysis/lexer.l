%{
    #include <stdio.h>
    #include "y.tab.h"

%}

%%

"."[a-zA-Z][a-zA-Z0-9]*                 {printf("Function Identifier: %s\n",yytext);}
[0-9][0-9]*					            {printf("Integer: %s\n",yytext);}	
[0-9]+"."[0-9]+				            {printf("Float: %s\n",yytext);}

%%

/*
Reserved keywords list
char* reserved[] = {}

*/

// These will later be commented out
int yywrap(){}

int main(){
    yylex();
    return 0;
}
