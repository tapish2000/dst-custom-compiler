%{
    #include <stdio.h>
    #include <string.h>
    #include "y.tab.h"
    
	int is_keyword(char* s);
%}

comment  ("#")([^#]|("\\#"))*([^\\])("#")
keywords (if|else|elif|loopif|show|take|return|void|start|integer|double|string|boolean|array|break|continue)

%%

{keywords}                              {printf("Reserved_words: %s\n",yytext); return is_keyword(yytext);}
[0-9][0-9]*					            {printf("Integer: %s\n",yytext); return INT_CONST;}	
[0-9]+"."[0-9]+				            {printf("Double: %s\n",yytext); return FLOAT_CONST;}
"true"                                  {printf("Boolean: %s\n",yytext); return BOOL_CONST;}
"false"									{printf("Boolean: %s\n",yytext); return BOOL_CONST;}
"\"".*"\""                              {printf("String: %s",yytext); return STR_CONST;}
"."[a-zA-Z][a-zA-Z0-9]*                 {printf("Function Identifier: %s\n",yytext); return FUNC_ID;}


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
				 return ADD;
				 }  
                     
"-"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return SUB;
				 }

"*"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return MUL;
				 }

"/"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return DIV;
				 }

"is"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return ASSIGN;
				 }

"and" 				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return AND;
				 }        

"or"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return OR;
				 }

"xor"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return XOR;
				 }

"not"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return NOT;
				 }

"<="				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return LTE;
				 }

">="				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return GTE;
				 }
				 
"<"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return LT;
				 }

">"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return GT;
				 }

"equals"			{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return EQ;
				 }

"!="				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return NEQ;
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

[a-zA-Z][a-zA-Z0-9]*           {printf("Variable Identifier: %s\n", yytext); return ID;}

"\\\""				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return QUO;
				 }
				 
"\\'"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return QUO;
				 }
				 
"\\#"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return HASH;
				 }


"\\\\"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return BASL;
				 }
				 
"\\b"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return BASP;
				 }	
				 

"\\n"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return NEWL;
				 }
				 
"\\t"				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return TAB;
				 }	
				 
"\\r"   			{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return WS;
				 }	

{comment}                      {printf("%s\n", yytext);};

(.|[\n])			;


%%

// Reserved keywords list
char* reserved[16] = {"if","else","elif","loopif","show","take","return","void","start","integer","double","string","boolean","array","break","continue"};
int res_id[16] = {IF, ELSE, ELIF, LOOP, SHOW, TAKE, RET, VOID, START, INT, DOUBLE, STR, BOOL, ARR, BREAK, CONT};


// These will later be commented out
/*
int main(int argc, char* argv[]) {
	FILE* file = fopen(argv[1],"r");
	if(file==NULL) {
		printf("Error! File not present\n");
		exit(0); }
	yyset_in(file);
    	yylex();
    	return 0;
}
*/
int yywrap(){}

int is_keyword(char* s){
	int i;
	for(i=0;i<16 && strcmp(s,reserved[i])!=0;i++);
	if(i<16){
		return res_id[i];
	}
	return -1;
}