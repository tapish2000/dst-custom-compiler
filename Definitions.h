#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define NAME_LEN 100
#define SYM_TABLE_SIZE 40

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
  char tag;                           /* a-Array, v-Variable, f-function */
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

void Intialize_Tables();
void Print_Tables();

struct Ast_node* makeNode(int type, struct Ast_node* first, struct Ast_node* second, struct Ast_node* third, struct Ast_node* fourth);
struct Symbol * makeSymbol(char *name, int type, int scope, int size,char tag,int no_elements,int no_of_params);

void add_variable_to_table(struct Symbol *symbp);
void add_method_to_table(struct Symbol *symbp);
int genKey(char *s);
void add_variable(struct Symbol *symbp);
struct Symbol *find_variable(char *s);
void add_method(struct Symbol *symbp);
struct Symbol *find_method(char *s);