
raw_data = """
🔹 Q1 — Why Doesn't the Struct Field Update?
Question
Why does the struct field remain unchanged after assignment?
Broken Code
#include <stdio.h>
typedef struct {
    int x;
} Point;

int main() {
    Point p;
    int x = 5;
    p.x = x;
    int x = 10;
    p.x = x;
    printf("%d", p.x);
}
Correct Code
Point p;
int x = 5;
p.x = x;
x = 10;
p.x = x;
Riddle
Shadow hides the real field.
Answer
Redeclaring int x inside same scope shadows previous variable.
Use same variable without redeclaration.

🔹 Q2 — Function Pointer Not Calling Correctly
Question
Why does this print 0 instead of 10?
Broken Code
#include <stdio.h>
int add(int a, int b) { return a + b; }
int main() {
    int (*fptr)(int,int);
    fptr(5,5);
    printf("%d", fptr(5,5));
}
Correct Code
int (*fptr)(int,int) = add;
printf("%d", fptr(5,5));
Riddle
Pointer points nowhere.
Answer
fptr was uninitialized → calling it undefined.
Must assign function address to pointer.

🔹 Q3 — Pointer-to-Struct + Dereference
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct { int x; } Point;
int main() {
    Point* p;
    p->x = 10;
    printf("%d", p->x);
}
Correct Code
Point pt;
Point* p = &pt;
p->x = 10;
printf("%d", p->x);
Riddle
Pointer must point to something real.
Answer
p is uninitialized → dereference crash.
Must assign valid memory address.

🔹 Q4 — Nested Struct Not Updating
Question
Why does inner struct remain default?
Broken Code
#include <stdio.h>
typedef struct {
    int x;
} Inner;
typedef struct {
    Inner in;
} Outer;

int main() {
    Outer o;
    Inner in;
    in.x = 5;
    o.in = in;
    in.x = 10;
    printf("%d", o.in.x);
}
Correct Code
Outer o;
o.in.x = 5;
o.in.x = 10;
printf("%d", o.in.x);
Riddle
Copy was made; original changes later.
Answer
Struct assignment copies value → modifying in after copying doesn't affect o.in.

🔹 Q5 — Pointer-to-Pointer Not Updating
Question
Why doesn't the value change through double pointer?
Broken Code
#include <stdio.h>
int main() {
    int x = 5;
    int* p = &x;
    int** pp;
    **pp = 10;
    printf("%d", x);
}
Correct Code
int x = 5;
int* p = &x;
int** pp = &p;
**pp = 10;
printf("%d", x);
Riddle
Double pointer must point to a valid pointer.
Answer
pp uninitialized → dereference crash.
Must assign valid pointer address.

🔹 Q6 — Array in Struct + Pointer Arithmetic
Question
Why does this print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; } S;
int main() {
    S s = {{1,2}};
    int* p = s.arr;
    printf("%d %d %d", *p, *(p+1), *(p+2));
}
Correct Code
S s = {{1,2,0}};
int* p = s.arr;
printf("%d %d %d", *p, *(p+1), *(p+2));
Riddle
Pointer walks too far, array too small.
Answer
*(p+2) → out-of-bounds → undefined.
Allocate enough array size.

🔹 Q7 — Function Pointer + Struct Field
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct {
    int (*fptr)(int,int);
} S;
int add(int a,int b){return a+b;}
int main() {
    S s;
    printf("%d", s.fptr(2,3));
}
Correct Code
S s;
s.fptr = add;
printf("%d", s.fptr(2,3));
Riddle
Pointer inside struct must be assigned.
Answer
s.fptr uninitialized → crash.
Must assign valid function address.

🔹 Q8 — Struct Pointer + Nested Pointer
Question
Why does this crash or print garbage?
Broken Code
#include <stdio.h>
typedef struct {
    int* p;
} S;
int main() {
    S s;
    *(s.p) = 5;
    printf("%d", *(s.p));
}
Correct Code
int x;
S s;
s.p = &x;
*(s.p) = 5;
printf("%d", *(s.p));
Riddle
Pointer inside struct must point to real memory.
Answer
s.p uninitialized → crash.

🔹 Q9 — Pointer-to-Pointer-to-Struct
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct { int x; } S;
int main() {
    S* s;
    S** pp;
    (**pp).x = 5;
    printf("%d", s->x);
}
Correct Code
S s_instance;
S* s = &s_instance;
S** pp = &s;
(**pp).x = 5;
printf("%d", s->x);
Riddle
Pointers must chain to real memory.
Answer
pp uninitialized → dereference crash.
Must initialize all levels.

🔹 Q10 — Nested Struct + Function Pointer
Question
Why does this crash or print garbage?
Broken Code
#include <stdio.h>
typedef struct {
    int (*f)(int);
} Inner;
typedef struct {
    Inner in;
} Outer;
int sqr(int x){ return x*x; }
int main() {
    Outer o;
    printf("%d", o.in.f(5));
}
Correct Code
Outer o;
o.in.f = sqr;
printf("%d", o.in.f(5));
Riddle
Nested pointer to function must be initialized.
Answer
o.in.f uninitialized → crash.
Must assign valid function address.

🔹 Q11 — Struct + Function Pointer + Array
Question
Why does this crash or print garbage?
Broken Code
#include <stdio.h>
typedef struct {
    int arr[2];
    int (*f)(int,int);
} S;
int add(int a,int b){return a+b;}
int main() {
    S s;
    printf("%d %d %d", s.arr[0], s.arr[1], s.f(2,3));
}
Correct Code
S s = {{1,2}};
s.f = add;
printf("%d %d %d", s.arr[0], s.arr[1], s.f(2,3));
Riddle
Array initialized, function pointer assigned.
Answer
s.arr uninitialized → undefined.
s.f uninitialized → crash.

🔹 Q12 — Pointer-to-Pointer-to-Struct + Assignment
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct { int x; } S;
int main() {
    S* s;
    S** pp;
    (**pp).x = 10;
    printf("%d", (**pp).x);
}
Correct Code
S s_instance;
S* s = &s_instance;
S** pp = &s;
(**pp).x = 10;
printf("%d", (**pp).x);
Riddle
All levels must point to valid memory.
Answer
pp uninitialized → dereference crash.

🔹 Q13 — Nested Struct + Pointer Arithmetic
Question
Why does this print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; } Inner;
typedef struct { Inner in; } Outer;
int main() {
    Outer o;
    int* p = o.in.arr;
    printf("%d %d %d", p[0], p[1], p[2]);
}
Correct Code
Outer o = {{{1,2,0}}};
int* p = o.in.arr;
printf("%d %d %d", p[0], p[1], p[2]);
Riddle
Array size too small, pointer walks too far.
Answer
p[2] → out-of-bounds → undefined.
Allocate enough array space.

🔹 Q14 — Function Pointer in Nested Struct
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct {
    int (*f)(int);
} Inner;
typedef struct {
    Inner in;
} Outer;
int sqr(int x){return x*x;}
int main() {
    Outer o;
    printf("%d", o.in.f(5));
}
Correct Code
Outer o;
o.in.f = sqr;
printf("%d", o.in.f(5));
Riddle
Nested function pointer must be assigned.
Answer
o.in.f uninitialized → crash.

🔹 Q15 — Pointer-to-Pointer-to-Struct + Function Pointer
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct { int (*f)(int); } S;
int sqr(int x){return x*x;}
int main() {
    S* s;
    S** pp;
    printf("%d", (**pp).f(4));
}
Correct Code
S s_instance;
S* s = &s_instance;
S** pp = &s;
s.f = sqr;
printf("%d", (**pp).f(4));
Riddle
Pointer-to-pointer must chain to initialized struct.
Answer
pp uninitialized → dereference crash.
f must be assigned.

🔹 Q16 — Multi-Level Struct Pointer + Array
Question
Why does this print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; } Inner;
typedef struct { Inner* in; } Outer;
int main() {
    Outer o;
    o.in->arr[0] = 1;
    printf("%d", o.in->arr[0]);
}
Correct Code
Inner inner_instance;
Outer o;
o.in = &inner_instance;
o.in->arr[0] = 1;
printf("%d", o.in->arr[0]);
Riddle
Pointer inside struct must point to a valid instance.
Answer
o.in uninitialized → crash.

🔹 Q17 — Struct + Pointer Arithmetic + Pre/Post Increment
Question
Why does this print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; } S;
int main() {
    S s = {{1,2}};
    int* p = s.arr;
    printf("%d %d %d", *p++, *p++, *p++);
}
Correct Code
S s = {{1,2,0}};
int* p = s.arr;
printf("%d %d %d", p[0], p[1], p[2]);
Riddle
Pointer walks too far, array too small.
Answer
Last *p++ → out-of-bounds → undefined behavior.

🔹 Q18 — Function Pointer + Array in Struct
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; int (*f)(int,int); } S;
int add(int a,int b){return a+b;}
int main() {
    S s;
    printf("%d %d %d", s.arr[0], s.arr[1], s.f(1,2));
}
Correct Code
S s = {{1,2}};
s.f = add;
printf("%d %d %d", s.arr[0], s.arr[1], s.f(1,2));
Riddle
Array initialized, function pointer assigned.
Answer
s.arr uninitialized → undefined.
s.f uninitialized → crash.

🔹 Q19 — Nested Struct + Pointer-to-Pointer + Assignment
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct { int x; } Inner;
typedef struct { Inner* in; } Outer;
int main() {
    Outer* o;
    Outer** pp;
    (**pp).in->x = 5;
    printf("%d", (**pp).in->x);
}
Correct Code
Inner inner_instance;
Outer outer_instance;
Outer* o = &outer_instance;
Outer** pp = &o;
o->in = &inner_instance;
(**pp).in->x = 5;
printf("%d", (**pp).in->x);
Riddle
Pointers must be chained and initialized.
Answer
pp uninitialized → crash.
in pointer must point to valid memory.

🔹 Q20 — Struct Pointer + Function Pointer + Array
Question
Why does this crash or print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; int (*f)(int); } S;
int sqr(int x){return x*x;}
int main() {
    S* s;
    printf("%d %d %d", s->arr[0], s->arr[1], s->f(5));
}
Correct Code
S s_instance = {{1,2}};
s_instance.f = sqr;
S* s = &s_instance;
printf("%d %d %d", s->arr[0], s->arr[1], s->f(5));
Riddle
Pointer must point to a valid struct, function pointer must be assigned.
Answer
s uninitialized → crash.
s->f uninitialized → crash.

🔹 Q21 — Nested Struct + Pointer-to-Pointer + Array + Function Pointer
Question
Why does this crash or print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; int (*f)(int); } Inner;
typedef struct { Inner* in; } Outer;
int sqr(int x){return x*x;}
int main() {
    Outer* o;
    Outer** pp;
    (**pp).in->arr[0] = 5;
    (**pp).in->f(3);
}
Correct Code
Inner inner_instance = {{1,2}};
Outer outer_instance;
outer_instance.in = &inner_instance;
Outer* o = &outer_instance;
Outer** pp = &o;
(**pp).in->arr[0] = 5;
(**pp).in->f = sqr;
printf("%d", (**pp).in->f(3));
Riddle
All pointers must be chained to valid memory.
Answer
pp and in uninitialized → crash.
Function pointer must be assigned before call.

🔹 Q22 — Pointer Arithmetic + Struct Array + Overflow
Question
Why does this print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; } S;
int main() {
    S s[2] = {{{1,2}}, {{3,4}}};
    int* p = s[0].arr;
    printf("%d %d %d %d %d", p[0], p[1], p[2], p[3], p[4]);
}
Correct Code
S s[2] = {{{1,2,0}}, {{3,4,0}}};
int* p = s[0].arr;
printf("%d %d %d %d %d", p[0], p[1], p[2], s[1].arr[0], s[1].arr[1]);
Riddle
Pointer walks across structs → array must be large enough.
Answer
p[2] → out-of-bounds → undefined.
Must allocate arrays carefully.

🔹 Q23 — Multi-level Pointer + Struct + Function Pointer
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct { int (*f)(int); } S;
int sqr(int x){return x*x;}
int main() {
    S* s;
    S** pp;
    printf("%d", (**pp).f(5));
}
Correct Code
S s_instance;
s_instance.f = sqr;
S* s = &s_instance;
S** pp = &s;
printf("%d", (**pp).f(5));
Riddle
Pointers chain → each must be valid, function pointer assigned.
Answer
pp uninitialized → crash.
f must point to valid function.

🔹 Q24 — Nested Struct + Pre/Post Increment + Pointer
Question
Why does this print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; } Inner;
typedef struct { Inner in; } Outer;
int main() {
    Outer o = {{{1,2}}};
    int* p = o.in.arr;
    printf("%d %d %d", *p++, *p++, *p++);
}
Correct Code
Outer o = {{{1,2,0}}};
int* p = o.in.arr;
printf("%d %d %d", p[0], p[1], p[2]);
Riddle
Pointer moves faster than array.
Answer
Last *p++ → out-of-bounds → undefined.
Allocate array large enough.

🔹 Q25 — Struct Array + Pointer-to-Pointer + Function Pointer
Question
Why does this crash or print garbage?
Broken Code
#include <stdio.h>
typedef struct { int (*f)(int); } S;
int sqr(int x){return x*x;}
int main() {
    S s[2];
    S** pp;
    printf("%d", (**pp).f(3));
}
Correct Code
S s[2];
s[0].f = sqr;
S* p = s;
S** pp = &p;
printf("%d", (**pp).f(3));
Riddle
Pointer-to-pointer must chain to initialized struct.
Answer
pp uninitialized → crash.
Function pointer must be assigned.

🔹 Q26 — Nested Struct + Array + Pointer Arithmetic + Precedence
Question
Why does this print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; } Inner;
typedef struct { Inner in[2]; } Outer;
int main() {
    Outer o = {{{1,2}},{{3,4}}};
    int* p = o.in[0].arr;
    if(*p & 1 == 1)
        printf("%d", *(p+2));
}
Correct Code
if((*p & 1) == 1)
    printf("%d", o.in[1].arr[0]);
Riddle
Operator precedence + pointer bounds.
Answer
== precedence → logic wrong.
*(p+2) → out-of-bounds → undefined.

🔹 Q27 — Multi-Level Pointer + Struct Array + Function Pointer
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct { int (*f)(int); } S;
int sqr(int x){return x*x;}
int main() {
    S s[2];
    S** pp;
    printf("%d", (**pp).f(2));
}
Correct Code
S s[2];
s[0].f = sqr;
S* p = s;
S** pp = &p;
printf("%d", (**pp).f(2));
Riddle
All pointers must chain → assign function.
Answer
pp uninitialized → crash.
f uninitialized → crash.

🔹 Q28 — Nested Struct + Pointer + Increment + Array
Question
Why does this print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; } Inner;
typedef struct { Inner in; } Outer;
int main() {
    Outer o = {{{1,2}}};
    int* p = o.in.arr;
    printf("%d %d %d", *p++, *p++, *p++);
}
Correct Code
Outer o = {{{1,2,0}}};
int* p = o.in.arr;
printf("%d %d %d", p[0], p[1], p[2]);
Riddle
Pointer walks too far → array too small.
Answer
Last dereference out-of-bounds → undefined behavior.

🔹 Q29 — Struct + Function Pointer + Nested Pointer
Question
Why does this crash?
Broken Code
#include <stdio.h>
typedef struct { int (*f)(int); } S;
int sqr(int x){return x*x;}
int main() {
    S* s;
    S** pp;
    printf("%d", (**pp).f(4));
}
Correct Code
S s_instance;
s_instance.f = sqr;
S* s = &s_instance;
S** pp = &s;
printf("%d", (**pp).f(4));
Riddle
Pointer-to-pointer → chain must be valid.
Answer
pp uninitialized → crash.
Function pointer must be assigned.

🔹 Q30 — Nested Struct + Multi-Pointer + Array + Function Pointer
Question
Why does this crash or print garbage?
Broken Code
#include <stdio.h>
typedef struct { int arr[2]; int (*f)(int); } Inner;
typedef struct { Inner* in; } Outer;
int sqr(int x){return x*x;}
int main() {
    Outer* o;
    Outer** pp;
    printf("%d %d %d", (**pp).in->arr[0], (**pp).in->arr[1], (**pp).in->f(3));
}
Correct Code
Inner inner_instance = {{1,2}};
inner_instance.f = sqr;
Outer outer_instance;
outer_instance.in = &inner_instance;
Outer* o = &outer_instance;
Outer** pp = &o;
printf("%d %d %d", (**pp).in->arr[0], (**pp).in->arr[1], (**pp).in->f(3));
Riddle
All pointers must chain, function pointer assigned, array valid.
Answer
pp uninitialized → crash.
in pointer uninitialized → crash.
Function pointer uninitialized → crash.
Array bounds must be checked.
"""

import re

def escape_swift_string(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

questions = []
# Split by 🔹 Q
blocks = re.split(r'🔹 Q\d+', raw_data)[1:]

for i, block in enumerate(blocks, 1):
    lines = [l.strip() for l in block.strip().split('\n') if l.strip()]
    
    title_match = re.search(r'— (.*)', block)
    title = title_match.group(1) if title_match else f"Level 3 – Question {i}"
    
    question_text = ""
    broken_code = ""
    correct_code = ""
    riddle = ""
    answer = ""
    
    current_section = None
    
    for line in block.split('\n'):
        line_strip = line.strip()
        if not line_strip: continue
        
        if line_strip == "Question":
            current_section = "question"
            continue
        elif line_strip == "Broken Code":
            current_section = "broken"
            continue
        elif line_strip == "Correct Code":
            current_section = "correct"
            continue
        elif line_strip == "Riddle":
            current_section = "riddle"
            continue
        elif line_strip == "Answer":
            current_section = "answer"
            continue
            
        if current_section == "question":
            question_text += line + "\n"
        elif current_section == "broken":
            broken_code += line + "\n"
        elif current_section == "correct":
            correct_code += line + "\n"
        elif current_section == "riddle":
            riddle += line + "\n"
        elif current_section == "answer":
            answer += line + "\n"

    questions.append(f"""
        questions.append(Question(
            title: "Level 3 – Question {i}",
            description: "{escape_swift_string(question_text.strip())}",
            initialCode: "{escape_swift_string(broken_code.strip())}",
            correctCode: "{escape_swift_string(correct_code.strip())}",
            difficulty: 3,
            riddle: "{escape_swift_string(riddle.strip())}",
            conceptExplanation: "{escape_swift_string(answer.strip())}",
            language: .c
        ))""")

print("    private static func generateCLevel3Questions() -> [Question] {")
print("        var questions: [Question] = []")
for q in questions:
    print(q)
print("        return questions")
print("    }")
