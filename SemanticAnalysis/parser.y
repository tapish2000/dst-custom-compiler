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
		  

%token ADD SUB MUL DIV ASSIGN AND OR XOR LTE GTE LT GT EQ NEQ NOT

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

expr:                             expr op value | value;
value:                            func_call | constant | arr; 
arr:                              arr [ data ] | ID; 
data:                             integer_number | ID; 
data_type:                        integer | bool | string | double;
op:                               ADD | SUB | MUL | DIV; 
rel_op:                           LTE | GTE | LT | GT | EQ | NEQ;
bi_logic_cond:                    AND | OR  | XOR;
constant:                         integer_number | string_constant | bool_constant | floating_number;

%%

int main(int argc, char *argv[])
{
  
  return 0;
}

int yyerror() {
  printf("\n\nError\n");
  return 0;
}


