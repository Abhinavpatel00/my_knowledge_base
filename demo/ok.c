
#include <stdio.h>

// so int is sometimes initialised as global and sometimes local huh
void ok()
{
    int a;
    a++;
    printf("%d", a);
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
/*
Compiler | Std   | Opt | Compiles | Exit | Output
---------------------------------------------------------------
gcc | c89 | O0 | YES | 0 | 12345
gcc | c89 | O1 | YES | 0 | 11111
gcc | c89 | O2 | YES | 0 | 11111
gcc | c89 | O3 | YES | 0 | 11111
gcc | c89 | Os | YES | 0 | 11111
gcc | c99 | O0 | YES | 0 | 12345
gcc | c99 | O1 | YES | 0 | 11111
gcc | c99 | O2 | YES | 0 | 11111
gcc | c99 | O3 | YES | 0 | 11111
gcc | c99 | Os | YES | 0 | 11111
gcc | c11 | O0 | YES | 0 | 12345
gcc | c11 | O1 | YES | 0 | 11111
gcc | c11 | O2 | YES | 0 | 11111
gcc | c11 | O3 | YES | 0 | 11111
gcc | c11 | Os | YES | 0 | 11111
gcc | c17 | O0 | YES | 0 | 12345
gcc | c17 | O1 | YES | 0 | 11111
gcc | c17 | O2 | YES | 0 | 11111
gcc | c17 | O3 | YES | 0 | 11111
gcc | c17 | Os | YES | 0 | 11111
gcc | gnu89 | O0 | YES | 0 | 12345
gcc | gnu89 | O1 | YES | 0 | 11111
gcc | gnu89 | O2 | YES | 0 | 11111
gcc | gnu89 | O3 | YES | 0 | 11111
gcc | gnu89 | Os | YES | 0 | 11111
gcc | gnu99 | O0 | YES | 0 | 12345
gcc | gnu99 | O1 | YES | 0 | 11111
gcc | gnu99 | O2 | YES | 0 | 11111
gcc | gnu99 | O3 | YES | 0 | 11111
gcc | gnu99 | Os | YES | 0 | 11111
gcc | gnu11 | O0 | YES | 0 | 12345
gcc | gnu11 | O1 | YES | 0 | 11111
gcc | gnu11 | O2 | YES | 0 | 11111
gcc | gnu11 | O3 | YES | 0 | 11111
gcc | gnu11 | Os | YES | 0 | 11111
clang | c89 | O0 | YES | 0 | 3276832769327703277132772
clang | c89 | O1 | YES | 0 | -1-1-1-1-1
clang | c89 | O2 | YES | 0 | -1-1-1-1-1
clang | c89 | O3 | YES | 0 | -1-1-1-1-1
clang | c89 | Os | YES | 0 | -1-1-1-1-1
clang | c99 | O0 | YES | 0 | 3276632767327683276932770
clang | c99 | O1 | YES | 0 | -1-1-1-1-1
clang | c99 | O2 | YES | 0 | -1-1-1-1-1
clang | c99 | O3 | YES | 0 | -1-1-1-1-1
clang | c99 | Os | YES | 0 | -1-1-1-1-1
clang | c11 | O0 | YES | 0 | 3276832769327703277132772
clang | c11 | O1 | YES | 0 | -1-1-1-1-1
clang | c11 | O2 | YES | 0 | -1-1-1-1-1
clang | c11 | O3 | YES | 0 | -1-1-1-1-1
clang | c11 | Os | YES | 0 | -1-1-1-1-1
clang | c17 | O0 | YES | 0 | 3276632767327683276932770
clang | c17 | O1 | YES | 0 | -1-1-1-1-1
clang | c17 | O2 | YES | 0 | -1-1-1-1-1
clang | c17 | O3 | YES | 0 | -1-1-1-1-1
clang | c17 | Os | YES | 0 | -1-1-1-1-1
clang | gnu89 | O0 | YES | 0 | 3276632767327683276932770
clang | gnu89 | O1 | YES | 0 | -1-1-1-1-1
clang | gnu89 | O2 | YES | 0 | -1-1-1-1-1
clang | gnu89 | O3 | YES | 0 | -1-1-1-1-1
clang | gnu89 | Os | YES | 0 | -1-1-1-1-1
clang | gnu99 | O0 | YES | 0 | 3276632767327683276932770
clang | gnu99 | O1 | YES | 0 | -1-1-1-1-1
clang | gnu99 | O2 | YES | 0 | -1-1-1-1-1
clang | gnu99 | O3 | YES | 0 | -1-1-1-1-1
clang | gnu99 | Os | YES | 0 | -1-1-1-1-1
clang | gnu11 | O0 | YES | 0 | 3276732768327693277032771
clang | gnu11 | O1 | YES | 0 | -1-1-1-1-1
clang | gnu11 | O2 | YES | 0 | -1-1-1-1-1
clang | gnu11 | O3 | YES | 0 | -1-1-1-1-1
clang | gnu11 | Os | YES | 0 | -1-1-1-1-1

*/
