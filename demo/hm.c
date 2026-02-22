#include <stdio.h>
void ok()
{
    int a=2;
    a = a++ & printf("%d", a);
}
int main()
{

    ok();
    ok();
    ok();
    ok();
    ok();

    return 0;
}
