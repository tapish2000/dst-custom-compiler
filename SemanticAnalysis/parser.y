%{
#include "Definitions.h"
#include <sys/queue.h>

int yyerror(char*);
int yylex();

void default_value(int type);

struct Ast_node* astroot;
char name[20];
int type, size, no_elements, no_of_params, no_of_args, error_code = 0;
char tag;
struct Symbol *sym, *s1, *s2;
struct Symbol *currmethod;
union Value value;
struct Symbol *newsym;

int enableRetStuck = 1;

int whileTop=-1;
struct Symbol *while_stack[30];

int rtop = -1;
struct Symbol *rs[30];

int vtop = -1;
struct Symbol *vs[30];

struct Hash_Table Symbols_Table[SYM_TABLE_SIZE];
struct Hash_Table methods_table;

int curMethodID = 0;
struct Symbol *curMethod = NULL;
%}

%union {
  int yint;
  double ydou;
  //boolean ybool;
  char yid[100];
  char ystr[300];
  struct Ast_node* node;
}
		  

%token ADD SUB MUL DIV ASSIGN AND OR XOR LTE GTE EQ NEQ NOT
%token <yid> FUNC_ID ID
%token <yint> INT_CONST BOOL_CONST
%token <ydou> FLOAT_CONST
%token <ystr> STR_CONST 
%token IF ELSE ELIF LOOP SHOW TAKE RET VOID START INT DOUBLE STR BOOL ARR BREAK CONT NEWL HASH QUO SQUO BASL BASP

%type <node> program functions function function_name data_type params param_list param
%type <node> stmts_list stmt withSemcol withoutSemcol
%type <node> array_decl return_stmt func_call func_type
%type <node> loop conditional conditions remain_cond elif_stmts else_stmt boolean bi_logic_cond rel_op op
%type <node> expr array_assign array_type assign_stmt assignment args_list args id_list
%type <node> data constant arr value

%%
program:                          functions START '{' stmts_list '}'
                                  {
                                    printf("program - START\n");

                                    sym = makeSymbol("start",4,&value,0,'f',0,0);
                                    strcpy(sym->asm_name, "_source_start");
                                    add_method_to_table(sym);
                                    
                                    astroot = makeNode(astProgram, sym, $1, $4, NULL, NULL);
                                  }
                                  | /* EMPTY */
                                  {
                                    printf("Either Start function is not there or program is empty\n");
                                    astroot = makeNode(astEmptyProgram, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  ;

functions:                        functions function 
                                  {
                                    $$ = makeNode(astFunctions, NULL, $1, $2, NULL, NULL);
                                  }
                                  | /* EMPTY */
                                  {
                                    $$ = NULL;
                                  };

function:                         function_name '{' stmts_list '}' 
                                  {
                                    // push_ret(makeSymbol("func_start", 0, NULL, 0, 1, 'f', 0, 0));

                                    newsym = makeSymbol("", 0, &value, 0, 'f', 0, 0);
                                    
                                    $$ = makeNode(astFunction, NULL, $1, $3, NULL, NULL);
                                  };

function_name:                    data_type FUNC_ID '(' params ')' 
                                  {
                                    $$ = makeNode(astFunctionName, NULL, $1, $4, NULL, NULL);
                                    strcpy(name, "_");
                                    strcat(name, $2+1);

                                    for(int i=0; i<no_of_params; i++) {
                                      s1 = popV();
                                      s1->is_param = 1;
                                      switch(s1->type) {
                                        case 0:
                                        case 3:				
                                          if(s1->tag=='v') {
                                            strcat(name, "_int");						
                                          } else if(s1->tag=='a') {
                                            strcat(name, "_intArr");
                                          }						
                                        break;
                                        case 1:				
                                          if(s1->tag=='v') {
                                            strcat(name, "_doub");
                                          } else if(s1->tag=='a'){
                                            strcat(name, "_doubArr");
                                          }
                                        break;
                                        case 2:
                                          strcat(name, "_intArr");
                                          break;
                                      }
                                    }		
                                    s1 = popV();
                                    default_value(s1->type);
                                    sym = makeSymbol($2, s1->type, &value, s1->size, 'f', 0, no_of_params);
                                    add_method_to_table(sym);		
                                    strcpy(sym->asm_name, name);
                                  };

params:                           param_list 
                                  {
                                    $$ = $1;
                                  }
                                  | /* EMPTY */ 
                                  {
                                    $$ = NULL;
                                    no_of_params = 0;
                                  };

param_list:                       param_list ',' param 
                                  {
                                    $$ = makeNode(astParamList, NULL, $1, $3, NULL, NULL);
                                    no_of_params++;
                                  }
                                  | param
                                  {
                                    $$ = $1;
                                    no_of_params=1;
                                  };

stmts_list:                       stmt stmts_list 
                                  {
                                    printf("stmts_list - stmt\n");
                                    $$ = makeNode(astStmtsList, NULL, $1, $2, NULL, NULL);
                                  }
                                  | /* EMPTY */ 
                                  {
                                    $$ = NULL;
                                  };

stmt:                             withSemcol ';' 
                                  {
                                    printf("stmt - withSemcol\n");
                                    $$ = $1;
                                  }
                                  | withoutSemcol 
                                  {
                                    $$ = $1;
                                  };

withSemcol:                       param 
                                  {
                                    $$ = $1;
                                  }
                                  | assign_stmt
                                  {
                                    printf("withSemcol - assign_stmt\n");
                                    $$ = $1;
                                  }
                                  | array_decl 
                                  {
                                    $$ = $1;
                                  }
                                  | return_stmt 
                                  {
                                    $$ = $1;
                                  }
                                  | func_call 
                                  {
                                    $$ = $1;
                                  }
                                  | BREAK 
                                  {
                                    $$ = makeNode(astBreak, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | CONT 
                                  {
                                    $$ = makeNode(astContinue, NULL, NULL, NULL, NULL, NULL);
                                  };
                                  
withoutSemcol:                    loop 
                                  {
                                    $$ = $1;
                                  }
                                  | conditional
                                  {
                                    $$ = $1;
                                  };

assign_stmt:                      param assignment 
                                  {
                                    printf("assign_stmt\n");
                                    $$ = makeNode(astAssignStmt, NULL, $1, $2, NULL, NULL);
                                    popV();
                                    popV();
                                    // sym = find_variable(param->)
                                  }
                                  | arr assignment
                                  {
                                    $$ = makeNode(astArrayAssignStmt, NULL, $1, $2, NULL, NULL);
                                    s1 = popV();
                                    s2 = popV();
                                    if(s1->type == 4 || s2->type == 4) {
                                      printf("Error! No assignment for void types\n");
                                      error_code = 1;
                                    }
                                  };

loop:                             LOOP '(' conditions ')' '{' stmts_list '}'
                                  {
                                    $$ = makeNode(astLoop, NULL, $3, $6, NULL, NULL);
                                  };

conditional:                      IF '(' conditions ')' '{' stmts_list '}' remain_cond
                                  {
                                    $$ = makeNode(astConditional, NULL, $3, $6, $8, NULL);
                                  };

remain_cond:                      elif_stmts else_stmt 
                                  {
                                    $$ = makeNode(astRemaiCond, NULL, $1, $2, NULL, NULL);
                                  }
                                  | /* EMPTY */ 
                                  {
                                    $$ = NULL;
                                  };

elif_stmts:                       elif_stmts ELIF '(' conditions ')' '{' stmts_list '}' 
                                  {
                                    $$ = makeNode(astElifStmts, NULL, $1, $4, $7, NULL);
                                  }
                                  | ELIF '(' conditions ')' '{' stmts_list '}'
                                  {
                                    $$ = makeNode(astElifStmt, NULL, $3, $6, NULL, NULL);
                                  };

else_stmt:                        ELSE '{' stmts_list '}' 
                                  {
                                    $$ = makeNode(astElseStmt, NULL, $3, NULL, NULL, NULL);
                                  }
                                  | /* EMPTY */ 
                                  {
                                    $$ = NULL;
                                  };

conditions:                       boolean 
                                  {
                                    $$ = $1;
                                    s1 = popV();
                                    if(s1->type == 2 || s1->type == 4) {
                                      printf("Error! Type of %s not compatible for boolean operations\n", s1->name);
                                      error_code = 1;
                                    }
                                  }
                                  | boolean bi_logic_cond conditions 
                                  {
                                    $$ = makeNode(astConditions, NULL, $1, $2, $3, NULL);
                                    s1 = popV();
                                    s2 = popV();
                                    if(s1->type == 2 || s1->type == 4) {
                                      type = 4;
                                      size = 0;
                                      printf("Error! Type of %s not compatible for arithmetic operations\n", s1->name);
                                      error_code = 1;
                                    }
                                    else if(s2->type == 2 || s2->type == 4) {
                                      type = 4;
                                      size = 0;
                                      printf("Error! Type of %s not compatible for arithmetic operations\n", s2->name);
                                      error_code = 1;
                                    }
                                    else {
                                      type = 0;
                                      size = 4;
                                    }
                                    pushV(makeSymbol("", type, &value, size, 'c', 0, 0));
                                  }
                                  | NOT conditions 
                                  {
                                    $$ = makeNode(astNotConditions, NULL, $2, NULL, NULL, NULL);
                                    s1 = popV();
                                    if(s1->type == 2 || s1->type == 4) {
                                      printf("Error! Type of %s not compatible for boolean operations\n", s1->name);
                                      error_code = 1;
                                    }
                                  };

boolean:                          boolean  rel_op  expr 
                                  {
                                    $$ = makeNode(astBoolean, NULL, $1, $2, $3, NULL);
                                    s1 = popV();
                                    s2 = popV();
                                    if(s1->type == 2 || s1->type == 4) {
                                      type = 4;
                                      size = 0;
                                      printf("Error! Type of %s not compatible for arithmetic operations\n", s1->name);
                                      error_code = 1;
                                    }
                                    else if(s2->type == 2 || s2->type == 4) {
                                      type = 4;
                                      size = 0;
                                      printf("Error! Type of %s not compatible for arithmetic operations\n", s2->name);
                                      error_code = 1;
                                    }
                                    else {
                                      type = 0;
                                      size = 4;
                                    }
                                    pushV(makeSymbol("", type, &value, size, 'c', 0, 0));
                                  }
                                  | expr 
                                  {
                                    $$ = $1;
                                  };

return_stmt:                      RET expr 
                                  {

                                    /* Check if the type of currmethod and the return type (pop from stack) are same */

                                    $$ = makeNode(astReturnStmt, currmethod, $2, NULL, NULL, NULL);
                                    popV();
                                  };

array_decl:                       ARR '<' array_type ',' data '>' ID array_assign 
                                  {
                                    $$ = makeNode(astArrayDecl, NULL, $3, $5, $8, NULL);
                                    s1 = popV();
                                    default_value(s1->type);
                                    sym = makeSymbol($7, s1->type, &value, s1->size, 'a', 0, 0);
                                    add_variable_to_table(sym);
                                    pushV(sym);
                                  };

array_type:                       data_type 
                                  {
                                    $$ = $1;
                                  }
                                  | ARR '<' array_type ',' data '>'
                                  {
                                    $$ = makeNode(astArrayType, NULL, $3, $5, NULL, NULL);
                                  };

func_call:                        func_type '(' args_list ')' 
                                  {
                                    $$ = makeNode(astFuncCall, NULL, $1, $3, NULL, NULL);
                                    s1 = vs[vtop-no_of_args];
                                    if(strcmp(s1->func_name, "take")!=0 && strcmp(s1->func_name, "show")!=0 && s1!=NULL) {
                                      if(no_of_args != s1->no_of_params) {
                                        printf("The function %s expects %d parameters but got %d arguments\n",s1->func_name, s1->no_of_params, no_of_args);
                                        error_code = 1;
                                        type = 4;
                                        size = 0;
                                      }
                                      else {
                                        strcpy(name, "_");
                                        strcat(name, (s1->func_name)+1);
                                        for(int i=0; i<no_of_args; i++) {
                                          s2 = popV();
                                          switch(s2->type) {
                                          case 0:
                                          case 3:		
                                            if (s1->tag=='a') {
                                              strcat(name, "_intArr");
                                            } else {
                                              strcat(name, "_int");						
                                            } 	
                                          break;
                                          case 1:				
                                            if (s1->tag=='a') {
                                              strcat(name, "_doubArr");
                                            } else {
                                              strcat(name, "_doub");
                                            }
                                          break;
                                          case 2:
                                            strcat(name, "_intArr");
                                            break;
                                          }
                                        }
                                        s1 = popV();
                                        printf("%s %s\n",s1->asm_name, name);
                                        if(strcmp(s1->asm_name, name) != 0) {
                                          printf("The arguments of function %s are not matching with the function's parameter types\n", s1->name);
                                          error_code = 1;
                                          type = 4;
                                          size = 0;
                                        } else {
                                        type = s1->type;
                                        size = s1->size;
                                        } }
                                      sym = makeSymbol("", type, &value, size, s1->tag, 0, 0);
                                      pushV(sym);
                                    }
                                    else {
                                      for(int i=0; i<=no_of_args; i++)
                                        popV();
                                    }
                                  };

func_type:                        FUNC_ID 
                                  {
                                    $$ = makeNode(astCustomFunc, NULL, NULL, NULL, NULL, NULL);
                                    sym = NULL;
                                    sym = find_method($1);
                                    if(sym==NULL) {
                                      printf("Error! Function %s is not declared\n", $1);
                                      error_code = 1;
                                    }
                                    pushV(sym);
                                  }
                                  | SHOW 
                                  {
                                    $$ = makeNode(astFuncShow, NULL, NULL, NULL, NULL, NULL);
                                    default_value(0);
                                    sym = makeSymbol("show",4,&value,0,'f',0,0);
                                    pushV(sym);
                                  }
                                  | TAKE
                                  {
                                    $$ = makeNode(astFuncTake, NULL, NULL, NULL, NULL, NULL);
                                    default_value(0);
                                    sym = makeSymbol("take",4,&value,0,'f',0,0);
                                    pushV(sym);
                                  };

args_list:                        args 
                                  {
                                    $$ = $1;
                                  }
                                  | /* EMPTY */ 
                                  {
                                    $$ = NULL;
                                    no_of_args = 0;
                                  };

args:                             args ',' expr 
                                  {
                                    $$ = makeNode(astArgs, NULL, $1, $3, NULL, NULL);
                                    no_of_args = no_of_args + 1;
                                  }
                                  | expr 
                                  {
                                    $$ = $1;
                                    no_of_args = 1;
                                  };

array_assign:                     ASSIGN '[' id_list ']'
                                  {
                                    $$ = makeNode(astArrayAssign, NULL, $3, NULL, NULL, NULL);
                                  }
                                  | /* EMPTY */ 
                                  {
                                    $$ = NULL;
                                  };

id_list:                          id_list ',' constant 
                                  {
                                    $$ = makeNode(astIdList, NULL, $1, $3, NULL, NULL);
                                  }
                                  | constant 
                                  {
                                    $$ = $1;
                                  };

param:                            data_type ID 
                                  {
                                    printf("param\n");
                                    
                                    default_value(type);
                                    s1 = popV();
                                    sym = makeSymbol($2, s1->type, &value, s1->size, 'v', 1, 0);
                                    add_variable_to_table(sym);
                                    pushV(sym);
                                    $$ = makeNode(astParam, sym, $1, NULL, NULL, NULL);
                                  };

assignment:                       ASSIGN expr 
                                  {
                                    printf("assignment\n");
                                    $$ = makeNode(astAssignment, NULL, $2, NULL, NULL, NULL);
                                  };

expr:                             expr op value 
                                  {
                                    printf("expr1\n");
                                    $$ = makeNode(astExpr, NULL, $1, $2, $3, NULL);
                                    s1 = popV();
                                    s2 = popV();
                                    if(s1->type == 2|| s1->type == 4) {
                                      type = (s1->type == 2) ? 2 : 4;
                                      size = 0;
                                      printf("Error! Type of %s not compatible for arithmetic operations\n", s1->name);
                                      error_code = 1;
                                    }
                                    else if(s2->type == 2 || s2->type == 4) {
                                      type = (s2->type == 2) ? 2 : 4;
                                      size = 0;
                                      printf("Error! Type of %s not compatible for arithmetic operations\n", s2->name);
                                      error_code = 1;
                                    }
                                    else {
                                    switch (s1->type) {
                                      case 3:
                                      case 0:
                                        if (s2->type == 0){
                                          type = 0;
                                          size = 4;
                                        } else if (s2->type == 1){
                                          type = 1;
                                          size = 8;
                                        }
                                      break;
                                      case 1:
                                        type = 1;
                                        size = 8;
                                      break;
                                      } 
                                    }
                                    sym = makeSymbol("", type, &value, size, 'c', 0, 0);
                                    pushV(sym);
                                  }
                                  | value
                                  {
                                    printf("expr2\n");
                                    $$ = $1;
                                  };

value:                            func_call 
                                  {
                                    $$ = $1;
                                  }
                                  | constant 
                                  {
                                    printf("value - constant\n");
                                    $$ = $1;
                                  }
                                  | arr
                                  {
                                    $$ = $1;
                                  }; 

arr:                              arr '[' data ']' 
                                  {
                                    $$ = makeNode(astArr, NULL, $1, $3, NULL, NULL);
                                  }
                                  | ID 
                                  {
                                    $$ = makeNode(astId, NULL, NULL, NULL, NULL, NULL);
                                    sym = NULL;
                                    sym = find_variable($1); 
                                    if(sym==NULL) {
                                      printf("Error! Variable %s is not declared\n", $1);
                                      error_code = 1;
                                    }
                                    else {
                                      pushV(sym);
                                    }
                                  }; 

data:                             INT_CONST 
                                  {
                                    $$ = makeNode(astData, NULL, NULL, NULL, NULL, NULL);
                                    value.ivalue = $1;
                                    sym = makeSymbol("INT_CONST", 0, &value, 4, 'c', 1, 0);
                                  }
                                  | ID
                                  {
                                    $$ = makeNode(astId, NULL, NULL, NULL, NULL, NULL);
                                    $$ = makeNode(astId, NULL, NULL, NULL, NULL, NULL);
                                    sym = NULL;
                                    sym = find_variable($1); 
                                    if(sym==NULL) {
                                      printf("Error! Variable %s is not declared\n", $1);
                                      error_code = 1;
                                    }
                                  }; 

data_type:                        INT 
                                  {
                                    $$ = makeNode(astInt, NULL, NULL, NULL, NULL, NULL);
                                    sym = makeSymbol("", 0, &value, 4, 'c', 0, 0);
                                    pushV(sym);
                                  }
                                  | BOOL 
                                  {
                                    $$ = makeNode(astBool, NULL, NULL, NULL, NULL, NULL);
                                    sym = makeSymbol("bool", 3, &value, 1, 'c', 0, 0);
                                    pushV(sym);
                                  }
                                  | STR 
                                  {
                                    $$ = makeNode(astStr, NULL, NULL, NULL, NULL, NULL);
                                    sym = makeSymbol("str", 2, &value, 0, 'c', 0, 0);
                                    pushV(sym);
                                  }
                                  | DOUBLE 
                                  {
                                    $$ = makeNode(astDouble, NULL, NULL, NULL, NULL, NULL);
                                    sym = makeSymbol("dou", 1, &value, 8, 'c', 0, 0);
                                    pushV(sym);
                                  }
                                  | VOID
                                  {
                                    $$ = makeNode(astVoid, NULL, NULL, NULL, NULL, NULL);
                                    sym = makeSymbol("void", 4, &value, 0, 'c', 0, 0);
                                    pushV(sym);
                                  };


op:                               ADD 
                                  {
                                    $$ = makeNode(astAdd, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | SUB 
                                  {
                                    $$ = makeNode(astSub, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | MUL 
                                  {
                                    $$ = makeNode(astMul, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | DIV
                                  {
                                    $$ = makeNode(astDiv, NULL, NULL, NULL, NULL, NULL);
                                  }; 

rel_op:                           LTE 
                                  {
                                    $$ = makeNode(astLte, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | GTE 
                                  {
                                    $$ = makeNode(astGte, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | '<' 
                                  {
                                    $$ = makeNode(astLt, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | '>' 
                                  {
                                    $$ = makeNode(astGt, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | EQ 
                                  {
                                    $$ = makeNode(astEq, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | NEQ
                                  {
                                    $$ = makeNode(astNeq, NULL, NULL, NULL, NULL, NULL);
                                  };

bi_logic_cond:                    AND 
                                  {
                                    $$ = makeNode(astAnd, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | OR 
                                  {
                                    $$ = makeNode(astOr, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | XOR
                                  {
                                    $$ = makeNode(astXor, NULL, NULL, NULL, NULL, NULL);
                                  };

constant:                         INT_CONST 
                                  {
                                    value.ivalue = $1;
                                    sym = makeSymbol("intConst", 0, &value, 4, 'c', 1, 0);
                                    add_variable_to_table(sym);
                                    $$ = makeNode(astIntConst, sym, NULL, NULL, NULL, NULL);
                                    pushV(sym);
                                  }
                                  | SUB INT_CONST 
                                  {
                                    value.ivalue = -$2;
                                    sym = makeSymbol("intConst", 0, &value, 4, 'c', 1, 0);
                                    add_variable_to_table(sym);
                                    $$ = makeNode(astIntConst, sym, NULL, NULL, NULL, NULL);
                                    pushV(sym);
                                  }
                                  | STR_CONST 
                                  {
                                    strcpy(value.yvalue, $1);
                                    sym = makeSymbol("strConst", 2, &value, 0, 'c', 1, 0);
                                    add_variable_to_table(sym);
                                    $$ = makeNode(astStrConst, sym, NULL, NULL, NULL, NULL);
                                  }
                                  | BOOL_CONST 
                                  {
                                    value.ivalue = $1;
                                    sym = makeSymbol("intConst", 3, &value, 4, 'c', 1, 0);
                                    add_variable_to_table(sym);
                                    $$ = makeNode(astBoolConst, sym, NULL, NULL, NULL, NULL);
                                    pushV(sym);
                                  }
                                  | FLOAT_CONST
                                  {
                                    value.dvalue = $1;
                                    sym = makeSymbol("doubleConst", 1, &value, 8, 'c', 1, 0);
                                    add_variable_to_table(sym);
                                    $$ = makeNode(astFloatConst, sym, NULL, NULL, NULL, NULL);
                                    pushV(sym);       
                                  }
                                  | SUB FLOAT_CONST
                                  {
                                    value.dvalue = -$2;
                                    sym = makeSymbol("doubleConst", 1, &value, 8, 'c', 1, 0);
                                    add_variable_to_table(sym);
                                    $$ = makeNode(astFloatConst, sym, NULL, NULL, NULL, NULL);
                                    pushV(sym);
                                  };

%%

// int main(int argc, char *argv[])
// {
//   if (argc != 2) {
//       printf("\nUsage: <exefile> <inputfile>\n\n");
//       exit(0);
//   }
//   Initialize_Tables();
//   yyin = fopen(argv[1], "r");
//   yyparse();
//   traverse(astroot, -3);
//   Print_Tables();
//   return 0;
// }

int yyerror(char *s) {
  printf("\nError: %s\n",s);
  return 0;
}

void default_value(int type) {
  switch(type) {
    case 0:
      value.ivalue = 0;
      break;
    case 1:
      value.dvalue = 0;
      break;
    case 2:
      strcpy(value.yvalue, "");
      break;
    case 3:
      value.ivalue = 0;
  }
}

/* ------------------- Handling Hash Tables --------------- */

void Initialize_Tables(){
  for(int i=0;i<SYM_TABLE_SIZE;i++){
    methods_table.symbols[i] = NULL;
    for(int j=0;j<SYM_TABLE_SIZE;j++){
      Symbols_Table[i].symbols[j] = NULL;
    }
  }
}

void Print_Tables(){
  printf("------- Method Table ---------\n");
  printf("Function Name\tParams_count\tReturn Type\n");
  for(int i=0;i<SYM_TABLE_SIZE;i++){
    if(methods_table.symbols[i] != NULL) {
      struct Symbol* symb = methods_table.symbols[i];
      printf("%s\t\t%d\t\t",symb->func_name,symb->no_of_params);
      type = symb->type;
        switch(type) {
          case 0:
            printf("int\n");
            break;
          case 1:
            printf("double\n");
            break;
          case 2:
            printf("string\n");
            break;
          case 3:
            printf("boolean\n");
            break;
          case 4:
            printf("void\n");
        }
    }
  }
  printf("------- Symbol tables ---------\n");
  printf("Variable Name\t\tValue\t\tDatatype\n");
  for(int i=0;i<SYM_TABLE_SIZE;i++){
    for(int j=0;j<SYM_TABLE_SIZE;j++){
      if(Symbols_Table[i].symbols[j] != NULL) {
        struct Symbol* symb = Symbols_Table[i].symbols[j];
        while(symb != NULL) {
          printf("%s\t\t",symb->name);
          type = symb->type;
          switch(type) {
            case 0:
              printf("%d\t\tint\n",symb->value.ivalue);
              break;
            case 1:
              printf("%f\tdouble\n",symb->value.dvalue);
              break;
            case 2:
              printf("%s\t\tstring\n",symb->value.yvalue);
              break;
            case 3:
              printf("%d\t\tboolean\n",symb->value.ivalue);
          }
          symb = symb->next;
        }
      }
    }
  }
}

/* ------------------- Handling Hash Tables --------------- */

//Variable stack

void ShowVStack(){
	printf("\n--- VARIABLE STACK ---\n");
	for (int i=vtop; i>=0; i--){
		printf("%s %s %d %d\n", vs[i]->name, vs[i]->func_name, vs[i]->type, vtop);
	}
	printf("--- END ---\n");
}

void pushV(struct Symbol *p)
{
   vs[++vtop]=p;
   printf("\nPush\n");
   ShowVStack();
}

struct Symbol *popV()
{ 
   printf("\nPop\n");
   ShowVStack();
   return(vs[vtop--]);
}

//Return Stack

void ShowRStack(){
	printf("\n--- RETURN STACK ---\n");
	for (int i=rtop; i>=0; i--){
		printf("%s\n", rs[i]->name);
	}
	printf("--- END ---\n");
}

void pushR(struct Symbol *p)
{
	rs[++rtop]=p;
}

struct Symbol *popR()
{
	return(rs[rtop--]);
}


int check_has_return(){
	
	struct Symbol *first, *second;
	
	first = rs[0];
	second = rs[1];
	
	
	if (rtop > 0 && first && second && strcmp(first->name, "start") == 0 && strcmp(second->name, "return") == 0){
		popR();
		popR();
		return 1;
	} else {
		return 0;
	}
	
}

//While Stack

struct Symbol* top_while() {
  return while_stack[whileTop];
}

void push_while(struct Symbol* whileSym) {
  while_stack[++whileTop] = whileSym;
}

struct Symbol *pop_while() {
	if (whileTop<0) {
		return(NULL);
	}

	struct Symbol * temp;
	temp = while_stack[whileTop--];
	while_stack[whileTop+1] = NULL;   
	return(temp);
}

void Init_While_Stack() {
	int i;
	for(i = 0; i < 30; i++) {
		while_stack[i] = NULL;
	}
}

void Show_While_Stack() {
	printf("\n--- WHILE STACK ---\n");
	for (int i = whileTop; i >= 0; i--) {
		printf("%d\n", while_stack[i]->value);
	}
	printf("--- END ---\n");
}

//Syntax

struct Ast_node* makeNode(int type, struct Symbol *sn, struct Ast_node* first, struct Ast_node* second, struct Ast_node* third, struct Ast_node* fourth){
  struct Ast_node * ptr = (struct Ast_node *)malloc(sizeof(struct Ast_node));
  ptr->node_type = type;
  ptr->symbol_node = sn;
  ptr->child_node[0] = first;
  ptr->child_node[1] = second;
  ptr->child_node[2] = third;
  ptr->child_node[3] = fourth;
  return ptr;
}

struct Symbol * makeSymbol(char *name, int type, union Value* value, int size,char tag,int no_elements,int no_of_params){
  struct Symbol* ptr = (struct Symbol*)malloc(sizeof(struct Symbol));
  printf("1\n");
  ptr->tag = tag;
  if(tag == 'f'){
    strcpy(ptr->func_name, name);
  } else{
    strcpy(ptr->name, name);
  }
  printf("2\n");
  switch(type) {
    case 0:
      printf("ooper\n");
      ptr->value.ivalue = value->ivalue;
      printf("neeche\n");
      break;
    case 1:
      ptr->value.dvalue = value->dvalue;
      break;
    case 2:
      strcpy(ptr->value.yvalue, value->yvalue);
      break;
    case 3:
      ptr->value.ivalue = value->ivalue;
      break;
    default:
      printf("Incompatible Data Type!\n");
      break;
  }
  printf("3\n");
  strcpy(ptr->asm_name, "");
  ptr->asmclass = '\0';
  ptr->type = type;
  //ptr->scope = scope;
  ptr->size = size;
  ptr->no_elements = no_elements;
  ptr->no_of_params = no_of_params;
  ptr->symbol_table = NULL;
  ptr->next = NULL;
  ptr->prev = NULL;
  printf("4\n");
  return ptr;
}

void add_variable_to_table(struct Symbol *symbp)
{  
  struct Symbol *exists, *newsy;

  newsy=symbp;
  if(symbp->tag == 'c'){
    add_variable(newsy);
  }
  else{
	exists=find_variable(newsy->name);
	if( !exists )
	{
		add_variable(newsy);
  }else
  {
    printf("%s redeclaration.\n",newsy->name);
    exit(1);
  }
  }
}

void add_method_to_table(struct Symbol *symbp)
{  
  struct Symbol *exists, *newme;

  newme=symbp;
   
	exists=find_method(newme->func_name);
	if( !exists )
	{
		add_method(newme);
  }
  else
  {
      printf("%s redeclaration.\n",newme->func_name);
      exit(1);
  }
  currmethod = symbp;
}


int genKey(char *s)
{  
  char *p;
  int athr=0;

  for(p=s; *p; p++) athr=athr+(*p);
  return (athr % SYM_TABLE_SIZE);
}


void add_variable(struct Symbol *symbp)
{  
  int i;
  struct Symbol *ptr;

//  struct HashTable cur_table = Symbols_Table[curMethodID];
  
  i=genKey(symbp->name);
  
  ptr=Symbols_Table[curMethodID].symbols[i];
  symbp->next=ptr;
  symbp->prev=NULL;
  
  if(ptr) ptr->prev=symbp;
  Symbols_Table[curMethodID].symbols[i]=symbp;
  Symbols_Table[curMethodID].numbSymbols++;
}

struct Symbol *find_variable(char *s)
{  
  int i;
  struct Symbol *ptr;
  
  struct Hash_Table cur_table = Symbols_Table[curMethodID];

  i = genKey(s);
  ptr = cur_table.symbols[i];
  
  
  while(ptr && (strcmp(ptr->name,s) !=0))
    ptr=ptr->next;
  return ptr;
}

void add_method(struct Symbol *symbp)
{  
  int i;
  struct Symbol *ptr;

  i = genKey(symbp->func_name);
  ptr = methods_table.symbols[i];
  symbp->next = ptr;
  symbp->prev = NULL;
  symbp->symbol_table = &Symbols_Table[curMethodID];
  if(ptr) ptr->prev = symbp;
  methods_table.symbols[i] = symbp;
  methods_table.numbSymbols++;
  
  curMethod = symbp;
  
}

struct Symbol *find_method(char *s)
{  
  int i;
  struct Symbol *ptr;

  i = genKey(s);
  ptr = methods_table.symbols[i];
  
  while(ptr && (strcmp(ptr->func_name,s) !=0))
    ptr = ptr->next;
  return ptr;
}

// void spacing(int n)
// {  
// 	int i;   
// 	for(i=0; i<n; i++) printf(" ");
// }

// void traverse(struct Ast_node *p, int n)
// {  
// 	int i;

//     n=n+3;
//     if(p)
//     {
// 		switch (p->node_type)
// 		{
// 			case astProgram: 
// 				spacing(n); printf("astProgram\n"); 
// 				break;
// 			case astFunctions: 
// 				spacing(n); printf("astFunctions\n"); 
// 				break;
// 			case astFunction: 
// 				spacing(n); printf("astFunction\n"); 
// 				break;
// 			case astFunctionName: 
// 				spacing(n); printf("astFunctionName\n"); 
// 				break;
// 			case astParamList: 
// 				spacing(n); printf("astParamList\n"); 
// 				break;
// 			case astStmtsList: 
// 				spacing(n); printf("astStmtsList\n"); 
// 				break;
// 			case astBreak: 
// 				spacing(n); printf("astBreak\n"); 
// 				break;
// 			case astContinue: 
// 				spacing(n); printf("astContinue\n"); 
// 				break;
// 			case astAssignStmt: 
// 				spacing(n); printf("astAssignStmt\n"); 
// 				break;
// 			case astLoop: 
// 				spacing(n); printf("astLoop\n"); 
// 				break;  
// 			case astConditional: 
// 				spacing(n); printf("astConditional\n"); 
// 				break;   
// 			case astRemaiCond: 
// 				spacing(n); printf("astRemaiCond\n"); 
// 				break;
// 			case astElifStmts: 
// 				spacing(n); printf("astElifStmts\n"); 
// 				break;
// 			case astElseStmt: 
// 				spacing(n); printf("astElseStmt\n"); 
// 				break;
// 			case astConditions: 
// 				spacing(n); printf("astConditions\n"); 
// 				break;
// 			case astBoolean:
// 				spacing(n); printf("astBoolean\n"); 
// 				break;
// 			case astReturnStmt: 
// 				spacing(n); printf("astReturnStmt\n"); 
// 				break;
// 			case astArrayDecl: 
// 				spacing(n); printf("astArrayDecl\n"); 
// 				break;
// 			case astFuncCall: 
// 				spacing(n); printf("astFuncCall\n"); 
// 				break;
// 			case astCustomFunc: 
// 				spacing(n); printf("astCustomFunc\n"); 
// 				break;
// 			case astFuncShow: 
// 				spacing(n); printf("astFuncShow\n"); 
// 				break;
// 			case astFuncTake: 
// 				spacing(n); printf("astFuncTake\n"); 
// 				break;
// 			case astArgs:
// 				spacing(n); printf("astArgs\n"); 
// 				break;
// 			case astArrayAssign: 
// 				spacing(n); printf("astArrayAssign\n"); 
// 				break;
// 			case astIdList: 
// 				spacing(n); printf("astIdList\n"); 
// 				break;
// 			case astParam: 
// 				spacing(n); printf("astParam\n"); 
// 				break;
// 			case astAssignment: 
// 				spacing(n); printf("astAssignment\n"); 
// 				break;
// 			case astExpr: 
// 				spacing(n); printf("astExpr\n"); 
// 				break;
// 			case astArr: 
// 				spacing(n); printf("astArr\n"); 
// 				break;
// 			case astData: 
// 				spacing(n); printf("astData\n"); 
// 				break;
// 			case astInt: 
// 				spacing(n); printf("astInt\n"); 
// 				break;
// 			case astBool: 
// 				spacing(n); printf("astBool\n"); 
// 				break;
// 			case astStr: 
// 				spacing(n); printf("astStr\n"); 
// 				break;
// 			case astDouble: 
// 				spacing(n); printf("astDouble\n"); 
// 				break;
// 			case astVoid: 
// 				spacing(n); printf("astVoid\n"); 
// 				break;
// 			case astAdd: 
// 				spacing(n); printf("astAdd\n"); 
// 				break;
// 			case astSub: 
// 				spacing(n); printf("astSub\n"); 
// 				break;
// 			case astMul: 
// 				spacing(n); printf("astMul\n"); 
// 				break;
// 			case astDiv: 
// 				spacing(n); printf("astDiv\n"); 
// 				break;
// 			case astLte:
// 				spacing(n); printf("astLte\n"); 
// 				break;
// 			case astGte:
// 				spacing(n); printf("astGte\n"); 
// 				break;
// 			case astLt:
// 				spacing(n); printf("astLt\n"); 
// 				break;
// 			case astGt: 
// 				spacing(n); printf("astGt\n"); 
// 				break;
// 			case astEq: 
// 				spacing(n); printf("astEq\n"); 
// 				break;
// 			case astNeq: 
// 				spacing(n); printf("astNeq\n"); 
// 				break;
// 			case astAnd: 
// 				spacing(n); printf("astAnd\n");
// 				break;
// 			case astOr: 
// 				spacing(n); printf("astOr\n"); 
// 				break;
// 			case astXor: 
// 				spacing(n); printf("astXor\n"); 
// 				break;
// 			case astIntConst: 
// 				spacing(n); printf("astIntConst\n"); 
// 				break;
// 			case astStrConst: 
// 				spacing(n); printf("astStrConst\n"); 
// 				break;
// 			case astBoolConst: 
// 				spacing(n); printf("astBoolConst\n"); 
// 				break;
// 			case astFloatConst: 
// 				spacing(n); printf("astFloatConst\n"); 
// 				break;
//       case astId:
//         spacing(n); printf("astId\n"); 
// 				break;
// 			default: 
// 				printf("AGNOSTO=%d\n",p->node_type);
// 		}
// 		for(i=0; i<4; i++) traverse(p->child_node[i],n);
// 	}
// }