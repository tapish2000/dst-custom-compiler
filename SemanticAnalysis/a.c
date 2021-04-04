#include <stdio.h>
#include <stdbool.h>
#include <string.h>

union Value{
  int ivalue;
  float dvalue;
  char yvalue[300];
};

int something(int a, int b) {
    int c = b;
    return c;
}

int main() {

    char name[100], temp[100], func[20]=".func";
    union Value value;
    value.dvalue = 24.35;
    bool i = 1;
    int a = value.dvalue;
    printf("%f\n", value.dvalue);
    printf("%d\n", value.ivalue);
    printf("%d\n", a+i);

    strcpy(temp, func+1);
    strcpy(name, "_int");						
    strcat(temp, name);

    strcpy(name, "_doub");
    strcat(temp, name);		
    printf("%s\n",temp);
}