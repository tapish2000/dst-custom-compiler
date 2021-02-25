%{
    #include <stdio.h>
    #include <string.h>
    #include <y.tab.h>
    
%}

comment  ("#")([^#]|("\\#"))*([^\\])("#")
keywords (if|else|elif|loopif|show|take|return|void|start|integer|double|string|boolean|array|break|continue)

%%

{keywords}                              {printf("Keyword: %s\n",yytext); return keyword(yytext);}
[0-9][0-9]*					            {printf("Integer: %s\n",yytext);}	
[0-9]+"."[0-9]+				            {printf("Double: %s\n",yytext);}
"true"                                  {printf("Boolean: %s\n",yytext);}
"false"									{printf("Boolean: %s\n",yytext);}
"\"".*"\""                              {printf("String: %s",yytext);}
"."[a-zA-Z][a-zA-Z0-9]*                 {printf("Function Identifier: %s\n",yytext);}


"++"			{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return INC;
				 }

"--"			{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return DEC;
				 }

"+"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return ADD;
				 }  
                     
"-"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return SUB;
				 }

"*"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return MUL;
				 }

"/"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return DIV;
				 }

"is"			{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return IS;
				 }

"and" 			{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return AND;
				 }        

"or"			{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return OR;
				 }

"xor"			{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return XOR;
				 }

"not"			{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return NOT;
				 }

"<="			{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return LTE;
				 }

">="			{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return GTE;
				 }
				 
"<"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return LT;
				 }

">"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return GT;
				 }

"equals"		{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return EQ;
				 }

"!="			{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return NEQ;
				 }

";"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return ';';
				 }

"{"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return '{';
				 }

"}"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return '}';
				 }

"("				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				return '(';
				 }

")"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return ')';
				 }

"["				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return '[';
				 }

"]"				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return ']';
				 }

","				{//printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 return ',';
				 }

[a-zA-Z][a-zA-Z0-9]*           {printf("Variable Identifier: %s\n", yytext);}

"\\\""				{printf("%s\n",yytext);
				 //strcpy(yylval.str, yytext);
				 //return DQUO;
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
int yywrap(){}

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
int keyword(char* s){
	int i;
	for(i=0;i<16 && strcmp(s,reserved[i])!=0;i++);
	if(i<16){
		return res_id[i];
	}
	return -1;
}
