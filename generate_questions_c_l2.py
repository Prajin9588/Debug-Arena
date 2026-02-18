
import re

raw_text = """
🔹 Q1 — Multiple Operator & Pointer Errors
Question

Why does this print garbage and possibly crash?

Broken Code
#include <stdio.h>
int main() {
    int* p, x = 5;
    p = x;
    if(*p = 10 && x = 5)
        printf("%d", *p);
}

Correct Code
int x = 5;
int* p = &x;
if((*p == 10) && (x == 5))
    printf("%d", *p);

Riddle

Pointer, assignment, and comparison all tangled.

Answer

p = x assigns integer to pointer → invalid.

*p = 10 is assignment, not comparison.

x = 5 is assignment inside condition.

Use proper & for pointer and == for comparisons.

🔹 Q2 — Array & Loop & Operator Traps
Question

Why does this crash or print wrong values?

Broken Code
#include <stdio.h>
int main() {
    int arr[3] = {1,2,3};
    int i = 0;
    while(i <= 3)
        printf("%d ", arr[i++]);
}

Correct Code
int i = 0;
while(i < 3)
    printf("%d ", arr[i++]);

Riddle

Off-by-one hides inside loop.

Answer

i <= 3 accesses arr[3] → out of bounds.

Loops must respect array size.

🔹 Q3 — Pointer + Null + Precedence Errors
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int* p = NULL;
    int x = 5;
    if(*p != 0 && x = 5)
        printf("%d", *p);
}

Correct Code
if(p != NULL && (*p != 0) && (x == 5))
    printf("%d", *p);

Riddle

Check pointer, compare properly, parentheses matter.

Answer

*p dereferences NULL → crash.

x = 5 is assignment, not comparison.

Parentheses required for precedence.

🔹 Q4 — Multiple Assignment & Post-Increment Trap
Question

Why does this print wrong values?

Broken Code
#include <stdio.h>
int main() {
    int x = 1, y = 2;
    int z = x = y++ + ++x;
    printf("%d %d %d", x, y, z);
}

Correct Code
int x = 1, y = 2;
x++;
int z = x + y++;
printf("%d %d %d", x, y, z);

Riddle

Increment, assignment, and evaluation collide.

Answer

Multiple assignments in one statement are tricky.

Post vs pre-increment affects evaluation order.

Avoid combining increment and assignment in same expression.

🔹 Q5 — Array, Pointer, and Dereference Errors
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int arr[3] = {1,2,3};
    int* p = arr + 3;
    *p = 10;
    printf("%d", arr[3]);
}

Correct Code
int* p = arr + 2;
*p = 10;
printf("%d", arr[2]);

Riddle

Pointer walks off array, dereference punishes.

Answer

arr+3 is beyond array.

Dereferencing past array → undefined behavior.

Access arr[3] invalid.

🔹 Q6 — Precedence & Short-Circuit Trap
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int* p = NULL;
    int x = 0;
    if(*p != 0 || x = 0)
        printf("OK");
}

Correct Code
if(p != NULL && (*p != 0) || x == 0)
    printf("OK");

Riddle

Order and operator matter.

Answer

*p evaluated first → crash (NULL).

x = 0 is assignment, not comparison.

Use proper precedence and short-circuit logic.

🔹 Q7 — Division + Pointer + Assignment Trap
Question

Why does this crash or give garbage?

Broken Code
#include <stdio.h>
int main() {
    int a = 5, b = 0;
    int* p;
    p = a/b;
    printf("%d", *p);
}

Correct Code
if(b != 0) {
    int res = a/b;
    int* p = &res;
    printf("%d", *p);
}

Riddle

Divide, then point.

Answer

Division by zero → runtime error.

Assigning integer to pointer → invalid.

Dereference uninitialized pointer → crash.

🔹 Q8 — Pre/Post Increment + Pointer Trap
Question

Why does this print garbage?

Broken Code
#include <stdio.h>
int main() {
    int x = 5;
    int* p = &x;
    printf("%d %d", x++, *p++);
}

Correct Code
printf("%d %d", x++, *p);

Riddle

Pointer increment shifts to nowhere.

Answer

*p++ increments pointer, not value.

Dereferencing pointer after increment → undefined if outside variable.

🔹 Q9 — Multiple Errors in String
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    char* str = "Hello";
    str[0] = 'h';
    printf("%s", str);
}

Correct Code
char str[] = "Hello";
str[0] = 'h';
printf("%s", str);

Riddle

String literal is read-only.

Answer

char* points to literal → read-only.

Modifying it causes crash.

Use char array to modify.

🔹 Q10 — Multiple Traps: Pointer + Array + Overflow
Question

Why does this print garbage or crash?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    p[2] = 5;
    printf("%d", arr[2]);
}

Correct Code
int arr[3] = {1,2,0};
arr[2] = 5;

Riddle

Pointer walks beyond, array too small.

Answer

arr[2] out of bounds → undefined.

Pointer dereference matches array size.

🔹 Q11 — Pointer + Assignment + Null
Question

Why does this crash and print garbage?

Broken Code
#include <stdio.h>
int main() {
    int* p = NULL;
    *p = 10;
    if(p = NULL)
        printf("%d", *p);
}

Correct Code
int x;
int* p = &x;
*p = 10;
if(p != NULL)
    printf("%d", *p);

Riddle

Pointer must exist before using.

Answer

Dereferencing NULL → crash.

p = NULL assigns, should be comparison p != NULL.

🔹 Q12 — Array + Out-of-Bounds + Dereference
Question

Why does this print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[3] = {1,2,3};
    int* p = arr + 3;
    printf("%d", *p);
}

Correct Code
int* p = arr + 2;
printf("%d", *p);

Riddle

Pointer steps off array.

Answer

arr+3 is outside bounds → undefined.

Dereference causes garbage or crash.

🔹 Q13 — Pre/Post Increment + Assignment
Question

Why does this print unexpected values?

Broken Code
#include <stdio.h>
int main() {
    int x = 1;
    int y = x++ + ++x;
    printf("%d %d", x, y);
}

Correct Code
int x = 1;
x++;
int y = x + x;

Riddle

Increment order matters.

Answer

x++ + ++x order of evaluation is undefined in C.

Mixing pre/post increment in same statement is unsafe.

🔹 Q14 — Null + Dereference + Comparison
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int* p = NULL;
    if(*p == 0 && p != NULL)
        printf("OK");
}

Correct Code
int x = 0;
int* p = &x;
if(p != NULL && *p == 0)
    printf("OK");

Riddle

Dereference first? Pointer dies.

Answer

Dereferencing NULL → crash.

Must check pointer first, then dereference.

🔹 Q15 — Division + Pointer + Assignment
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int a = 5, b = 0;
    int* p;
    p = a/b;
    printf("%d", *p);
}

Correct Code
if(b != 0) {
    int res = a/b;
    int* p = &res;
    printf("%d", *p);
}

Riddle

Divide safely, then point.

Answer

Division by zero → runtime error.

Cannot assign integer to pointer.

Dereference uninitialized pointer → crash.

🔹 Q16 — Array + Overflow + Pointer
Question

Why does this print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    p[2] = 5;
    printf("%d", arr[2]);
}

Correct Code
int arr[3] = {1,2,0};
arr[2] = 5;
printf("%d", arr[2]);

Riddle

Pointer walks off the array.

Answer

Out-of-bounds → undefined behavior.

Must allocate enough space.

🔹 Q17 — Operator Precedence + Assignment
Question

Why does this print wrong value?

Broken Code
#include <stdio.h>
int main() {
    int x = 1, y = 2;
    if(x & 1 == 1)
        printf("1");
    else
        printf("0");
}

Correct Code
if((x & 1) == 1)

Riddle

Parentheses guide evaluation.

Answer

== has higher precedence than &.

Must use parentheses to get intended logic.

🔹 Q18 — Multiple Pointer Errors
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int* p;
    *p = 10;
    p = NULL;
    printf("%d", *p);
}

Correct Code
int x;
int* p = &x;
*p = 10;
printf("%d", *p);

Riddle

Pointer points nowhere.

Answer

*p before initialization → crash.

*p after NULL → crash.

Always initialize pointer before dereference.

🔹 Q19 — String Literal + Assignment + Array Size
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    char* str = "Hello";
    str[0] = 'h';
    printf("%s", str);
}

Correct Code
char str[] = "Hello";
str[0] = 'h';
printf("%s", str);

Riddle

Read-only strings cannot be changed.

Answer

char* points to literal → read-only.

Modifying causes crash.

Use array for mutable string.

🔹 Q20 — Pre/Post Increment + Pointer Misuse
Question

Why does this print garbage?

Broken Code
#include <stdio.h>
int main() {
    int x = 5;
    int* p = &x;
    printf("%d %d", x++, *p++);
}

Correct Code
printf("%d %d", x++, *p);

Riddle

Pointer moves; value stays.

Answer

*p++ increments pointer, not value.

Dereferencing pointer after increment → undefined if outside variable.

🔹 Q21 — Array + Pointer + Overflow
Question

Why does this print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[3] = {1,2,3};
    int* p = arr;
    p[3] = 10;
    printf("%d", arr[3]);
}

Correct Code
int arr[4] = {1,2,3,0};
arr[3] = 10;
printf("%d", arr[3]);

Riddle

Pointer walks off the edge.

Answer

arr[3] is out of bounds → undefined behavior.

Must allocate enough memory for intended access.

🔹 Q22 — Null Pointer + Assignment + Condition
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int* p = NULL;
    if(*p = 0)
        printf("%d", *p);
}

Correct Code
int x;
int* p = &x;
*p = 0;
if(*p == 0)
    printf("%d", *p);

Riddle

Pointer must point somewhere first.

Answer

Dereferencing NULL → crash.

*p = 0 is assignment; comparison should be ==.

🔹 Q23 — Pre/Post Increment + Operator Precedence
Question

Why does this print wrong result?

Broken Code
#include <stdio.h>
int main() {
    int x = 1;
    if(x++ & 1 == 1)
        printf("Odd");
    else
        printf("Even");
}

Correct Code
if((x++ & 1) == 1)

Riddle

Parentheses save logic.

Answer

== has higher precedence than &.

Must group bitwise operation properly.

🔹 Q24 — String + Array + Assignment Trap
Question

Why does this crash or behave unexpectedly?

Broken Code
#include <stdio.h>
int main() {
    char* str = "C Language";
    str[0] = 'c';
    printf("%s", str);
}

Correct Code
char str[] = "C Language";
str[0] = 'c';
printf("%s", str);

Riddle

Literal strings are read-only.

Answer

char* points to literal → modifying it causes crash.

Use array for mutable string.

🔹 Q25 — Pointer + Division + Overflow + Short-Circuit
Question

Why does this crash or print garbage?

Broken Code
#include <stdio.h>
int main() {
    int a = 10, b = 0;
    int* p;
    if(a/b && (p == NULL))
        *p = a/b;
    printf("%d", *p);
}

Correct Code
int a = 10, b = 2;
int x;
int* p = &x;
if(b != 0 && p != NULL) {
    *p = a / b;
    printf("%d", *p);
}

Riddle

Divide safely, pointer alive, order matters.

Answer

Division by zero → crash.

Dereferencing NULL pointer → crash.

Logical AND short-circuit prevents invalid memory access.

🔹 Q26 — Pre/Post Increment + Pointer + Array Overflow + Assignment
Question

Why does this produce garbage or crash?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    arr[2] = 5;
    printf("%d %d %d", *p++, *p++, *p++);
}

Correct Code
int arr[3] = {1,2,0};
int* p = arr;
printf("%d %d %d", *p, *(p+1), arr[2]);

Riddle

Pointer walks off, array too small, increments collide.

Answer

arr[2] initially out-of-bounds → undefined.

*p++ increments pointer each time; last dereference outside array → garbage.

Must allocate enough space and avoid multiple pointer increments in same expression.

🔹 Q27 — Pointer + Null + Conditional + Assignment Confusion
Question

Why does this crash or print wrong result?

Broken Code
#include <stdio.h>
int main() {
    int* p = NULL;
    int x = 5;
    if(*p = x && p = NULL)
        printf("%d", *p);
}

Correct Code
int x = 5;
int* p = &x;
if(p != NULL && *p == x)
    printf("%d", *p);

Riddle

Dereference before check? Assignment lies.

Answer

*p dereferences NULL → crash.

*p = x is assignment, not comparison.

p = NULL assigns NULL, not comparison.

Must check pointer before dereference and use proper ==.

🔹 Q28 — Array + Pointer + Pre/Post Increment + Arithmetic
Question

Why does this print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[3] = {1,2,3};
    int* p = arr;
    printf("%d %d %d", *(p++ + 1), *p++, *(p+2));
}

Correct Code
int arr[3] = {1,2,3};
int* p = arr;
printf("%d %d %d", *(p+1), *(p+1), *(p+2));

Riddle

Pointer arithmetic + increment collide.

Answer

p++ + 1 increments pointer then adds → confusing.

Last dereference *(p+2) may go beyond array → undefined.

Pointer arithmetic must respect array bounds and order of evaluation.

🔹 Q29 — Pointer + Array + Undefined Behavior + Overflow
Question

Why does this crash or print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr + 1;
    p[2] = 10;
    printf("%d", arr[3]);
}

Correct Code
int arr[4] = {1,2,0,0};
int* p = arr + 1;
p[2] = 10;
printf("%d", arr[3]);

Riddle

Pointer walks too far, array too small.

Answer

arr[3] initially out-of-bounds → undefined.

Pointer arithmetic + dereference beyond allocated array → crash/garbage.

Must allocate enough memory for pointer access.

🔹 Q30 — Multi-Trap: Pointer + Array + Pre/Post Increment + Short-Circuit + Division
Question

Why does this crash or print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    int a = 10, b = 0;
    if((*p++ = a/b) && arr[2] == 0)
        printf("%d", arr[2]);
}

Correct Code
int arr[3] = {1,2,0};
int* p = arr;
int a = 10, b = 2;
if(b != 0) {
    *p = a / b;
    printf("%d", arr[0]);
}

Riddle

Divide safely, pointer moves, array bounds respected.

Answer

Division by zero → crash.

*p++ = ... increments pointer; last dereference unsafe.

arr[2] out-of-bounds → undefined.

Must combine safe pointer, valid array, and proper short-circuit logic.

🔹 Q31 — Pointer + Pre/Post Increment + Array Overflow + Division
Question

Why does this crash or print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    int a = 10, b = 0;
    *p++ = a / b;
    printf("%d %d", arr[0], arr[1]);
}

Correct Code
int arr[2] = {1,2};
int* p = arr;
int a = 10, b = 2;
*p = a / b;
printf("%d %d", arr[0], arr[1]);

Riddle

Divide safely before pointer walks.

Answer

Division by zero → crash.

*p++ increments pointer → arr[1] unchanged if used incorrectly.

Must respect array bounds.

🔹 Q32 — Null Pointer + Assignment + Short-Circuit + Comparison
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int* p = NULL;
    int x = 5;
    if(*p = x && p == NULL)
        printf("%d", *p);
}

Correct Code
int x = 5;
int* p = &x;
if(p != NULL && *p == x)
    printf("%d", *p);

Riddle

Pointer must live before dereference.

Answer

*p dereferences NULL → crash.

*p = x is assignment, not comparison.

p == NULL must not be evaluated first; check pointer first.

🔹 Q33 — Multiple Pointer + Array + Pre/Post Increment + Overflow
Question

Why does this crash or print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[3] = {1,2,3};
    int* p = arr;
    printf("%d %d %d %d", *p++, *p++, *p++, *(p+1));
}

Correct Code
int arr[4] = {1,2,3,0};
int* p = arr;
printf("%d %d %d %d", arr[0], arr[1], arr[2], arr[3]);

Riddle

Pointer moves too fast, array too small.

Answer

*p++ increments pointer multiple times → last dereference may go out-of-bounds.

Array size insufficient → undefined behavior.

🔹 Q34 — Operator Precedence + Pointer + Assignment
Question

Why does this print unexpected values?

Broken Code
#include <stdio.h>
int main() {
    int x = 1;
    int* p = &x;
    if(*p & 1 == 1)
        printf("Odd");
    else
        printf("Even");
}

Correct Code
if((*p & 1) == 1)

Riddle

Parentheses guide correct evaluation.

Answer

== has higher precedence than &.

Without parentheses, logic is incorrect.

🔹 Q35 — Pointer + Division + Pre/Post Increment + Null
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int a = 5, b = 0;
    int* p = NULL;
    *p = a / b;
    printf("%d", *p++);
}

Correct Code
int a = 5, b = 2;
int x;
int* p = &x;
*p = a / b;
printf("%d", *p);

Riddle

Divide first, then point.

Answer

Division by zero → crash.

Dereference NULL → crash.

*p++ increments pointer unnecessarily → unsafe if pointer moves beyond allocated memory.

🔹 Q36 — Array + Pointer + Short-Circuit + Assignment
Question

Why does this crash or behave unexpectedly?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr + 2;
    if(*p = 10 && arr[0] == 1)
        printf("%d", arr[2]);
}

Correct Code
int arr[3] = {1,2,0};
int* p = arr + 2;
*p = 10;
if(arr[0] == 1)
    printf("%d", arr[2]);

Riddle

Pointer must stay inside array.

Answer

arr+2 initially out-of-bounds → undefined behavior.

Assignment in conditional *p = 10 → logical bug.

Accessing arr[2] must be within array bounds.

🔹 Q37 — Pre/Post Increment + Pointer + Array Overflow
Question

Why does this print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    printf("%d %d %d", *p++, *p++, *p++);
}

Correct Code
int arr[3] = {1,2,0};
int* p = arr;
printf("%d %d %d", arr[0], arr[1], arr[2]);

Riddle

Pointer walks beyond array.

Answer

Multiple increments in single statement → last dereference undefined.

Array too small initially → must allocate enough space.

🔹 Q38 — Pointer + Array + Arithmetic + Precedence
Question

Why does this print unexpected values?

Broken Code
#include <stdio.h>
int main() {
    int arr[3] = {1,2,3};
    int* p = arr;
    printf("%d", *(p++ + 1));
}

Correct Code
int arr[3] = {1,2,3};
int* p = arr;
printf("%d", *(p + 1));

Riddle

Increment first or add first?

Answer

p++ + 1 increments pointer before addition → may access wrong memory.

Must separate pointer arithmetic from increment.

🔹 Q39 — Pointer + Null + Division + Short-Circuit
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int* p = NULL;
    int a = 5, b = 0;
    if(*p = a/b && p != NULL)
        printf("%d", *p);
}

Correct Code
int x;
int* p = &x;
int a = 5, b = 2;
if(p != NULL && b != 0) {
    *p = a / b;
    printf("%d", *p);
}

Riddle

Pointer safe, divide safe, check first.

Answer

Dereferencing NULL → crash.

Division by zero → crash.

Order of evaluation critical for safety.

🔹 Q40 — Multi-Trap: Pointer + Array + Pre/Post Increment + Assignment + Overflow
Question

Why does this crash or print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    arr[2] = 10;
    *p++ = 5;
    printf("%d %d %d", arr[0], arr[1], arr[2]);
}

Correct Code
int arr[3] = {1,2,0};
int* p = arr;
*p = 5;
arr[2] = 10;
printf("%d %d %d", arr[0], arr[1], arr[2]);

Riddle

Array bounds, pointer moves, assignment collide.

Answer

arr[2] initially out-of-bounds → undefined behavior.

Pointer increment *p++ → careful, could overwrite next element.

Must allocate enough memory and handle pointer carefully.

🔹 Q41 — Pointer + Pre/Post Increment + Array + Arithmetic
Question

Why does this crash or print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    printf("%d %d %d", *(p+1), *p++, *p++);
}

Correct Code
int arr[2] = {1,2};
int* p = arr;
printf("%d %d %d", arr[1], arr[0], arr[1]);

Riddle

Pointer order matters; increments collide.

Answer

*p++ increments pointer → changes subsequent dereference.

Mixing pointer arithmetic and post-increment in same statement → undefined.

🔹 Q42 — Null Pointer + Division + Assignment + Short-Circuit
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int* p = NULL;
    int a = 5, b = 0;
    if((*p = a/b) && p != NULL)
        printf("%d", *p);
}

Correct Code
int x;
int* p = &x;
int a = 5, b = 2;
if(p != NULL && b != 0) {
    *p = a / b;
    printf("%d", *p);
}

Riddle

Divide safely, pointer safe, check first.

Answer

Dereferencing NULL → crash.

Division by zero → crash.

Logical AND short-circuit critical.

🔹 Q43 — Array + Pointer + Overflow + Assignment
Question

Why does this print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr + 1;
    *p++ = 5;
    *p = 10;
    printf("%d %d %d", arr[0], arr[1], arr[2]);
}

Correct Code
int arr[3] = {1,2,0};
int* p = arr + 1;
*p = 5;
*(p+1) = 10;
printf("%d %d %d", arr[0], arr[1], arr[2]);

Riddle

Pointer moves, array too small, watch the bounds.

Answer

arr[2] initially out-of-bounds → undefined.

*p++ increments pointer → careful with next dereference.

Must allocate enough memory.

🔹 Q44 — Operator Precedence + Pointer + Increment + Assignment
Question

Why does this print unexpected values?

Broken Code
#include <stdio.h>
int main() {
    int x = 3;
    int* p = &x;
    if(*p & 1 == 1)
        printf("Odd");
    else
        printf("Even");
}

Correct Code
if((*p & 1) == 1)

Riddle

Operators trick you; parentheses save logic.

Answer

== has higher precedence than &.

Must use parentheses to get intended result.

🔹 Q45 — Pointer + Array + Pre/Post Increment + Short-Circuit
Question

Why does this crash or print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr + 2;
    if(*p++ && arr[0] == 1)
        printf("%d", *p);
}

Correct Code
int arr[3] = {1,2,0};
int* p = arr + 2;
if(arr[0] == 1)
    printf("%d", arr[2]);

Riddle

Pointer outside array? Short-circuit helps nothing.

Answer

arr+2 → out-of-bounds → undefined.

*p++ dereference → crash.

Must stay within allocated memory.

🔹 Q46 — Multiple Errors: Pointer + Division + Assignment + Overflow
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int a = 10, b = 0;
    int* p;
    *p = a / b;
    int arr[2];
    arr[2] = 5;
    printf("%d", *p);
}

Correct Code
int a = 10, b = 2;
int x;
int* p = &x;
*p = a / b;
int arr[3] = {0,0,0};
arr[2] = 5;
printf("%d", *p);

Riddle

Divide safely, pointer valid, array enough.

Answer

Division by zero → crash.

Dereferencing uninitialized pointer → crash.

Out-of-bounds array access → undefined.

🔹 Q47 — Pointer + Pre/Post Increment + Array + Overflow + Assignment
Question

Why does this crash or print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    *p++ = 5;
    *p++ = 10;
    printf("%d %d %d", arr[0], arr[1], arr[2]);
}

Correct Code
int arr[3] = {1,2,0};
int* p = arr;
*p = 5;
*(p+1) = 10;
printf("%d %d %d", arr[0], arr[1], arr[2]);

Riddle

Pointer moves too fast, array too small.

Answer

Multiple increments → last dereference out-of-bounds.

Must allocate enough array space.

🔹 Q48 — Null Pointer + Division + Short-Circuit + Increment
Question

Why does this crash?

Broken Code
#include <stdio.h>
int main() {
    int* p = NULL;
    int a = 5, b = 0;
    if(*p++ = a/b && p != NULL)
        printf("%d", *p);
}

Correct Code
int x;
int* p = &x;
int a = 5, b = 2;
if(p != NULL && b != 0) {
    *p = a / b;
    printf("%d", *p);
}

Riddle

Check pointer, divide safely, increment carefully.

Answer

Dereference NULL → crash.

Division by zero → crash.

*p++ increments pointer → unsafe if pointer not valid.

🔹 Q49 — Pointer + Array + Precedence + Overflow + Assignment
Question

Why does this print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    if(*p & 1 == 1)
        arr[2] = 5;
    printf("%d", arr[2]);
}

Correct Code
if((*p & 1) == 1)
    arr[2] = 5; // Ensure array size = 3
int arr[3] = {1,2,0};
printf("%d", arr[2]);

Riddle

Operators trick, pointer safe, array enough.

Answer

== precedence → logic wrong.

arr[2] initially out-of-bounds → undefined.

Must combine parentheses + array allocation.

🔹 Q50 — Multi-Trap Ultra: Pointer + Pre/Post Increment + Division + Short-Circuit + Overflow
Question

Why does this crash or print garbage?

Broken Code
#include <stdio.h>
int main() {
    int arr[2] = {1,2};
    int* p = arr;
    int a = 10, b = 0;
    if((*p++ = a/b) && arr[2] == 0)
        printf("%d", arr[2]);
}

Correct Code
int arr[3] = {1,2,0};
int* p = arr;
int a = 10, b = 2;
*p = a / b;
printf("%d", arr[0]);

Riddle

Divide safe, pointer valid, array in bounds.

Answer

Division by zero → crash.

Pointer increment → careful to stay within array.

Out-of-bounds access → undefined.
"""

def escape_swift_string(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

# Regex to split units starting with 🔹 Q and some number
units = re.split(r'🔹 Q\d+ — ', raw_text)[1:]

print("    private static func generateCLevel2Questions() -> [Question] {")
print("        var questions: [Question] = []")
print("")

for i, unit in enumerate(units, 1):
    lines = unit.strip().split('\n')
    title = lines[0].strip()
    
    # Extract sections
    question_start = -1
    broken_start = -1
    correct_start = -1
    riddle_start = -1
    answer_start = -1
    
    for idx, line in enumerate(lines):
        if line.startswith("Question"): question_start = idx
        elif line.startswith("Broken Code"): broken_start = idx
        elif line.startswith("Correct Code"): correct_start = idx
        elif line.startswith("Riddle"): riddle_start = idx
        elif line.startswith("Answer"): answer_start = idx

    question_text = "\n".join(lines[question_start+1:broken_start]).strip()
    broken = "\n".join(lines[broken_start+1:correct_start]).strip()
    correct = "\n".join(lines[correct_start+1:riddle_start]).strip()
    riddle = "\n".join(lines[riddle_start+1:answer_start]).strip()
    answer = "\n".join(lines[answer_start+1:]).strip()

    print(f"        questions.append(Question(")
    print(f"            title: \"Level 2 – Question {i}\",")
    print(f"            description: \"{escape_swift_string(question_text)}\",")
    print(f"            initialCode: \"{escape_swift_string(broken)}\",")
    print(f"            correctCode: \"{escape_swift_string(correct)}\",")
    print(f"            difficulty: 2,")
    print(f"            riddle: \"{escape_swift_string(riddle)}\",")
    print(f"            conceptExplanation: \"{escape_swift_string(answer)}\",")
    print(f"            language: .c")
    print(f"        ))")

print("")
print("        return questions")
print("    }")
