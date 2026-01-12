#include <stdio.h>

extern int add(int a, int b);
extern int test();

int main() {
    int result;
    result = add(5, 3);
    printf("add(5, 3) = %d\n", result);
    result = test();
    printf("test() = %d\n", result);
    return result;
}
