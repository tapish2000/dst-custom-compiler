
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
  int *param_list;                    /* List of parameters of a function */ 
  int *arr_elements;                  /* Elements in an array */

  struct Hash_Table *symbols_ptr;   /* Pointer to the symbol table if it is a method */

  struct Symbol *next;                /* Pointer to the next symbol in the symbol table */
  struct Symbol *prev;                /* Pointer to the previous symbol in the symbol table */
};

struct Hash_Table {
  int no_symbols;
  struct Symbol *sym_table[SYM_TABLE_SIZE];
};

struct Ast_node {
  int node_type;
  struct Symbol *symbol_node;
  struct Ast_node *child_node[4];
};

/* ----------------------- Function Prototypes -------------------------*/

void Intialize_Tables();
