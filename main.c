#include <stdio.h>

extern int add(int a, int b);

int main() {
    int result = add(5, 3);
    printf("add(5, 3) = %d\n", result);
    return result;
}
