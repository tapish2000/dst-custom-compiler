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
  int yint;
  char ystr[100];
}
		  

%token <ystr> ADD SUB MUL DIV ASSIGN AND OR XOR LTE GTE LT GT EQ NEQ NOT
%token <ystr> FUNC_ID ID
%token <ystr> INT_CONST STR_CONST BOOL_CONST FLOAT_CONST
%token <yint> IF ELSE ELIF LOOP SHOW TAKE RET VOID START INT DOUBLE STR BOOL ARR BREAK CONT

%%
program:                          functions START '{' stmts_list '}';
functions:                        functions function 
                                  |  ;
function:                         function_name '{' stmts_list '}';
function_name:                    data_type FUNC_ID '(' params ')';
params:                           param_list 
                                  |  ;
param_list:                       param_list ',' param 
                                  | param;
stmts_list:                       stmts 
                                  |  ;
stmts:                            stmt stmts 
                                  | stmt ;
stmt:                             withSemcol ';'
                                  | withoutSemcol ;
withSemcol:                       param 
                                  | assign_stmt  
                                  | array_decl 
                                  | return_stmt 
                                  | func_call 
                                  | BREAK 
                                  | CONT ;
withoutSemcol:                    loop 
                                  | conditional;

assign_stmt:                      param assignment 
                                  | ID assignment;
loop:                             LOOP '(' conditions ')' '{' stmts_list '}';
conditional:                      IF '(' conditions ')' '{' stmts_list '}' remain_cond;
remain_cond:                      elif_stmts else_stmt
                                  | ;
elif_stmts:                       elif_stmts ELIF '(' conditions ')' '{' stmts_list '}'
                                  | ELIF '(' conditions ')' '{' stmts_list '}';
else_stmt:                        ELSE '{' stmts_list '}'
                                  | ;
conditions:                       boolean bi_logic_cond conditions
                                  | boolean
                                  | NOT conditions;
boolean:                          expr rel_op expr
                                  | expr;
return_stmt:                      RET expr;

array_decl:                       ARR '<' array_type ',' data '>' ID array_assign;
array_type:                       data_type 
                                  | array_decl;
func_call:                         FUNC_ID '(' args_list ')' ;
args_list:                        args 
                                  |  ;
args:                             args ',' expr 
                                  | expr ;
array_assign:                     ASSIGN '[' id_list ']' 
                                  |  ;
id_list:                          id_list ',' constant 
                                  | constant ;
param:                            data_type ID ;
assignment:                       ASSIGN expr ;

expr:                             expr op value | value;
value:                            func_call | constant | arr; 
arr:                              ARR '[' data ']' | ID; 
data:                             INT_CONST | ID; 
data_type:                        INT | BOOL | STR | DOUBLE;
op:                               ADD | SUB | MUL | DIV; 
rel_op:                           LTE | GTE | LT | GT | EQ | NEQ;
bi_logic_cond:                    AND | OR  | XOR;
constant:                         INT_CONST | STR_CONST | BOOL_CONST | FLOAT_CONST;

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