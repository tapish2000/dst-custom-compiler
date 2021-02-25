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
program:                          functions start '{' stmts_list '}';
functions:                        functions function |  ;
function:                         function_name '{' stmts_list '}';
function_name:                    data_type func_identifier '(' params ')';
params:                           param_list |  ;
param_list:                       param_list ',' param | param;
stmts_list:                       stmts |  ;
stmts:                            stmt ';' stmts | stmt ;
stmt:                             param | assign_stmt | loop | conditional |  array_decl |  return_stmt | func_call | break | continue ;


assign_stmt:                      param assignment 
                                  | ID assignment;
loop:                             'loopif' '(' conditions ')' '{' stmts_list '}';
conditonal:                       'if' '(' conditions ')' '{' stmts_list '}' remain_cond;
remain_cond:                      elif_stmts else_stmt
                                  | ;
elif_stmts:                       elif_stmts 'elif' '(' conditions ')' '{' stmts_list '}'
                                  | 'elif' '(' conditions ')' '{' stmts_list '}';
else_stmt:                        'else' '{' stmts_list '}'
                                  | ;
conditions:                       conditions bi_logic_cond boolean 
                                  | boolean
                                  | 'not' conditions;
boolean:                          expr rel_op expr
                                  | expr;
return_stmt:                      'return' expr;

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
arr:                              arr '[' data ']' | ID; 
data:                             integer_number | ID; 
data_type:                        integer | bool | string | double;
op:                               ADD | SUB | MUL | DIV; 
rel_op:                           LTE | GTE | LT | GT | EQ | NEQ;
bi_logic_cond:                    AND | OR  | XOR;
constant:                         integer_number | string_constant | bool_constant | floating_number;

%%

int main(int argc, char *argv[])
{
  if (argc != 2) {
      printf("\nUsage: <exefile> <inputfile>\n\n");
      exit(0);
  }
  yyin = fopen(argv[1], "r");
  yyparse();
  return 0;
}

int yyerror() {
  printf("\n\nError\n");
  return 0;
}