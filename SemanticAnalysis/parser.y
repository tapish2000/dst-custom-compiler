%{
#include "Definitions.h"
extern FILE * yyin;

int yyerror(char*);
int yylex();

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
}
		  

%token ADD SUB MUL DIV ASSIGN AND OR XOR LTE GTE EQ NEQ NOT
%token <yid> FUNC_ID ID
%token <yint> INT_CONST BOOL_CONST
%token <ydou> FLOAT_CONST
%token <ystr> STR_CONST 
%token IF ELSE ELIF LOOP SHOW TAKE RET VOID START INT DOUBLE STR BOOL ARR BREAK CONT

%%
program:                          functions START{ printf("START\n");} '{' stmts_list '}';

functions:                        functions function 
                                  |  ;

function:                         function_name '{' stmts_list '}';

function_name:                    data_type FUNC_ID '(' params ')';

params:                           param_list 
                                  |  ;

param_list:                       param_list ',' param 
                                  | param;

stmts_list:                       stmt stmts_list 
                                  |  ;

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
                                  | arr assignment;

loop:                             LOOP '(' conditions ')' '{' stmts_list '}';

conditional:                      IF '(' conditions ')' '{' stmts_list '}' remain_cond;

remain_cond:                      elif_stmts else_stmt
                                  | ;

elif_stmts:                       elif_stmts ELIF '(' conditions ')' '{' stmts_list '}'
                                  | ELIF '(' conditions ')' '{' stmts_list '}';

else_stmt:                        ELSE '{' stmts_list '}'
                                  | ;

conditions:                       boolean 
                                  | boolean bi_logic_cond conditions
                                  | NOT conditions;

boolean:                          boolean  rel_op  expr 
                                  | expr;

return_stmt:                      RET expr;

array_decl:                       ARR '<' array_type ',' data '>' ID array_assign;

array_type:                       data_type 
                                  | array_decl;

func_call:                        func_type '(' args_list ')' ;

func_type:                        FUNC_ID | SHOW |TAKE;

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

arr:                              arr '[' data ']' | ID; 

data:                             INT_CONST | ID; 

data_type:                        INT | BOOL | STR | DOUBLE | VOID;

op:                               ADD | SUB | MUL | DIV; 

rel_op:                           LTE | GTE | '<' | '>' | EQ | NEQ;

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

int yyerror(char *s) {
  printf("\nError: %s\n",s);
  return 0;
}

/* ------------------- Handling Hash Tables --------------- */

void Intialize_Tables(){
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


struct Ast_node* makeNode(int type, struct Ast_node* first, struct Ast_node* second, struct Ast_node* third, struct Ast_node* fourth){
  struct Ast_node * ptr = (struct Ast_node *)malloc(sizeof(struct Ast_node));
  ptr->node_type = type;
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
    strcpy(ptr->func_name,name);
  }else{
    strcpy(ptr->name,name);
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