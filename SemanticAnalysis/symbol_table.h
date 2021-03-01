union Value{
  int ivalue;
  float fvalue;
  char yvalue;
} 

struct symbol {
    char var_name[100];
    char func_name[100];
    char tag;       //a-Array, v-Variable, f-function
    char type[10];  //integer or double or string or boolean
    int no_elements;   // number of elements for an array, in case of a variable - 1
    Union Value value;
    int size;
    int no_param;  
}