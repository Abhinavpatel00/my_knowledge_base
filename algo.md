
- stack sort works if there are no such order exist as 231  
- instead of checking whole array for this pattern which will or not be O(n) we can just stack sort whole array and then compare length if len is equal then we can say it is sortable if not then not

- stack sort algo is as follows
for x in array { 
out = 0;
top = -1;
while(stack.isempty &&  x > stack[top] )
  {
  output[out++] = stack[top--];
  }
  stack[++top] = x;
}
- there can be other permutations like the one avoids  the pattern          the patterns 132, 213, and 312
https://en.wikipedia.org/wiki/Stack-sortable_permutation
- stack permutation is #push ≥ #pop
So for n elements:
Total sequences of n pushes and n pops
2nCn 
Sequences where at some point: #pop > #push (2n)C(n+1) 
it can also be thought as 
Push = step up
Pop = step down
You start at ground level.
You must take exactly 2n steps.
You must end back at ground.
You are NOT allowed to go below ground.
You must take:
n steps up
n steps down
Imagine someone gives you a bad path.
idea of reflection
At some point it goes below ground.
Find the first moment it goes below ground.
Right there.
Now take everything before that moment
and flip it:
Up becomes down
Down becomes up
then valid = total - invalid
valid = (2n)C(n) -(2n)C(n+1)

2 ups
2 downs

All sequences:

UUDD ✅
UDUD ✅
UDDU ❌ (goes below ground)
DUUD ❌
DUDU ❌
DDUU ❌

Only 2 are valid.

Catalan(2) = 2.

void reflect_bad_path(char* s)
{
    int height = 0;
    int k      = -1;
    for(i, s[i] != '\0')
    {
        if(s[i] == 'U')height++; else height--;

        if(height == -1)
        {
            k = i;
            break;
        }
    }
    if(k == -1)
    {
        printf("Not a bad path.\n");
        return;
    }
    // Reflect prefix [0..k]
    for(int i = 0; i <= k; i++)
    {
        s[i] = (s[i] == 'U') ? 'D' : 'U';
    }
}
// more consice
void reflect_bad_path(char *s)
{
    for (int i = 0, h = 0; s[i]; ++i)
        if ((h += s[i] == 'U' ? 1 : -1) < 0)
        {
          while (i >= 0)
              s[i--] ^= ('U' ^ 'D');
          return;
        }
}

SSXSSXXX

every valid seq  U  [valid block]  D  [valid block]
so  c(n) = sum k = 0 to n-1 c(k)c(n-(k+1))

Suppose total pairs = 3.

We want all valid sequences with 3 pairs.

The first pair takes 1 opening and 1 closing.
That leaves 2 pairs to distribute between A and B.

So possibilities:

Case 1:
A has 0 pairs
B has 2 pairs

Structure:

()  [valid of size 2]

Case 2:
A has 1 pair
B has 1 pair

Structure:

( [size1] ) [size1]

Case 3:
A has 2 pairs
B has 0 pairs

Structure:

( [size2] )

Those are the only possibilities.

See the pattern?

If total pairs = n,

Then:

A can have:
0 pairs
1 pair
2 pairs
...
n−1 pairs
And B automatically gets the rest:
n−1−k pairs

For each possible size of A:
(number of ways to build A)
×
(number of ways to build B)

And since we try every possible split,
we add them all.

To build a valid structure of size n:
Choose how big the inside block is.
Multiply ways to build inside and outside.
Add over all choices.
Let’s test it with small numbers so your brain stops doubting.

n = 0
Only empty string.
Count = 1.

n = 1
Only:
()
Count = 1.
n = 2
Possible splits:
A=0, B=1
→ ()()
A=1, B=0
→ (())
Total = 2.
n = 3
A=0, B=2
→ () (2-ways) → gives 2
A=1, B=1
→ (1-way)(1-way) → gives 1
A=2, B=0
→ (2-ways) → gives 2
Total = 2 + 1 + 2 = 5.
Matches Catalan(3) = 5.
https://www.math.uchicago.edu/~may/VIGRE/VIGRE2007/REUPapers/FINALAPP/Lim.pdf

an = (2n)! / ((n + 1)! n!)
(2n)!

That counts all ways to arrange 2n distinct objects.

But in our stack world, the 2n objects are not all distinct. We actually have:

n pushes (all identical)
n pops (all identical)

n! for the pushes
n! for the pops

That gives:

(2n)! / (n! n!)

The division by (n+1) comes from a structural constraint:
the path must never dip below zero.

That constraint kills exactly n/(n+1) of the sequences.

Only 1/(n+1) survive.


we only dip to zero when 









http://www.eng.utah.edu/~cs5785/slides-f10/Dangerous+Optimizations.pdf


http://blog.regehr.org/archives/1307

