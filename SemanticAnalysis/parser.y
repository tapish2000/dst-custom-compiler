%{
#include "Definitions.h"
#include <sys/queue.h>
extern FILE * yyin;

int yyerror(char*);
int yylex();

void default_value(int type);

struct Ast_node* astroot;
char name[20];
int type, size, no_elements, no_of_params, error_code = 0;
char tag;
struct Symbol *sym, *s1;
struct Symbol *currmethod;
union Value value;

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
%type <node> loop conditional conditions remain_cond elif_stmts else_stmt boolean not_cond or_cond and_cond xor_cond rel_op
%type <node> expr array_assign array_type assign_stmt assignment args_list args id_list add_expr multi_expr add_op multi_op
%type <node> data constant arr value

%%
program:                          functions START '{' stmts_list '}'
                                  {
                                    default_value(type);
                                    sym = makeSymbol("main",4,&value,0,'f',0,0);
                                    strcpy(sym->mix_name, "_source_main");
                                    add_variable_to_table(sym);
                                    astroot = makeNode(astProgram, NULL, $1, $4, NULL, NULL);
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
                                    $$ = makeNode(astFunction, NULL, $1, $3, NULL, NULL);

                                  };

function_name:                    data_type FUNC_ID '(' params ')' 
                                  {
                                    $$ = makeNode(astFunctionName, NULL, $1, $4, NULL, NULL);
                                    strcpy(name, "_");
                                    strcat(name, $2+1);

                                    for(int i=0; i<no_of_params; i++) {
                                      s1 = popV();
                                      printf("%s\n", s1->name);
                                      s1->is_param = 1;
                                      switch(s1->type) {
                                        case 0:
                                        case 3:				
                                          if (s1->tag=='v') {
                                            strcat(name, "_int");						
                                          } else {
                                            strcat(name, "_intArr");
                                          }						
                                        break;
                                        case 1:				
                                          if (s1->tag=='v') {
                                            strcat(name, "_doub");
                                          } else {
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
                                    strcpy(sym->mix_name, name);
                                    pushV(sym);
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
                                    $$ = makeNode(astStmtsList, NULL, $1, $2, NULL, NULL);
                                  }
                                  | /* EMPTY */ 
                                  {
                                    $$ = NULL;
                                  };

stmt:                             withSemcol ';' 
                                  {
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
                                    $$ = makeNode(astAssignStmt, NULL, $1, $2, NULL, NULL);
                                    // sym = find_variable(param->)
                                  }
                                  | arr assignment
                                  {
                                    $$ = makeNode(astAssignStmt, NULL, $1, $2, NULL, NULL);
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
                                    $$ = makeNode(astElifStmts, NULL, $3, $6, NULL, NULL);
                                  };

else_stmt:                        ELSE '{' stmts_list '}' 
                                  {
                                    $$ = makeNode(astElseStmt, NULL, $3, NULL, NULL, NULL);
                                  }
                                  | /* EMPTY */ 
                                  {
                                    $$ = NULL;
                                  };

conditions:                       not_cond 
                                  {
                                    $$ = $1;
                                  };
                                 
not_cond:                         NOT or_cond
                                  {
                                    $$ = makeNode(astNot, NULL, $2, NULL, NULL, NULL);
                                  }
                                  |
                                  or_cond
                                  {
                                    $$ = $1;
                                  };

or_cond:                          or_cond OR and_cond
                                  {
                                    $$ = makeNode(astOr, NULL, $1, $3, NULL, NULL);
                                  }
                                  | and_cond
                                  {
                                    $$ = $1;
                                  };

and_cond:                         and_cond AND xor_cond
                                  {
                                    $$ = makeNode(astAnd, NULL, $1, $3, NULL, NULL);
                                  }
                                  | xor_cond
                                  {
                                    $$ = $1;
                                  };

xor_cond:                          xor_cond XOR boolean
                                  {
                                    $$ = makeNode(astXor, NULL, $1, $3, NULL, NULL);
                                  }
                                  | boolean
                                  {
                                    $$ = $1;
                                  };

boolean:                          boolean  rel_op  expr 
                                  {
                                    $$ = makeNode(astBoolean, NULL, $1, $2, $3, NULL);
                                  }
                                  | expr 
                                  {
                                    $$ = $1;
                                  };

return_stmt:                      RET expr 
                                  {

                                    /* Check if the type of currmethod and the return type (pop from stack) are same */

                                    $$ = makeNode(astReturnStmt, currmethod, $2, NULL, NULL, NULL);
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
                                  }
                                  | SHOW 
                                  {
                                    $$ = makeNode(astFuncShow, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | TAKE
                                  {
                                    $$ = makeNode(astFuncTake, NULL, NULL, NULL, NULL, NULL);
                                  };

args_list:                        args 
                                  {
                                    $$ = $1;
                                  }
                                  | /* EMPTY */ 
                                  {
                                    $$ = NULL;
                                  };

args:                             args ',' expr 
                                  {
                                    $$ = makeNode(astArgs, NULL, $1, $3, NULL, NULL);
                                  }
                                  | expr 
                                  {
                                    $$ = $1;
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
                                    $$ = makeNode(astParam, NULL, $1, NULL, NULL, NULL);
                                    default_value(type);
                                    s1 = popV();
                                    sym = makeSymbol($2, s1->type, &value, s1->size, 'v', 1, 0);
                                    add_variable_to_table(sym);
                                    pushV(sym);
                                  };

assignment:                       ASSIGN expr 
                                  {
                                    $$ = makeNode(astAssignment, NULL, $2, NULL, NULL, NULL);
                                  };

expr:                             add_expr
                                  {
                                    $$ = $1;
                                  };

add_expr:                         add_expr add_op multi_expr
                                  {
                                    $$ = makeNode(astAddExpr, NULL, $1, $2, $3, NULL);
                                  }
                                  | multi_expr
                                  {
                                    $$ = $1;
                                  };

multi_expr:                       multi_expr multi_op value
                                  {
                                    $$ = makeNode(astMultiExpr, NULL, $1, $2, $3, NULL);
                                  }
                                  | value 
                                  {
                                    $$ = $1;
                                  } 
                                  | '(' expr ')'
                                  {
                                    $$ = $2;
                                  };

add_op:                           ADD 
                                  {
                                    $$ = makeNode(astAdd, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | SUB 
                                  {
                                    $$ = makeNode(astSub, NULL, NULL, NULL, NULL, NULL);
                                  };

multi_op:                         MUL 
                                  {
                                    $$ = makeNode(astMul, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | DIV
                                  {
                                    $$ = makeNode(astDiv, NULL, NULL, NULL, NULL, NULL);
                                  }; 

value:                            func_call 
                                  {
                                    $$ = $1;
                                  }
                                  | constant 
                                  {
                                    $$ = $1;
                                  }
                                  | arr
                                  {
                                    $$ = $1;
                                  }; 

arr:                              arr '[' data ']' 
                                  {
                                    $$ = makeNode(astArr, NULL, $1, NULL, NULL, NULL);
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
                                    sym = makeSymbol("", 3, &value, 1, 'c', 0, 0);
                                    //push_vs(sym);
                                  }
                                  | STR 
                                  {
                                    $$ = makeNode(astStr, NULL, NULL, NULL, NULL, NULL);
                                    sym = makeSymbol("", 2, &value, 0, 'c', 0, 0);
                                    pushV(sym);
                                  }
                                  | DOUBLE 
                                  {
                                    $$ = makeNode(astDouble, NULL, NULL, NULL, NULL, NULL);
                                    sym = makeSymbol("", 1, &value, 8, 'c', 0, 0);
                                    pushV(sym);
                                  }
                                  | VOID
                                  {
                                    $$ = makeNode(astVoid, NULL, NULL, NULL, NULL, NULL);
                                    sym = makeSymbol("", 4, &value, 0, 'c', 0, 0);
                                    pushV(sym);
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

int main(int argc, char *argv[])
{
  if (argc != 2) {
      printf("\nUsage: <exefile> <inputfile>\n\n");
      exit(0);
  }
  Initialize_Tables();
  yyin = fopen(argv[1], "r");
  yyparse();

  if(error_code == 1)
    exit(1);
    
  traverse(astroot, -3);
  Print_Tables();
  return 0;
}

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

//Variable stack

void ShowVStack(){
	printf("\n--- VARIABLE STACK ---\n");
	for (int i=vtop; i>=0; i--){
		printf("%s\n", vs[i]);
	}
	printf("--- END ---\n");
}

void pushV(struct Symbol *p)
{
   vs[++vtop]=p;
}

struct Symbol *popV()
{
   return(vs[vtop--]);
}

//Return Stack

void ShowRStack(){
	printf("\n--- RETURN STACK ---\n");
	for (int i=rtop; i>=0; i--){
		printf("%s\n", rs[i]);
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
  ptr->tag = tag;
  if(tag == 'f'){
    strcpy(ptr->func_name, name);
  } else{
    strcpy(ptr->name, name);
  }
  switch(type) {
    case 0:
      ptr->value.ivalue = value->ivalue;
      break;
    case 1:
      ptr->value.dvalue = value->dvalue;
      break;
    case 2:
      strcpy(ptr->value.yvalue, value->yvalue);
      break;
    case 3:
      ptr->value.ivalue = value->ivalue;
  }
  ptr->type = type;
  //ptr->scope = scope;
  ptr->size = size;
  ptr->no_elements = no_elements;
  ptr->no_of_params = no_of_params;
  ptr->symbol_table = NULL;
  ptr->next = NULL;
  ptr->prev = NULL;

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
   
	exists=find_method(newme->name);
	if( !exists )
	{
		add_method(newme);
  }
  else
  {
      printf("%s redeclaration.\n",newme->name);
      exit(1);
  }
  currmethod = symbp;
}


int genKey(char *s)
{  char *p;
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
{  int i;
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
{  int i;
   struct Symbol *ptr;

   i = genKey(s);
   ptr = methods_table.symbols[i];
   
   while(ptr && (strcmp(ptr->func_name,s) !=0))
      ptr = ptr->next;
   return ptr;
}

void spacing(int n)
{  
	int i;   
	for(i=0; i<n; i++) printf(" ");
}

void traverse(struct Ast_node *p, int n)
{  
	int i;

    n=n+3;
    if(p)
    {
		switch (p->node_type)
		{
			case astProgram: 
				spacing(n); printf("astProgram\n"); 
				break;
			case astFunctions: 
				spacing(n); printf("astFunctions\n"); 
				break;
			case astFunction: 
				spacing(n); printf("astFunction\n"); 
				break;
			case astFunctionName: 
				spacing(n); printf("astFunctionName\n"); 
				break;
			case astParamList: 
				spacing(n); printf("astParamList\n"); 
				break;
			case astStmtsList: 
				spacing(n); printf("astStmtsList\n"); 
				break;
			case astBreak: 
				spacing(n); printf("astBreak\n"); 
				break;
			case astContinue: 
				spacing(n); printf("astContinue\n"); 
				break;
			case astAssignStmt: 
				spacing(n); printf("astAssignStmt\n"); 
				break;
			case astLoop: 
				spacing(n); printf("astLoop\n"); 
				break;  
			case astConditional: 
				spacing(n); printf("astConditional\n"); 
				break;   
			case astRemaiCond: 
				spacing(n); printf("astRemaiCond\n"); 
				break;
			case astElifStmts: 
				spacing(n); printf("astElifStmts\n"); 
				break;
			case astElseStmt: 
				spacing(n); printf("astElseStmt\n"); 
				break;
			case astConditions: 
				spacing(n); printf("astConditions\n"); 
				break;
			case astBoolean:
				spacing(n); printf("astBoolean\n"); 
				break;
			case astReturnStmt: 
				spacing(n); printf("astReturnStmt\n"); 
				break;
			case astArrayDecl: 
				spacing(n); printf("astArrayDecl\n"); 
				break;
			case astFuncCall: 
				spacing(n); printf("astFuncCall\n"); 
				break;
			case astCustomFunc: 
				spacing(n); printf("astCustomFunc\n"); 
				break;
			case astFuncShow: 
				spacing(n); printf("astFuncShow\n"); 
				break;
			case astFuncTake: 
				spacing(n); printf("astFuncTake\n"); 
				break;
			case astArgs:
				spacing(n); printf("astArgs\n"); 
				break;
			case astArrayAssign: 
				spacing(n); printf("astArrayAssign\n"); 
				break;
			case astIdList: 
				spacing(n); printf("astIdList\n"); 
				break;
			case astParam: 
				spacing(n); printf("astParam\n"); 
				break;
			case astAssignment: 
				spacing(n); printf("astAssignment\n"); 
				break;
			case astExpr: 
				spacing(n); printf("astExpr\n"); 
				break;
			case astArr: 
				spacing(n); printf("astArr\n"); 
				break;
			case astData: 
				spacing(n); printf("astData\n"); 
				break;
			case astInt: 
				spacing(n); printf("astInt\n"); 
				break;
			case astBool: 
				spacing(n); printf("astBool\n"); 
				break;
			case astStr: 
				spacing(n); printf("astStr\n"); 
				break;
			case astDouble: 
				spacing(n); printf("astDouble\n"); 
				break;
			case astVoid: 
				spacing(n); printf("astVoid\n"); 
				break;
			case astAdd: 
				spacing(n); printf("astAdd\n"); 
				break;
			case astSub: 
				spacing(n); printf("astSub\n"); 
				break;
			case astMul: 
				spacing(n); printf("astMul\n"); 
				break;
			case astDiv: 
				spacing(n); printf("astDiv\n"); 
				break;
			case astLte:
				spacing(n); printf("astLte\n"); 
				break;
			case astGte:
				spacing(n); printf("astGte\n"); 
				break;
			case astLt:
				spacing(n); printf("astLt\n"); 
				break;
			case astGt: 
				spacing(n); printf("astGt\n"); 
				break;
			case astEq: 
				spacing(n); printf("astEq\n"); 
				break;
			case astNeq: 
				spacing(n); printf("astNeq\n"); 
				break;
			case astAnd: 
				spacing(n); printf("astAnd\n");
				break;
			case astOr: 
				spacing(n); printf("astOr\n"); 
				break;
			case astXor: 
				spacing(n); printf("astXor\n"); 
				break;
			case astIntConst: 
				spacing(n); printf("astIntConst\n"); 
				break;
			case astStrConst: 
				spacing(n); printf("astStrConst\n"); 
				break;
			case astBoolConst: 
				spacing(n); printf("astBoolConst\n"); 
				break;
			case astFloatConst: 
				spacing(n); printf("astFloatConst\n"); 
				break;
      case astId:
        spacing(n); printf("astId\n"); 
				break;
			default: 
				printf("AGNOSTO=%d\n",p->node_type);
		}
		for(i=0; i<4; i++) traverse(p->child_node[i],n);
	}
}