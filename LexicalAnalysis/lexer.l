%{
    #include <stdio.h>
    #include <string.h>
    //#include <y.tab.h>
    
    
%}

comment  ("#")([^#]|("\\#"))*([^\\])("#")
BS       ("\\")
keywords (if|else|elif|loopif|show|take|return|void|start|integer|double|string|boolean|array)

%%

{keywords}                              {printf("Keyword: %s\n",yytext);}
[0-9][0-9]*			         {printf("Integer: %s\n",yytext);}	
[0-9]+"."[0-9]+			 {printf("Double: %s\n",yytext);}
"."[a-zA-Z][a-zA-Z0-9]*                 {printf("Function Identifier: %s\n",yytext);}


"++"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return INC;
				 }

"--"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return DEC;
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

"("				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return FUNBEG;
				 }

")"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return FUNEND;
				 }

"["				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return ARRBEG;
				 }

"]"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return ARREND;
				 }

","				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return SEP;
				 }

[a-zA-Z][a-zA-Z0-9]*           {printf("Variable Identifier: %s\n", yytext);}

{BS}"\""			{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return QUO;
				 }
				 
{BS}"'"			{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return QUO;
				 }
				 
{BS}"#"			{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return HASH;
				 }


"\\\\"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return BASL;
				 }
				 
{BS}"b"			{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return BASP;
				 }	
				 

{BS}"n"			{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return NEWL;
				 }
				 
{BS}"t"			{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return TAB;
				 }	
				 
{BS}"r"			{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return WS;
				 }
				 			

{comment}                      {printf("%s\n", yytext);};

(.|[\n])			;


%%

/*
Reserved keywords list
char* reserved[] = {}

*/

// These will later be commented out
int yywrap(){}

int main(int argc, char* argv[]) {
	FILE* file = fopen(argv[1],"r");
	if(file==NULL) {
		printf("Error! File not present");
		exit(0); }
	yyset_in(file);
    	yylex();
    	return 0;
}
