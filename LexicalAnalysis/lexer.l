%{
    #include <stdio.h>
%}

keywords (if|else|elif|loopif|show|take|return|void|start|integer|double|string|boolean|array)

%%

{keywords}                              {printf("Keyword: %s\n",yytext);}
[0-9][0-9]*					            {printf("Integer: %s\n",yytext);}	
[0-9]+"."[0-9]+				            {printf("Double: %s\n",yytext);}
"."[a-zA-Z][a-zA-Z0-9]*                 {printf("Function Identifier: %s\n",yytext);}
[a-zA-Z][a-zA-Z0-9]*                    {printf("Variable Identifier: %s\n", yytext);}

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
