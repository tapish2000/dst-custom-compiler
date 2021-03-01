
#define NAME_LEN 300
#define SYM_TABLE_SIZE 40


struct Symbol {
  char name[NAME_LEN];                /* Variable Name */
  char func_name[NAME_LEN];           /* Function Name */
  int type;                           /* Datatype */
  int scope;                          /* Scope */
  int int_val;                        /* Integer Value */
  double double_val;                  /* Double Value */
  char *string_val;                   /* String Value */
  int bool_val;                       /* Boolean Value */
  int arr_size;                       /* Size of an array */
  int no_of_params;                   /* Number of parameters in a function */
  int *param_list;                    /* List of parameters of a function */ 
  int *arr_elements;                  /* Elements in an array */

  struct Symbol_table *symbols_ptr;   /* Pointer to the symbol table if it is a method */

  struct Symbol *next;                /* Pointer to the next symbol in the symbol table */
  struct Symbol *prev;                /* Pointer to the previous symbol in the symbol table */
};

struct Symbol_table {
  int no_symbols;
  struct Symbol *sym_table[SYM_TABLE_SIZE];
};

struct Ast_node {
  int node_type;
  struct Symbol *symbol_node;
  struct Ast_node *child_node[4];
};