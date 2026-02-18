
import re

raw_text = """
🔹 Q1 — Why Isn't the Field Updating?
Question
Why does the object keep its default value even after passing data to the constructor?
Broken Code
class User {
    private String name;

    public User(String name) {
        name = name;
    }

    public String getName() {
        return name;
    }
}
Correct Code
public User(String name) {
    this.name = name;
}
Riddle
Two names enter. One stays unchanged.
Answer
The parameter shadows the instance variable. Use this.

🔹 Q2 — Why Is It Printing 5 Instead of 10?
Question
Why does the program print 5 even though the object is of type B?
Broken Code
class A { int x = 5; }
class B extends A { int x = 10; }

A obj = new B();
System.out.println(obj.x);
Correct Code
Use a method instead:

class A { int getX() { return 5; } }
class B extends A { int getX() { return 10; } }
Riddle
The object is B.
The reference is A.
Who speaks?
Answer
Fields are not polymorphic. Methods are.

🔹 Q3 — Why Does This Crash at Runtime?
Question
Why does casting cause a runtime error?
Broken Code
class Animal {}
class Dog extends Animal {}

Animal a = new Animal();
Dog d = (Dog) a;
Correct Code
Animal a = new Dog();
Dog d = (Dog) a;
Riddle
You changed the label.
But not the object.
Answer
Casting does not change the actual object type.

🔹 Q4 — Why Isn't the Method Overridden?
Question
Why doesn't the child version execute?
Broken Code
class A {
    void show() {}
}

class B extends A {
    void show(int x) {}
}
Correct Code
@Override
void show() {}
Riddle
Same name. Different shape.
Answer
Method signature must match exactly.

🔹 Q5 — Why NullPointerException?
Question
Why does this throw an exception?
Broken Code
class Test {
    String text;

    void print() {
        System.out.println(text.length());
    }
}
Correct Code
String text = "";


OR null check.
Riddle
You asked something from nothing.
Answer
The variable was never initialized.

🔹 Q6 — Why Can't It Compile?
Question
Why does this fail to compile?
Broken Code
class Parent {
    Parent(int x) {}
}

class Child extends Parent {
    Child() {}
}
Correct Code
Child() {
    super(10);
}
Riddle
Before the child lives, the parent must exist.
Answer
Parent has no default constructor.

🔹 Q7 — Why Is It Calling Parent's Method?
Question
Why does it print "Parent"?
Broken Code
class Parent {
    static void show() {
        System.out.println("Parent");
    }
}

class Child extends Parent {
    static void show() {
        System.out.println("Child");
    }
}

Parent obj = new Child();
obj.show();
Correct Code
Use non-static method.
Riddle
Static methods obey the reference, not the object.
Answer
Static methods are hidden, not overridden.

🔹 Q8 — Why Is the Count Shared?
Question
Why do all objects share the same count?
Broken Code
class Counter {
    static int count = 0;

    Counter() {
        count++;
    }
}
Correct Code
Remove static if per-object count needed.
Riddle
One variable. Many instances.
Answer
Static variables belong to the class.

🔹 Q9 — Why Can't I Call This Method?
Question
Why can't I access child-specific method?
Broken Code
interface A {
    void show();
}

class B implements A {
    public void show() {}
    void extra() {}
}

A obj = new B();
obj.extra();
Correct Code
B obj = new B();
obj.extra();
Riddle
Reference limits visibility.
Answer
Interface reference exposes only interface methods.

🔹 Q10 — Why Does Equality Fail in HashSet?
Question
Why are logically equal objects stored twice?
Broken Code
class User {
    int id;

    public boolean equals(Object o) {
        return ((User)o).id == this.id;
    }
}
Correct Code
@Override
public int hashCode() {
    return Integer.hashCode(id);
}
Riddle
Equal in comparison.
Different in bucket.
Answer
Must override both equals and hashCode.

🔹 Q11 — Why Does the List Not Update?
Question
Why does adding elements to a method parameter list not affect the original list?
Broken Code
void addItem(List<String> items) {
    items = new ArrayList<>();
    items.add("New");
}

List<String> myList = new ArrayList<>();
addItem(myList);
System.out.println(myList.size());
Correct Code
void addItem(List<String> items) {
    items.add("New");
}
Riddle
The container was replaced. Original untouched.
Answer
Assignment rebinds the local reference; it does not affect the caller's object.

🔹 Q12 — Why Is the Thread Not Stopping?
Question
Why does Thread.stopRequested not stop the thread?
Broken Code
class Worker extends Thread {
    boolean stopRequested = false;

    public void run() {
        while (!stopRequested) {
            // do work
        }
    }
}

Worker w = new Worker();
w.start();
w.stopRequested = true;
Correct Code
volatile boolean stopRequested = false;
Riddle
Changes exist, but the CPU sees the old.
Answer
Thread visibility issue; must declare the flag volatile.

🔹 Q13 — Why Do Two Objects Compare Unequal?
Question
Why does == fail for two objects with the same values?
Broken Code
class Point {
    int x, y;
    Point(int x, int y) { this.x = x; this.y = y; }
}

Point p1 = new Point(1,2);
Point p2 = new Point(1,2);

System.out.println(p1 == p2);
Correct Code
System.out.println(p1.equals(p2));

@Override
public boolean equals(Object o) {
    Point p = (Point) o;
    return p.x == x && p.y == y;
}
Riddle
Two twins. Not the same identity.
Answer
== checks reference, not logical equality.

🔹 Q14 — Why Is the Map Key Overwritten?
Question
Why does inserting a new object with same content overwrite the old key?
Broken Code
class Key {
    int id;
    Key(int id) { this.id = id; }
}

Map<Key,String> map = new HashMap<>();
map.put(new Key(1), "A");
map.put(new Key(1), "B");
System.out.println(map.size());
Correct Code
@Override
public int hashCode() {
    return Integer.hashCode(id);
}
Riddle
Looks identical. Bucket decides.
Answer
HashMap uses hashCode() and equals(); missing hashCode causes collisions.

🔹 Q15 — Why Does super Not Work?
Question
Why does calling super() give an error?
Broken Code
class Parent {
    Parent(int x) {}
}

class Child extends Parent {
    Child() {
        super();
    }
}
Correct Code
Child() {
    super(10);
}
Riddle
The parent expects input. Child gave none.
Answer
Parent has no no-arg constructor; must pass arguments.

🔹 Q16 — Why Is the Stream Empty?
Question
Why does filtering a stream give no results?
Broken Code
List<String> names = List.of("Alice", "Bob");
names.stream()
     .filter(n -> { n.toUpperCase(); return true; })
     .forEach(System.out::println);
Correct Code
.filter(n -> n.toUpperCase().equals("ALICE"))
Riddle
You changed a copy. Original remains.
Answer
Strings are immutable; toUpperCase() returns a new string.

🔹 Q17 — Why Does Overloading Confuse the Compiler?
Question
Why does this method call fail to compile?
Broken Code
class Test {
    void process(int x, long y) {}
    void process(long x, int y) {}
}

Test t = new Test();
t.process(5,5);
Correct Code
t.process(5, 5L);
Riddle
Same numbers. Ambiguous path.
Answer
Compiler cannot disambiguate exact overload with literals.

🔹 Q18 — Why Is the Exception Not Caught?
Question
Why does this throw an uncaught exception?
Broken Code
try {
    throw new IOException();
} catch (Exception e) {
    System.out.println("Caught");
}
Correct Code
catch (IOException e) { System.out.println("Caught"); }
Riddle
Parent trap missed child.
Answer
IOException must be caught or declared; compiler forces checked exceptions to match.

🔹 Q19 — Why Does the Copy Share State?
Question
Why do modifications to one object affect the other?
Broken Code
class Container {
    List<String> items;
    Container(List<String> items) { this.items = items; }
}

List<String> list = new ArrayList<>();
Container c1 = new Container(list);
Container c2 = new Container(list);

c1.items.add("X");
System.out.println(c2.items.size());
Correct Code
this.items = new ArrayList<>(items);
Riddle
Shared blood. Separate bodies expected.
Answer
Both objects reference same list; need defensive copy.

🔹 Q20 — Why Is the Interface Method Not Found?
Question
Why does calling defaultMethod() fail?
Broken Code
interface A {
    default void show() {}
}

class B implements A {
    void show() {}
}

A obj = new B();
obj.defaultMethod();
Correct Code
obj.show();
Riddle
You changed the shape. The label remained.
Answer
Method name must match; no defaultMethod() exists in interface.

🔹 Q21 — Why Does Interface Conflict Arise?
Question
Why does this class fail to compile?
Broken Code
interface A { void show(); }
interface B { void show(); }

class C implements A, B {
}
Correct Code
class C implements A, B {
    public void show() {}
}
Riddle
Two parents. One child. Must speak once.
Answer
Implementing multiple interfaces with same method requires one concrete implementation.

🔹 Q22 — Why Can't I Access Outer Variable?
Question
Why does the inner class not see x?
Broken Code
class Outer {
    int x = 10;

    class Inner {
        void print() {
            int x = 20;
            System.out.println(x + Outer.this.y);
        }
    }
}
Correct Code
System.out.println(x + Outer.this.x);
Riddle
Two x's. One belongs outside.
Answer
Inner class can reference outer class via Outer.this; wrong variable used.

🔹 Q23 — Why Generics Cause Cast Exception?
Question
Why does this fail at runtime?
Broken Code
List raw = new ArrayList<String>();
raw.add(10);

String s = (String) raw.get(0);
Correct Code
List<String> list = new ArrayList<>();
list.add("Hello");
Riddle
The container says String. Reality disagrees.
Answer
Raw types bypass compile-time checks; unsafe cast causes ClassCastException.

🔹 Q24 — Why Is Reflection Returning Null?
Question
Why does getDeclaredField fail?
Broken Code
class Test { private int x; }

Field f = Test.class.getField("x");
Correct Code
Field f = Test.class.getDeclaredField("x");
f.setAccessible(true);
Riddle
Hidden treasure. Wrong map.
Answer
Private fields require getDeclaredField() and setAccessible(true).

🔹 Q25 — Why Do Threads Print Unexpected Order?
Question
Why does output vary between runs?
Broken Code
class Printer extends Thread {
    int id;
    Printer(int id) { this.id = id; }

    public void run() {
        System.out.println("Printing " + id);
    }
}

new Printer(1).start();
new Printer(2).start();
Correct Code
Use synchronization if order matters:

synchronized(System.out) { System.out.println(...); }
Riddle
Two hands. One clock. Chaos.
Answer
Thread scheduling is nondeterministic; no guaranteed order.

🔹 Q26 — Why Does Anonymous Class Shadow Variable?
Question
Why does the lambda see the wrong variable?
Broken Code
int x = 5;
Runnable r = new Runnable() {
    int x = 10;
    public void run() { System.out.println(x); }
};
r.run();
Correct Code
final int x = 5;
Runnable r = () -> System.out.println(x);
Riddle
Outer x waits. Inner x speaks.
Answer
Anonymous classes can have their own fields that shadow outer variables.

🔹 Q27 — Why Is Volatile Not Enough?
Question
Why does increment still fail?
Broken Code
volatile int count = 0;

count++;
Correct Code
AtomicInteger count = new AtomicInteger(0);
count.incrementAndGet();
Riddle
Visible, but not atomic.
Answer
volatile ensures visibility, but doesn't make compound operations atomic.

🔹 Q28 — Why Does Nested Static Class Fail to Access Non-Static?
Question
Why can't a static nested class use y?
Broken Code
class Outer {
    int y = 10;

    static class Inner {
        void print() {
            System.out.println(y);
        }
    }
}
Correct Code
Outer o = new Outer();
System.out.println(o.y);
Riddle
Detached branch. Needs trunk.
Answer
Static nested classes cannot access non-static members directly.

🔹 Q29 — Why Does Generic Method Fail Type Inference?
Question
Why can't the compiler infer type?
Broken Code
class Util {
    static <T> void printList(List<T> list) {}
}

List<Integer> nums = List.of(1,2,3);
Util.<String>printList(nums);
Correct Code
Util.printList(nums);
Riddle
Type claimed. Reality differs.
Answer
Explicit type argument conflicts with actual type; compiler cannot reconcile.

🔹 Q30 — Why Does Deadlock Happen?
Question
Why do threads hang forever?
Broken Code
class Deadlock {
    Object lock1 = new Object();
    Object lock2 = new Object();

    void t1() { synchronized(lock1){ synchronized(lock2){} } }
    void t2() { synchronized(lock2){ synchronized(lock1){} } }
}
Correct Code
Acquire locks in consistent order.
Riddle
Two hands grab two sticks in reverse. Freeze.
Answer
Deadlock occurs when threads acquire locks in conflicting orders.
"""

def escape_swift_string(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

# Regex to split units starting with 🔹 Q and some number
units = re.split(r'🔹 Q\d+ — ', raw_text)[1:]

print("    private static func generateJavaLevel3Questions() -> [Question] {")
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
    print(f"            title: \"Level 3 – Question {i}\",")
    print(f"            description: \"{escape_swift_string(question_text)}\",")
    print(f"            initialCode: \"{escape_swift_string(broken)}\",")
    print(f"            correctCode: \"{escape_swift_string(correct)}\",")
    print(f"            difficulty: 3,")
    print(f"            riddle: \"{escape_swift_string(riddle)}\",")
    print(f"            conceptExplanation: \"{escape_swift_string(answer)}\",")
    print(f"            language: .java")
    print(f"        ))")

print("")
print("        return questions")
print("    }")
