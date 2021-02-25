%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
extern FILE * yyin;

int yyerror();
int yylex();

%}

%union {
	char str[50];
  int yint;
}
		  

%token ADD SUB MUL DIV IS AND OR XOR LTE GTE LT GT EQ NEQ NOT ID FUNC_ID
%token IF ELSE ELIF LOOP SHOW TAKE RET VOID START INT DOUBLE STR BOOL ARR BREAK CONT

%type <str> ID
%type <str> FUNC_ID

%%
program:                          functions START '{' stmts_list '}';
functions:                        functions function |  ;
function:                         function_name '{' stmts_list '}';
function_name:                    data_type FUNC_ID '(' params ')';
params:                           param_list |  ;
param_list:                       param_list ',' param | param;
stmts_list:                       stmts |  ;
stmts:                            stmt ';' stmts | stmt ;
stmt:                             param | assign_stmt | loop | conditional |  array_decl |  return_stmt | func_call | BREAK | CONT ;


assign_stmt:                      param assignment 
                                  | ID assignment;
loop:                             LOOP '(' conditions ')' '{' stmts_list '}';
conditional:                       IF '(' conditions ')' '{' stmts_list '}' remain_cond;
remain_cond:                      elif_stmts else_stmt
                                  | ;
elif_stmts:                       elif_stmts ELIF '(' conditions ')' '{' stmts_list '}'
                                  | ELIF '(' conditions ')' '{' stmts_list '}';
else_stmt:                        ELSE '{' stmts_list '}'
                                  | ;
conditions:                       conditions bi_logic_cond boolean 
                                  | boolean
                                  | NOT conditions;
boolean:                          expr rel_op expr
                                  | expr;
return_stmt:                      RET expr;

array_decl:                       ARR LT array_type ',' data GT ID array_assign;
array_type:                       data_type 
                                  | array_decl;
func_call:                         FUNC_ID '(' args_list ')' ;
args_list:                        args 
                                  |  ;
args:                             args ',' expr 
                                  | expr ;
array_assign:                     IS '[' id_list ']' 
                                  |  ;
id_list:                          id_list ',' constant 
                                  | constant ;
param:                            data_type ID ;
assignment:                       IS expr ;

expr:                             expr op value | value;
value:                            func_call | constant | arr; 
arr:                              arr '[' data ']' | ID; 
data:                             integer_number | ID; 
data_type:                        INT | BOOL | STR | DOUBLE;
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