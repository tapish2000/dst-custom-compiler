%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
extern FILE * yyin;

int yyerror();
int yylex();

%}

%union {
	 char str[10];
}
		  

%token ADD SUB 
%type <str> ADD
%type <str> SUB
%%

pr: ADD			{};

%%

int main(int argc, char *argv[])
{
  
  return 0;
}

int yyerror() {
  printf("\n\nError\n");
  return 0;
}


