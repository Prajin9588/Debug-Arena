
questions_raw = [
    {
        "id": "Q1",
        "title": "Missing Semicolon",
        "broken": "int a = 10\nSystem.out.println(a);",
        "error": "Missing semicolon after variable declaration.",
        "correct": "int a = 10;\nSystem.out.println(a);",
        "riddle": "A sentence must end before another begins.",
        "answer": "Add ;"
    },
    {
        "id": "Q2",
        "title": "Missing Quotes",
        "broken": "System.out.println(Hello World);",
        "error": "String literal must be inside quotation marks.",
        "correct": "System.out.println(\"Hello World\");",
        "riddle": "Words need walls to be spoken.",
        "answer": "Add \" \"."
    },
    {
        "id": "Q3",
        "title": "Wrong Arithmetic Operator",
        "broken": "int result = 8 + 2;  // supposed to multiply\nSystem.out.println(result);",
        "error": "Using addition instead of multiplication.",
        "correct": "int result = 8 * 2;\nSystem.out.println(result);",
        "riddle": "When growth is required, combine through multiplication.",
        "answer": "Replace + with *."
    },
    {
        "id": "Q4",
        "title": "Assignment in Condition",
        "broken": "int x = 5;\nif(x = 5) {\n    System.out.println(\"Equal\");\n}",
        "error": "Assignment used instead of comparison.",
        "correct": "int x = 5;\nif(x == 5) {\n    System.out.println(\"Equal\");\n}",
        "riddle": "Comparing is not assigning.",
        "answer": "Use ==."
    },
    {
        "id": "Q5",
        "title": "Wrong Data Type",
        "broken": "int price = 9.99;",
        "error": "Decimal cannot be stored in int.",
        "correct": "double price = 9.99;",
        "riddle": "Fractions need more space than integers.",
        "answer": "Use double."
    },
    {
        "id": "Q6",
        "title": "Boolean Written as String",
        "broken": "boolean isReady = \"true\";",
        "error": "Boolean cannot store a string.",
        "correct": "boolean isReady = true;",
        "riddle": "Truth is not text.",
        "answer": "Remove quotation marks."
    },
    {
        "id": "Q7",
        "title": "Incorrect Increment",
        "broken": "int count = 3;\ncount =+ 1;\nSystem.out.println(count);",
        "error": "Wrong increment syntax.",
        "correct": "int count = 3;\ncount += 1;\nSystem.out.println(count);",
        "riddle": "Add to yourself properly.",
        "answer": "Use +=."
    },
    {
        "id": "Q8",
        "title": "Wrong Loop Direction",
        "broken": "for(int i = 0; i < 5; i--) {\n    System.out.println(i);\n}",
        "error": "Decrement causes infinite loop.",
        "correct": "for(int i = 0; i < 5; i++) {\n    System.out.println(i);\n}",
        "riddle": "To move forward, you must increase.",
        "answer": "Use i++."
    },
    {
        "id": "Q9",
        "title": "Array Index Out of Bounds",
        "broken": "int[] arr = {1,2,3};\nSystem.out.println(arr[3]);",
        "error": "Index 3 does not exist.",
        "correct": "int[] arr = {1,2,3};\nSystem.out.println(arr[2]);",
        "riddle": "Counting begins at zero.",
        "answer": "Use valid index."
    },
    {
        "id": "Q10",
        "title": "String Comparison",
        "broken": "String name = \"Alex\";\nif(name == \"Alex\") {\n    System.out.println(\"Match\");\n}",
        "error": "== compares references.",
        "correct": "String name = \"Alex\";\nif(name.equals(\"Alex\")) {\n    System.out.println(\"Match\");\n}",
        "riddle": "Compare meaning, not memory.",
        "answer": "Use .equals()."
    },
    {
        "id": "Q11",
        "title": "Missing Parentheses in Method Call",
        "broken": "System.out.println;",
        "error": "Method call requires parentheses.",
        "correct": "System.out.println();",
        "riddle": "A function must be opened to speak.",
        "answer": "Add ()."
    },
    {
        "id": "Q12",
        "title": "Variable Used Before Declaration",
        "broken": "x = 10;\nint x;",
        "error": "Variable declared after usage.",
        "correct": "int x;\nx = 10;",
        "riddle": "A name must exist before it's called.",
        "answer": "Declare first."
    },
    {
        "id": "Q13",
        "title": "Wrong Logical Operator",
        "broken": "if (5 > 3 & 4 > 2) {\n    System.out.println(\"True\");\n}",
        "error": "Single & used instead of logical AND.",
        "correct": "if (5 > 3 && 4 > 2) {\n    System.out.println(\"True\");\n}",
        "riddle": "Two truths must meet logically.",
        "answer": "Use &&."
    },
    {
        "id": "Q14",
        "title": "Missing Return Statement",
        "broken": "public static int add(int a, int b) {\n    int sum = a + b;\n}",
        "error": "Method must return an int.",
        "correct": "public static int add(int a, int b) {\n    int sum = a + b;\n    return sum;\n}",
        "riddle": "If you promise a number, you must give one back.",
        "answer": "Add return."
    },
    {
        "id": "Q15",
        "title": "Division Using Integers",
        "broken": "int result = 5 / 2;\nSystem.out.println(result);",
        "error": "Integer division removes decimals.",
        "correct": "double result = 5.0 / 2;\nSystem.out.println(result);",
        "riddle": "When splitting unevenly, use decimals.",
        "answer": "Use double."
    },
    {
        "id": "Q16",
        "title": "Switch Missing Break",
        "broken": "int day = 1;\nswitch(day) {\n    case 1:\n        System.out.println(\"Monday\");\n    case 2:\n        System.out.println(\"Tuesday\");\n}",
        "error": "Missing break causes fall-through.",
        "correct": "int day = 1;\nswitch(day) {\n    case 1:\n        System.out.println(\"Monday\");\n        break;\n    case 2:\n        System.out.println(\"Tuesday\");\n        break;\n}",
        "riddle": "Without stopping, you fall into the next path.",
        "answer": "Add break."
    },
    {
        "id": "Q17",
        "title": "Wrong Loop Condition",
        "broken": "int i = 1;\nwhile(i > 5) {\n    System.out.println(i);\n    i++;\n}",
        "error": "Condition false from start.",
        "correct": "int i = 1;\nwhile(i <= 5) {\n    System.out.println(i);\n    i++;\n}",
        "riddle": "The door must be open to enter the loop.",
        "answer": "Fix condition."
    },
    {
        "id": "Q18",
        "title": "Missing Curly Braces",
        "broken": "if (true)\n    System.out.println(\"Yes\");\n    System.out.println(\"Done\");",
        "error": "Only first line belongs to if.",
        "correct": "if (true) {\n    System.out.println(\"Yes\");\n    System.out.println(\"Done\");\n}",
        "riddle": "Multiple actions need a container.",
        "answer": "Add { }."
    },
    {
        "id": "Q19",
        "title": "Wrong Array Size",
        "broken": "int[] numbers = new int[2];\nnumbers[0] = 5;\nnumbers[1] = 10;\nnumbers[2] = 15;",
        "error": "Index 2 out of bounds.",
        "correct": "int[] numbers = new int[3];\nnumbers[0] = 5;\nnumbers[1] = 10;\nnumbers[2] = 15;",
        "riddle": "Space must match what you store.",
        "answer": "Increase array size."
    },
    {
        "id": "Q20",
        "title": "Wrong Type Casting",
        "broken": "double value = 9.7;\nint num = value;",
        "error": "Possible loss of precision.",
        "correct": "double value = 9.7;\nint num = (int) value;",
        "riddle": "If shrinking a number, be explicit.",
        "answer": "Cast with (int)."
    },
    {
        "id": "Q21",
        "title": "Missing Main Method Signature",
        "broken": "public class Test {\n    public static void start(String[] args) {\n        System.out.println(\"Hello\");\n    }\n}",
        "error": "JVM looks for main.",
        "correct": "public class Test {\n    public static void main(String[] args) {\n        System.out.println(\"Hello\");\n    }\n}",
        "riddle": "The program begins only at one door.",
        "answer": "Rename to main."
    },
    {
        "id": "Q22",
        "title": "Variable Scope Issue",
        "broken": "if (true) {\n    int x = 10;\n}\nSystem.out.println(x);",
        "error": "x not visible outside block.",
        "correct": "int x = 10;\nif (true) {\n}\nSystem.out.println(x);",
        "riddle": "What lives inside cannot escape its block.",
        "answer": "Declare outside."
    },
    {
        "id": "Q23",
        "title": "Wrong Return Type",
        "broken": "public static String getNumber() {\n    return 10;\n}",
        "error": "Returning int instead of String.",
        "correct": "public static String getNumber() {\n    return \"10\";\n}",
        "riddle": "Return what you promise.",
        "answer": "Match return type."
    },
    {
        "id": "Q24",
        "title": "Infinite Loop Condition",
        "broken": "int i = 0;\nwhile(i < 5) {\n    System.out.println(i);\n}",
        "error": "i never changes.",
        "correct": "int i = 0;\nwhile(i < 5) {\n    System.out.println(i);\n    i++;\n}",
        "riddle": "Movement prevents endless repetition.",
        "answer": "Increment i."
    },
    {
        "id": "Q25",
        "title": "Misplaced Braces",
        "broken": "if (true) {\n    System.out.println(\"Hi\");\n}\n}",
        "error": "Extra closing brace.",
        "correct": "if (true) {\n    System.out.println(\"Hi\");\n}",
        "riddle": "Every opening has only one closing.",
        "answer": "Remove extra }."
    },
    {
        "id": "Q26",
        "title": "Wrong Comparison Operator",
        "broken": "int age = 18;\nif (age => 18) {\n    System.out.println(\"Adult\");\n}",
        "error": "=> is invalid operator.",
        "correct": "int age = 18;\nif (age >= 18) {\n    System.out.println(\"Adult\");\n}",
        "riddle": "Greater must come before equal.",
        "answer": "Use >=."
    },
    {
        "id": "Q27",
        "title": "Incorrect String Concatenation",
        "broken": "int score = 90;\nSystem.out.println(\"Score: \" - score);",
        "error": "Cannot subtract string and int.",
        "correct": "int score = 90;\nSystem.out.println(\"Score: \" + score);",
        "riddle": "Words join numbers with addition.",
        "answer": "Use +."
    },
    {
        "id": "Q28",
        "title": "Wrong Boolean Condition",
        "broken": "boolean isOpen = false;\nif (isOpen = true) {\n    System.out.println(\"Open\");\n}",
        "error": "Assignment instead of comparison.",
        "correct": "boolean isOpen = false;\nif (isOpen == true) {\n    System.out.println(\"Open\");\n}",
        "riddle": "Truth should be checked, not changed.",
        "answer": "Remove assignment."
    },
    {
        "id": "Q29",
        "title": "Missing Array Initialization",
        "broken": "int[] arr;\narr[0] = 5;",
        "error": "Array not initialized.",
        "correct": "int[] arr = new int[1];\narr[0] = 5;",
        "riddle": "Space must exist before storing.",
        "answer": "Use new."
    },
    {
        "id": "Q30",
        "title": "Wrong For Loop Start",
        "broken": "for(int i = 5; i < 5; i++) {\n    System.out.println(i);\n}",
        "error": "Condition false immediately.",
        "correct": "for(int i = 0; i < 5; i++) {\n    System.out.println(i);\n}",
        "riddle": "Start before your limit.",
        "answer": "Fix starting value."
    },
    {
        "id": "Q31",
        "title": "Incorrect Char Declaration",
        "broken": "char letter = \"A\";",
        "error": "Char uses single quotes.",
        "correct": "char letter = 'A';",
        "riddle": "One character needs one quote.",
        "answer": "Use ' '."
    },
    {
        "id": "Q32",
        "title": "Wrong Logical OR",
        "broken": "if (5 > 10 ||| 3 < 4) {\n    System.out.println(\"True\");\n}",
        "error": "||| is invalid.",
        "correct": "if (5 > 10 || 3 < 4) {\n    System.out.println(\"True\");\n}",
        "riddle": "OR uses only two lines.",
        "answer": "Use ||."
    },
    {
        "id": "Q33",
        "title": "Missing Method Call",
        "broken": "public static void greet() {\n    System.out.println(\"Hello\");\n}\n\ngreet;",
        "error": "Method not called properly.",
        "correct": "public static void greet() {\n    System.out.println(\"Hello\");\n}\n\ngreet();",
        "riddle": "A method runs only when invoked.",
        "answer": "Add ()."
    },
    {
        "id": "Q34",
        "title": "Wrong Variable Name Case",
        "broken": "int number = 5;\nSystem.out.println(Number);",
        "error": "Java is case-sensitive.",
        "correct": "int number = 5;\nSystem.out.println(number);",
        "riddle": "Case matters in this language.",
        "answer": "Match exact name."
    },
    {
        "id": "Q35",
        "title": "Incorrect Modulus Usage",
        "broken": "int result = 10 % 0;",
        "error": "Cannot divide by zero.",
        "correct": "int result = 10 % 3;",
        "riddle": "Zero cannot divide.",
        "answer": "Use non-zero divisor."
    },
    {
        "id": "Q36",
        "title": "Wrong While Initialization",
        "broken": "int i;\nwhile(i < 3) {\n    System.out.println(i);\n    i++;\n}",
        "error": "Variable not initialized.",
        "correct": "int i = 0;\nwhile(i < 3) {\n    System.out.println(i);\n    i++;\n}",
        "riddle": "Start before you loop.",
        "answer": "Initialize i."
    },
    {
        "id": "Q37",
        "title": "Missing Default in Switch",
        "broken": "int x = 5;\nswitch(x) {\n    case 1:\n        System.out.println(\"One\");\n        break;\n}",
        "error": "No handling for other values.",
        "correct": "int x = 5;\nswitch(x) {\n    case 1:\n        System.out.println(\"One\");\n        break;\n    default:\n        System.out.println(\"Other\");\n}",
        "riddle": "Always prepare for the unexpected.",
        "answer": "Add default."
    },
    {
        "id": "Q38",
        "title": "Wrong Increment Position",
        "broken": "int i = 0;\nSystem.out.println(i++);\nSystem.out.println(i);",
        "error": "Logic Issue: Post-increment changes after printing.",
        "correct": "int i = 0;\nSystem.out.println(++i);",
        "riddle": "Increase before you show.",
        "answer": "Use pre-increment."
    },
    {
        "id": "Q39",
        "title": "Comparing Char and String",
        "broken": "char letter = 'A';\nif (letter.equals(\"A\")) {\n    System.out.println(\"Match\");\n}",
        "error": "Char has no equals method.",
        "correct": "char letter = 'A';\nif (letter == 'A') {\n    System.out.println(\"Match\");\n}",
        "riddle": "Characters compare with equality.",
        "answer": "Use ==."
    },
    {
        "id": "Q40",
        "title": "Wrong Loop Bound",
        "broken": "int[] arr = {1,2,3};\nfor(int i = 0; i <= arr.length; i++) {\n    System.out.println(arr[i]);\n}",
        "error": "<= causes out-of-bounds.",
        "correct": "int[] arr = {1,2,3};\nfor(int i = 0; i < arr.length; i++) {\n    System.out.println(arr[i]);\n}",
        "riddle": "Stop before the length.",
        "answer": "Use <."
    },
    {
        "id": "Q41",
        "title": "Missing Return in Boolean Method",
        "broken": "public static boolean check() {\n}",
        "error": "Must return boolean.",
        "correct": "public static boolean check() {\n    return true;\n}",
        "riddle": "A boolean must return truth or falsehood.",
        "answer": "Add return."
    },
    {
        "id": "Q42",
        "title": "Wrong Double Comparison",
        "broken": "double a = 0.1 + 0.2;\nif (a == 0.3) {\n    System.out.println(\"Equal\");\n}",
        "error": "Issue: Precision problem.",
        "correct": "double a = 0.1 + 0.2;\nif (Math.abs(a - 0.3) < 0.0001) {\n    System.out.println(\"Equal\");\n}",
        "riddle": "Decimals are rarely exact.",
        "answer": "Use tolerance."
    },
    {
        "id": "Q43",
        "title": "Using Unused Variable",
        "broken": "int x = 5;",
        "error": "Issue: Declared but unused.",
        "correct": "int x = 5;\nSystem.out.println(x);",
        "riddle": "Every declared value should serve purpose.",
        "answer": "Use the variable."
    },
    {
        "id": "Q44",
        "title": "Wrong Conditional Structure",
        "broken": "if (5 > 3)\n    System.out.println(\"Yes\");\nelse\n    System.out.println(\"No\");\n    System.out.println(\"Done\");",
        "error": "Issue: \"Done\" always runs.",
        "correct": "if (5 > 3) {\n    System.out.println(\"Yes\");\n} else {\n    System.out.println(\"No\");\n}\nSystem.out.println(\"Done\");",
        "riddle": "Structure defines behavior.",
        "answer": "Use braces."
    },
    {
        "id": "Q45",
        "title": "Wrong Data Type for Large Number",
        "broken": "int big = 3000000000;",
        "error": "Exceeds int limit.",
        "correct": "long big = 3000000000L;",
        "riddle": "Big numbers need bigger containers.",
        "answer": "Use long."
    },
    {
        "id": "Q46",
        "title": "Wrong String Method Name",
        "broken": "String name = \"Alex\";\nSystem.out.println(name.lenght());",
        "error": "Misspelled method.",
        "correct": "String name = \"Alex\";\nSystem.out.println(name.length());",
        "riddle": "Spelling matters in methods.",
        "answer": "Fix spelling."
    },
    {
        "id": "Q47",
        "title": "Missing Import for Scanner",
        "broken": "Scanner input = new Scanner(System.in);",
        "error": "Scanner not imported.",
        "correct": "import java.util.Scanner;\nScanner input = new Scanner(System.in);",
        "riddle": "Some tools must be imported first.",
        "answer": "Add import."
    },
    {
        "id": "Q48",
        "title": "Wrong Type in For-Each",
        "broken": "int[] nums = {1,2,3};\nfor(String n : nums) {\n    System.out.println(n);\n}",
        "error": "Type mismatch.",
        "correct": "int[] nums = {1,2,3};\nfor(int n : nums) {\n    System.out.println(n);\n}",
        "riddle": "Match the container type.",
        "answer": "Use int."
    },
    {
        "id": "Q49",
        "title": "Incorrect Ternary Syntax",
        "broken": "int x = 5;\nString result = x > 3 ? \"Big\";",
        "error": "Missing false expression.",
        "correct": "int x = 5;\nString result = x > 3 ? \"Big\" : \"Small\";",
        "riddle": "Ternary always has two paths.",
        "answer": "Add false value."
    },
    {
        "id": "Q50",
        "title": "Wrong Class Name Case",
        "broken": "public class myClass {\n}",
        "error": "Naming convention violation.",
        "correct": "public class MyClass {\n}",
        "riddle": "Class names begin with capital.",
        "answer": "Use PascalCase."
    }
]

def escape_swift_string(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

print("    private static func generateJavaLevel1Questions() -> [Question] {")
print("        var questions: [Question] = []")
print("")

for i, q in enumerate(questions_raw, 1):
    print(f"        questions.append(Question(")
    print(f"            title: \"Level 1 – Question {i}\",")
    print(f"            description: \"{escape_swift_string(q['error'])}\",")
    print(f"            initialCode: \"{escape_swift_string(q['broken'])}\",")
    print(f"            correctCode: \"{escape_swift_string(q['correct'])}\",")
    print(f"            difficulty: 1,")
    print(f"            riddle: \"{escape_swift_string(q['riddle'])}\",")
    print(f"            conceptExplanation: \"{escape_swift_string(q['answer'])}\",")
    print(f"            language: .java")
    print(f"        ))")

print("")
print("        return questions")
print("    }")
