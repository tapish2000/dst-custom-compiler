%{
#include "Definitions.h"
#include <sys/queue.h>
extern FILE * yyin;

int yyerror(char*);
int yylex();

Ast_node* astroot;

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
%token IF ELSE ELIF LOOP SHOW TAKE RET VOID START INT DOUBLE STR BOOL ARR BREAK CONT

%type <node> program functions function function_name data_type paramas param_list param
%type <node> stmts_list stmt withSemcol withoutSemcol
%type <node> assign_stmt array_decl return_stmt func_call func_type func_name
%type <node> loop conditional conditions remain_cond elif_stmts else_stmt boolean bi_logic_cond rel_op
%type <node> expr array_assign array_type array_decl assign_stmt assignment args_list args id_list
%type <node> data constant arr value

%%
program:                          functions START '{' stmts_list '}'
                                  {
                                    astroot = makeNode(astProgram, NULL, $1, $4, NULL, NULL);
                                  }
                                  ;

functions:                        functions function 
                                  {
                                    $$ = makenode(astFunctions, NULL, $1, $2, NULL, NULL);
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
                                  };

params:                           param_list 
                                  {
                                    $$ = $1;
                                  }
                                  | /* EMPTY */ 
                                  {
                                    $$ = NULL;
                                  };

param_list:                       param_list ',' param 
                                  {
                                    $$ = makeNode(astParamList, NULL, $1, $3, NULL, NULL);
                                  }
                                  | param 
                                  {
                                    $$ = $1;
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

conditions:                       boolean 
                                  {
                                    $$ = $1;
                                  }
                                  | boolean bi_logic_cond conditions 
                                  {
                                    $$ = makeNode(astConditions, NULL, $1, $2, $3, NULL);
                                  }
                                  | NOT conditions 
                                  {
                                    $$ = makeNode(astConditions, NULL, $2, NULL, NULL, NULL);
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
                                    $$ = makeNode(astReturnStmt, NULL, $2, NULL, NULL, NULL);
                                  };

array_decl:                       ARR '<' array_type ',' data '>' ID array_assign 
                                  {
                                    $$ = makeNode(astArrayDecl, NULL, $3, $5, $8, NULL);
                                  };

array_type:                       data_type 
                                  {
                                    $$ = $1;
                                  }
                                  | array_decl
                                  {
                                    $$ = $1;
                                  };

func_call:                        func_type '(' args_list ')' 
                                  {
                                    $$ = makeNode(astFuncCall, NULL, $1, $3, NULL, NULL);
                                  };

func_type:                        FUNC_ID 
                                  {
                                    $$ = makeNode(astCustomFunc, NULL, NULL, NULL, NULL, NULL);
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
                                  };

assignment:                       ASSIGN expr 
                                  {
                                    $$ = makeNode(astAssignment, NULL, $2, NULL, NULL, NULL);
                                  };

expr:                             expr op value 
                                  {
                                    $$ = makeNode(astExpr, NULL, $1, $2, $3, NULL);
                                  }
                                  | value
                                  {
                                    $$ = $1;
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
                                    $$ = makeNode(astArr, NULL, NULL, NULL, NULL, NULL);
                                  }; 

data:                             INT_CONST 
                                  {
                                    $$ = makeNode(astData, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | ID
                                  {
                                    $$ = makeNode(astData, NULL, NULL, NULL, NULL, NULL);
                                  }; 

data_type:                        INT 
                                  {
                                    $$ = makeNode(astInt, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | BOOL 
                                  {
                                    $$ = makeNode(astBool, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | STR 
                                  {
                                    $$ = makeNode(astStr, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | DOUBLE 
                                  {
                                    $$ = makeNode(astDouble, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | VOID
                                  {
                                    $$ = makeNode(astVoid, NULL, NULL, NULL, NULL, NULL);
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
                                    $$ = makeNode(astIntConst, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | STR_CONST 
                                  {
                                    $$ = makeNode(astStrConst, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | BOOL_CONST 
                                  {
                                    $$ = makeNode(astBoolConst, NULL, NULL, NULL, NULL, NULL);
                                  }
                                  | FLOAT_CONST
                                  {
                                    $$ = makeNode(astFloatConst, NULL, NULL, NULL, NULL, NULL);
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
  return 0;
}

int yyerror(char *s) {
  printf("\nError: %s\n",s);
  return 0;
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
  for(int i=0;i<SYM_TABLE_SIZE;i++){
    printf("%s\n",methods_table.symbols[i]->name);
  }
  printf("------- Symbol tables ---------\n");
  for(int i=0;i<SYM_TABLE_SIZE;i++){
    for(int j=0;j<SYM_TABLE_SIZE;j++){
      printf("%s\n",Symbols_Table[i].symbols[j]->name);
    }
  }
}


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

struct Symbol * makeSymbol(char *name, int type, int scope, int size,char tag,int no_elements,int no_of_params){
  struct Symbol* ptr = (struct Symbol*)malloc(sizeof(struct Symbol));
  ptr->tag = tag;
  if(tag == 'f'){
    strcpy(ptr->func_name, name);
  }else{
    strcpy(ptr->name, name);
  }
  ptr->type = type;
  ptr->scope = scope;
  ptr->size = size;
  ptr->no_elements = no_elements;
  ptr->no_of_params = no_of_params;
  ptr->symbol_table = NULL;
  ptr->next = NULL;
  ptr->prev = NULL;
}

void add_variable_to_table(struct Symbol *symbp)
{  
  struct Symbol *exists, *newsy;

  newsy=symbp;
   
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
/*
void traverse(AstNode *p,int n)
{  
	int i;

    n=n+3;
    if(p)
    {
		switch (p->NodeType)
		{
			case astEmptyProgram: 
				kena(n); printf("astEmptyProgram\n"); 
				break;
			case astProgram: 
				kena(n); printf("astProgram\n"); 
				break;
			case astMethods: 
				kena(n); printf("astMethods\n"); 
				break;
			case astMethod: 
				kena(n); printf("astMethod\n"); 
				break;
			case astFormalParameters: 
				kena(n); printf("astFormalParameters\n"); 
				break;
			case astFormalArrayParameters: 
				kena(n); printf("astFormalArrayParameters\n"); 
				break;
			case astNoFormalParameters: 
				kena(n); printf("astNoFormalParameters\n"); 
				break;
			case astMoreFormalParameters: 
				kena(n); printf("astMoreFormalParameters\n"); 
				break;
			case astNoMoreFormalParameters: 
				kena(n); printf("astNoMoreFormalParameters\n"); 
				break;
			case astTypeInt: 
				kena(n); printf("astTypeInt\n"); 
				break;  
			case astTypeReal: 
				kena(n); printf("astTypeReal\n"); 
				break;   
			case astBody: 
				kena(n); printf("astBody\n"); 
				break;
			case astDeclarations: 
				kena(n); printf("astDeclarations\n"); 
				break;
			case astNoDeclarations: 
				kena(n); printf("astNoDeclarations\n"); 
				break;
			case astMoreDeclarations: 
				kena(n); printf("astMoreDeclarations\n"); 
				break;
			case astNoMoreDeclarations:
				kena(n); printf("astNoMoreDeclarations\n"); 
				break;
			case astDeclaration: 
				kena(n); printf("astDeclaration\n"); 
				break;
			case astArrayDeclaration: 
				kena(n); printf("astArrayDeclaration\n"); 
				break;
			case astArrayVariable: 
				kena(n); printf("astArrayVariable\n"); 
				break;
			case astDeclarationExtended: 
				kena(n); printf("astDeclarationExtended\n"); 
				break;
			case astVariable: 
				kena(n); printf("astVariable\n"); 
				break;
			case astVariableExtended: 
				kena(n); printf("astVariableExtended\n"); 
				break;
			case astNoVariable:
				kena(n); printf("astNoVariable\n"); 
				break;
			case astIncreaseAfter: 
				kena(n); printf("astIncreaseAfter\n"); 
				break;
			case astIncreaseBefore: 
				kena(n); printf("astIncreaseBefore\n"); 
				break;
			case astDecreaseAfter: 
				kena(n); printf("astDecreaseAfter\n"); 
				break;
			case astDecreaseBefore: 
				kena(n); printf("astDecreaseBefore\n"); 
				break;
			case astPlusEquals: 
				kena(n); printf("astPlusEquals\n"); 
				break;
			case astMinusEquals: 
				kena(n); printf("astMinusEquals\n"); 
				break;
			case astTimesEquals: 
				kena(n); printf("astTimesEquals\n"); 
				break;
			case astDivideEquals: 
				kena(n); printf("astDivideEquals\n"); 
				break;
			case astStatements: 
				kena(n); printf("astStatements\n"); 
				break;
			case astNoStatements: 
				kena(n); printf("astNoStatements\n"); 
				break;
			case astIncDecStatement: 
				kena(n); printf("astIncDecStatement\n"); 
				break;
			case astChangeAssignStatement: 
				kena(n); printf("astChangeAssignStatement\n"); 
				break;
			case astReturn: 
				kena(n); printf("astReturn\n"); 
				break;
			case astUnlessStatement: 
				kena(n); printf("astUnlessStatement\n"); 
				break;
			case astIfStatement: 
				kena(n); printf("astIfStatement\n"); 
				break;
			case astIfElseStatement: 
				kena(n); printf("astIfElseStatement\n"); 
				break;
			case astWhileStatement:
				kena(n); printf("astWhileStatement\n"); 
				break;
			case astRepeatStatement:
				kena(n); printf("astRepeatStatement\n"); 
				break;
			case astForStatement:
				kena(n); printf("astForStatement\n"); 
				break;
			case astBreakStatement: 
				kena(n); printf("astBreakStatement\n"); 
				break;
			case astPrintStatement: 
				kena(n); printf("astPrintStatement\n"); 
				break;
			case astPrintlnStatement: 
				kena(n); printf("astPrintlnStatement\n"); 
				break;
			case astMessage: 
				kena(n); printf("astMessage\n"); 
				//kena(n); printf("astMessage:%s\n", p->SymbolNode->name); 
				break;
			case astMoreMessage: 
				kena(n); printf("astMoreMessage\n"); 
				break;
			case astNoMoreMessage: 
				kena(n); printf("astNoMoreMessage\n"); 
				break;
			case astTextToPrint: 
				kena(n); printf("astTextToPrint\n"); 
				break;
			case astExpressionToPrint: 
				kena(n); printf("astExpressionToPrint\n"); 
				break;
			case astReadStatement: 
				kena(n); printf("astReadStatement\n"); 
				break;
			case astReadWithPrintStatement: 
				kena(n); printf("astReadWithPrintStatement\n"); 
				break;
			case astEmptyStatement: 
				kena(n); printf("astEmptyStatement\n"); 
				break;
			case astStartAssignStatement: 
				kena(n); printf("astStartAssignStatement\n"); 
				break;
			case astAssignStatement: 
				kena(n); printf("astAssignStatement\n"); 
				break;
			case astMoreAssignStatement: 
				kena(n); printf("astMoreAssignStatement\n"); 
				break;
			case astAssignMultipleStatement: 
				kena(n); printf("astAssignMultipleStatement\n"); 
				break;
			case astNestedAssignStatement: 
				kena(n); printf("astNestedAssignStatement\n"); 
				break;
			case astLastNestedAssignStatement: 
				kena(n); printf("astLastNestedAssignStatement\n"); 
				break;
			case astLocation: 
				kena(n); printf("astLocation\n"); 
				break;
			case astMethodName: 
				kena(n); printf("astMethodName\n"); 
				break;
			case astArrayName: 
				kena(n); printf("astArrayName\n"); 
				break;
			case astArrayCall: 
				kena(n); printf("astArrayCall\n"); 
				break;
			case astOrExpression: 
				kena(n); printf("astOrExpression\n"); 
				break;
			case astAndExpression: 
				kena(n); printf("astAndExpression\n"); 
				break;
			case astRelationExpression: 
				kena(n); printf("astRelationExpression\n"); 
				break;
			case astLessOrEqualOperator: 
				kena(n); printf("astLessOrEqualOperator\n"); 
				break;
			case astLessOperator: 
				kena(n); printf("astLessOperator\n"); 
				break;
			case astGreaterOperator: 
				kena(n); printf("astGreaterOperator\n"); 
				break;
			case astGreaterOrEqualOperator: 
				kena(n); printf("astGreaterOrEqualOperator\n"); 
				break;
			case astEqualOperator: 
				kena(n); printf("astEqualOperator\n"); 
				break;
			case astNotEqualOperator: 
				kena(n); printf("astNotEqualOperator\n"); 
				break;
			case astAddExpression: 
				kena(n); printf("astAddExpression\n"); 
				break;
			case astAddOperator: 
				kena(n); printf("astAddOperator\n"); 
				break;
			case astSubtractOperator: 
				kena(n); printf("astSubtractOperator\n"); 
				break;
			case astTerm: 
				kena(n); printf("astTerm\n"); 
				break;
			case astNotOperator: 
				kena(n); printf("astNotOperator\n"); 
				break;
			case astMultiplyOperator: 
				kena(n); printf("astMultiplyOperator\n"); 
				break;
			case astDivideOperator: 
				kena(n); printf("astDivideOperator\n"); 
				break;
			case astModuloOperator: 
				kena(n); printf("astModuloOperator\n"); 
				break;	
			case astIntConstant: 
				kena(n); printf("astIntConstant\n"); 
				break;
			case astRealConstant: 
				kena(n); printf("astRealConstant\n"); 
				break;
			case astTrue: 
				kena(n); printf("astTrue\n"); 
				break;
			case astFalse: 
				kena(n); printf("astFalse\n"); 
				break;
			case astMethodCall: 
				kena(n); printf("astMethodCall\n"); 
				break;
			case astActualParameters: 
				kena(n); printf("astActualParameters\n"); 
				break;
			case astNoActualParameters: 
				kena(n); printf("astNoActualParameters\n"); 
				break;
			case astMoreActualParameters: 
				kena(n); printf("astMoreActualParameters\n"); 
				break;
			case astNoMoreActualParameters: 
				kena(n); printf("astNoMoreActualParameters\n"); 
				break;
			default: 
				printf("AGNOSTO=%d\n",p->NodeType);
		}
		for(i=0; i<4; i++) traverse(p->pAstNode[i],n);
	}
}
*/
