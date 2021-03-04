#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define NAME_LEN 100
#define SYM_TABLE_SIZE 40

#define astProgram 500
#define astFunctions 501
#define astFunction 502
#define astFunctionName 503
#define astParamList 504
#define astStmtsList 505
#define astBreak 506
#define astContinue 507
#define astAssignStmt 508
#define astLoop 509
#define astConditional 510
#define astRemaiCond 511
#define astElifStmts 512
#define astElseStmt 513
#define astConditions 514
#define astBoolean 515
#define astReturnStmt 516
#define astArrayDecl 517
#define astFuncCall 518
#define astCustomFunc 519
#define astFuncShow 520
#define astFuncTake 521
#define astArgs 522
#define astArrayAssign 523
#define astIdList 524
#define astParam 525
#define astAssignment 526
#define astExpr 527
#define astArr 528
#define astData 529
#define astInt 530
#define astBool 531
#define astStr 532
#define astDouble 533
#define astVoid 534
#define astSub 535
#define astMul 536
#define astDiv 537
#define astLte 538
#define astGte 539
#define astLt 540
#define astGt 541
#define astEq 542
#define astNeq 543
#define astAnd 544
#define astOr 545
#define astXor 546
#define astIntConst 547
#define astStrConst 548
#define astBoolConst 549
#define astFloatConst 550

union Value{
  int ivalue;
  double dvalue;
  char* yvalue;
};

struct Symbol {
  char name[NAME_LEN];                /* Variable Name */
  char func_name[NAME_LEN];           /* Function Name */
  int type;                           /* Datatype */
  int scope;                          /* Scope */
  union Value value;                  /* Value of the variable */
  int size;                           /* size of the variable */
  char tag;                           /* a-Array, v-Variable, f-Function */
  int no_elements;                    /*  number of elements for an array, in case of a variable - 1 */
  int no_of_params;                   /* Number of parameters in a function */
  // int *param_list;                    /* List of parameters of a function */ 
  // int *arr_elements;                  /* Elements in an array */

  struct Hash_Table *symbol_table;     /* Pointer to the symbol table if it is a method */

  struct Symbol *next;                /* Pointer to the next symbol in the symbol table */
  struct Symbol *prev;                /* Pointer to the previous symbol in the symbol table */
};

struct Hash_Table {
  int numbSymbols;
  struct Symbol *symbols[SYM_TABLE_SIZE];
};

struct Ast_node {
  int node_type;
  struct Symbol *symbol_node;
  struct Ast_node *child_node[4];
};

/* ----------------------- Function Prototypes -------------------------*/

void Initialize_Tables();
void Print_Tables();

struct Ast_node* makeNode(int type, struct Symbol *sn, struct Ast_node* first, struct Ast_node* second, struct Ast_node* third, struct Ast_node* fourth);
struct Symbol * makeSymbol(char *name, int type, int scope, int size,char tag,int no_elements,int no_of_params);

void add_variable_to_table(struct Symbol *symbp);
void add_method_to_table(struct Symbol *symbp);
int genKey(char *s);
void add_variable(struct Symbol *symbp);
struct Symbol *find_variable(char *s);
void add_method(struct Symbol *symbp);
struct Symbol *find_method(char *s);