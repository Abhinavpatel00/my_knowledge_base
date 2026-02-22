
// inline struct 
// might be useful
struct { float x, y; } make_vec2(float x, float y)
{
    return (struct { float x, y; }){ x, y };
}
https://www.youtube.com/watch?v=k-vvokWGtGA&t=1782s
systemshock does something like this
typedef void (*StateFn)(void);

typedef enum {
    STATE_MENU,
    STATE_PLAYING,
    STATE_PAUSED
} GameState;

void menu_update(void);
void playing_update(void);
void paused_update(void);

StateFn state_table[] = {
    [STATE_MENU]    = menu_update,
    [STATE_PLAYING] = playing_update,
    [STATE_PAUSED]  = paused_update
};

state_table[current_state]();



You don’t want:

if(enemy->type == GOBLIN) ...
else if(enemy->type == DRAGON) ...

Instead:

typedef void (*AIUpdateFn)(Enemy*);

typedef enum {
    ENEMY_GOBLIN,
    ENEMY_DRAGON,
    ENEMY_SLIME,
    ENEMY_COUNT
} EnemyType;

Table:

AIUpdateFn ai_table[ENEMY_COUNT] = {
    [ENEMY_GOBLIN] = goblin_ai,
    [ENEMY_DRAGON] = dragon_ai,
    [ENEMY_SLIME]  = slime_ai
};

Update loop:

ai_table[enemy->type](enemy);

Now adding a new enemy is:

add enum
write function
plug into table

typedef void (*InputHandler)(Input*);

InputHandler input_table[] = {
    [STATE_MENU]    = menu_input,
    [STATE_PLAYING] = gameplay_input,
    [STATE_PAUSED]  = paused_input
};
In ECS-like designs, systems can be function pointers stored in arrays:

typedef void (*SystemUpdate)(float dt);

SystemUpdate systems[] = {
    physics_update,
    animation_update,
    render_update
};

Game loop:

for(int i = 0; i < SYSTEM_COUNT; i++)
    systems[i](dt);

Now you can reordeer systems dynamically.



-- this is cool
   a[b] == *(a + b)

-- for rand 
   int 0 = (int)&0

-O2 -fverbose-asm is very useful
in c89 this code compiles but in 99 doesnt because in c89 compiler creates implicit decl then finds symbol while linking
int main()
{
    printf("%d",     (int){55});
}
- return code might be garbage like one two three or anything like that if u dont do return 0;

-               -O2 -S -fverbose-asm  ,  -fdump-tree-all , 
-std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -g3 -fsanitize=address,undefined
-- undefined acc to   https://www.slideshare.net/slideshow/deep-c-programming/26451627  pg 157
    a = a++;
    printf("%d", a);
 but works on all compilers
-- lol compilers are more unreliable than llms
-- the evaluation order of most expr is undefined in c and cpp  


modifying a variable and reading it again without a sequence point in between is undefined behavior.

int a = 5;
a = a++ & printf("%d", a);

C does not define the evaluation order of:
left operand
right operand
So:
Maybe a++ happens first
Maybe printf reads a before increment
Maybe after
Maybe compiler reorders
Maybe optimizer folds things
Maybe demons escape
but in practice the result  will be mostly consistent 

%zu for size_t format specifier 
in cpp adding member funnc does not inc size,because class doesnt know about its members at runtime its just a syntax sugar however virtual will inc because of vtable am i right

Because without virtual, C++ decides what function to call before running the program.
With virtual, C++ decides while running the program.

#include <iostream>

class Shape {
public:
    virtual void draw() {
        std::cout << "I am a shape\n";
    }
};
class Circle : public Shape {
public:
    void draw() override {
        std::cout << "I am a circle\n";
    }
};
class Square : public Shape {
public:
    void draw() override {
        std::cout << "I am a square\n";
    }
};
int main() {
    Shape* s1 = new Circle();
    Shape* s2 = new Square();

    s1->draw();
    s2->draw();

    delete s1;
    delete s2;
}


this is v good  https://www.slideshare.net/slideshow/deep-c-programming/26451627
https://www.slideshare.net/slideshow/insecure-coding-in-c-and-c/35699341

https://c-faq.com/


