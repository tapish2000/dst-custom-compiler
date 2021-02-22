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

array_decl:                       array '<' array_type ',' data '>' ID array_assign;
array_type:                       data_type 
                                  | array_decl;
func_cal:                         func_identifier '(' args_list ')' ;
args_list:                        args 
                                  |  ;
args:                             args ',' expr 
                                  | expr ;
array_assign:                     is '[' id_list ']' 
                                  |  ;
id_list:                          id_list ',' constant 
                                  | constant ;
param:                            data_type ID ;
assignment:                       is expr ;

%%

int main(int argc, char *argv[])
{
  
  return 0;
}

int yyerror() {
  printf("\n\nError\n");
  return 0;
}


