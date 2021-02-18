%{
    #include <stdio.h>
    #include <string.h>
    
    
%}


keywords (if|else|elif|loopif|show|take|return|void|start|integer|double|string|boolean|array)

%%

{keywords}                              {printf("Keyword: %s\n",yytext);}
[0-9][0-9]*					            {printf("Integer: %s\n",yytext);
                                        //strcpy(yylval.ystr,yytext);
                                        //return(INT_CONST);
                                        }	
[0-9]+"."[0-9]+				            {printf("Double: %s\n",yytext);
                                        //strcpy(yylval.ystr,yytext);
                                        //return(DOUBLE_CONST);
                                        }
"."[a-zA-Z][a-zA-Z0-9]*                 {printf("Function Identifier: %s\n",yytext);
                                        //strcpy(yylval.ystr,yytext);
                                        //return(FUNC_CONST);
                                        }


"+"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return ADD;
				 }  
                     
"-"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return SUB;
				 }

"*"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return MUL;
				 }

"/"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return DIV;
				 }

"is"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return ASSIGN;
				 }

"and" 				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return AND;
				 }        

"or"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return OR;
				 }

"xor"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return XOR;
				 }

"not"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return NOT;
				 }

"<="				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return LTE;
				 }

">="				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return GTE;
				 }
				 
"<"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return LT;
				 }

">"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return GT;
				 }

"equals"			{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return EQ;
				 }

"!="				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return NEQ;
				 }

";"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return TER;
				 }

"{"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return BEGIN;
				 }

"}"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return END;
				 }

","				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return SEP;
				 }
				 

[a-zA-Z][a-zA-Z0-9]*                    {printf("Variable Identifier: %s\n", yytext);
                                        //strcpy(yylval.ystr,yytext);
                                        //return(ID);
                                        }

[ \n\r\t]+                              {printf("Escaped new line or white space or tabs\n");}

.                                       {printf("Unknown character: %s\n",yytext);}

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
