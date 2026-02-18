
import re

raw_text = """
🔹 Q1 — Method Logic Not Returning Correct Value
Broken Code
public static int square(int n) {
    n * n;
}
Error: Expression not returned.
Correct Code
public static int square(int n) {
    return n * n;
}
Riddle: Calculation without return disappears.
Answer: Add return.

🔹 Q2 — Parameter Not Used
Broken Code
public static int doubleValue(int x) {
    return 2 * 5;
}
Error: Method ignores parameter.
Correct Code
public static int doubleValue(int x) {
    return 2 * x;
}
Riddle: Why accept input if you ignore it?
Answer: Use parameter.

🔹 Q3 — Nested Loop Wrong Inner Limit
Broken Code
for(int i = 0; i < 3; i++) {
    for(int j = 0; j < i; j++) {
        System.out.print("*");
    }
    System.out.println();
}
Issue: First row prints nothing.
Correct Code
for(int i = 1; i <= 3; i++) {
    for(int j = 0; j < i; j++) {
        System.out.print("*");
    }
    System.out.println();
}
Riddle: Start at one if you want the first star.
Answer: Adjust outer loop.

🔹 Q4 — Array Sum Missing Accumulator
Broken Code
int[] nums = {1,2,3,4};
for(int i = 0; i < nums.length; i++) {
    nums[i] += nums[i];
}
System.out.println(nums[0]);
Error: Modifying values instead of summing.
Correct Code
int sum = 0;
for(int i = 0; i < nums.length; i++) {
    sum += nums[i];
}
System.out.println(sum);
Riddle: To collect total, use a container.
Answer: Use accumulator variable.

🔹 Q5 — Input Not Read Properly
Broken Code
Scanner sc = new Scanner(System.in);
int age;
System.out.println("Enter age:");
System.out.println(age);
Error: Value never read.
Correct Code
Scanner sc = new Scanner(System.in);
System.out.println("Enter age:");
int age = sc.nextInt();
System.out.println(age);
Riddle: Ask, then receive.
Answer: Use nextInt().

🔹 Q6 — Method Calling Itself Without Stop
Broken Code
public static void loop() {
    loop();
}
Error: Infinite recursion.
Correct Code
public static void loop(int n) {
    if(n == 0) return;
    loop(n - 1);
}
Riddle: Even recursion needs a stopping rule.
Answer: Add base case.

🔹 Q7 — 2D Array Wrong Column Access
Broken Code
int[][] grid = {
    {1,2},
    {3,4}
};
System.out.println(grid[2][0]);
Error: Row index out of bounds.
Correct Code
System.out.println(grid[1][0]);
Riddle: Two rows mean index 0 and 1.
Answer: Fix index.

🔹 Q8 — Method Returns Wrong Logic
Broken Code
public static boolean isEven(int n) {
    if(n % 2 == 0)
        return false;
    else
        return true;
}
Error: Logic reversed.
Correct Code
public static boolean isEven(int n) {
    return n % 2 == 0;
}
Riddle: Even numbers divide without remainder.
Answer: Fix condition.

🔹 Q9 — Nested Loop Printing Wrong Shape
Broken Code
for(int i = 0; i < 3; i++) {
    for(int j = 0; j < 3; j++) {
        System.out.print(i);
    }
    System.out.println();
}
Issue: Prints row number instead of pattern.
Correct Code
for(int i = 0; i < 3; i++) {
    for(int j = 0; j < 3; j++) {
        System.out.print("*");
    }
    System.out.println();
}
Riddle: Shape needs symbol, not counter.
Answer: Print "*".

🔹 Q10 — Searching Array Wrong Condition
Broken Code
int[] arr = {4,7,9};
int target = 7;
for(int i = 0; i < arr.length; i++) {
    if(arr[i] != target) {
        System.out.println("Found");
    }
}
Error: Wrong comparison operator.
Correct Code
for(int i = 0; i < arr.length; i++) {
    if(arr[i] == target) {
        System.out.println("Found");
        break;
    }
}
Riddle: Found only when equal.
Answer: Use ==.

🔹 Q11 — Finding Maximum (Wrong Initial Value)
Broken Code
int[] arr = {5, 9, 3, 12, 4};
int max = 0;
for(int i = 0; i < arr.length; i++) {
    if(arr[i] > max) {
        max = arr[i];
    }
}
System.out.println(max);
Error: Fails if all numbers are negative.
Correct Code
int max = arr[0];
for(int i = 1; i < arr.length; i++) {
    if(arr[i] > max) {
        max = arr[i];
    }
}
System.out.println(max);
Riddle: The first element is the safest starting point.
Answer: Initialize with arr[0].

🔹 Q12 — Counting Even Numbers (Wrong Condition)
Broken Code
int count = 0;
for(int n : arr) {
    if(n % 2 == 1) {
        count++;
    }
}
System.out.println(count);
Error: Counts odd numbers instead of even.
Correct Code
if(n % 2 == 0) {
    count++;
}
Riddle: Even numbers leave no remainder.
Answer: Use % 2 == 0.

🔹 Q13 — Reversing Array (Wrong Swap)
Broken Code
for(int i = 0; i < arr.length; i++) {
    arr[i] = arr[arr.length - 1 - i];
}
Error: Overwrites values, no proper swap.
Correct Code
for(int i = 0; i < arr.length / 2; i++) {
    int temp = arr[i];
    arr[i] = arr[arr.length - 1 - i];
    arr[arr.length - 1 - i] = temp;
}
Riddle: To swap, use a temporary hand.
Answer: Use temp variable.

🔹 Q14 — Input Validation Missing Loop
Broken Code
Scanner sc = new Scanner(System.in);
int number = sc.nextInt();
System.out.println(number);
Issue: Accepts negative when only positive allowed.
Correct Code
int number;
do {
    number = sc.nextInt();
} while(number < 0);
Riddle: Validate until correct.
Answer: Use do-while.

🔹 Q15 — Method Not Returning After Condition
Broken Code
public static int abs(int n) {
    if(n < 0)
        n = -n;
}
Error: Missing return statement.
Correct Code
public static int abs(int n) {
    if(n < 0)
        n = -n;
    return n;
}
Riddle: Modified value must be returned.
Answer: Add return.

🔹 Q16 — 2D Array Sum (Wrong Loop Limit)
Broken Code
int sum = 0;
for(int i = 0; i < grid.length; i++) {
    for(int j = 0; j < grid.length; j++) {
        sum += grid[i][j];
    }
}
Error: Inner loop should use column length.
Correct Code
for(int i = 0; i < grid.length; i++) {
    for(int j = 0; j < grid[i].length; j++) {
        sum += grid[i][j];
    }
}
Riddle: Rows may not equal columns.
Answer: Use grid[i].length.

🔹 Q17 — Prime Check Logic Wrong
Broken Code
public static boolean isPrime(int n) {
    for(int i = 2; i < n; i++) {
        if(n % i == 0)
            return true;
    }
    return false;
}
Error: Logic reversed.
Correct Code
public static boolean isPrime(int n) {
    if(n <= 1) return false;
    for(int i = 2; i < n; i++) {
        if(n % i == 0)
            return false;
    }
    return true;
}
Riddle: A prime has no divisors except 1 and itself.
Answer: Reverse return logic.

🔹 Q18 — Nested Loop Wrong Break
Broken Code
for(int i = 0; i < arr.length; i++) {
    for(int j = 0; j < arr.length; j++) {
        if(arr[i] == arr[j]) {
            break;
        }
    }
}
Issue: Break exits only inner loop.
Correct Code
outer:
for(int i = 0; i < arr.length; i++) {
    for(int j = 0; j < arr.length; j++) {
        if(arr[i] == arr[j]) {
            break outer;
        }
    }
}
Riddle: Sometimes you must break both levels.
Answer: Use labeled break.

🔹 Q19 — Factorial Logic Wrong
Broken Code
int fact = 0;
for(int i = 1; i <= n; i++) {
    fact *= i;
}
Error: Factorial must start at 1.
Correct Code
int fact = 1;
for(int i = 1; i <= n; i++) {
    fact *= i;
}
Riddle: Multiplication starts with one.
Answer: Initialize to 1.

🔹 Q20 — Average Calculation Wrong Type
Broken Code
int sum = 15;
int count = 4;
double avg = sum / count;
Error: Integer division before assignment.
Correct Code
double avg = (double) sum / count;
Riddle: Cast before dividing.
Answer: Use (double).

🔹 Q21 — Linear Search Returns Too Early
Broken Code
public static boolean contains(int[] arr, int target) {
    for(int i = 0; i < arr.length; i++) {
        if(arr[i] == target)
            return true;
        else
            return false;
    }
    return false;
}
Error: Returns false after first mismatch.
Correct Code
for(int i = 0; i < arr.length; i++) {
    if(arr[i] == target)
        return true;
}
return false;
Riddle: Search entire list before giving up.
Answer: Remove early false.

🔹 Q22 — Nested Loop Pattern Wrong Line Break
Broken Code
for(int i = 1; i <= 3; i++) {
    for(int j = 1; j <= i; j++) {
        System.out.println("*");
    }
}
Error: Prints vertically instead of triangle.
Correct Code
for(int i = 1; i <= 3; i++) {
    for(int j = 1; j <= i; j++) {
        System.out.print("*");
    }
    System.out.println();
}
Riddle: Use print for same line.
Answer: Replace println with print inside loop.

🔹 Q23 — Duplicate Detection Wrong Logic
Broken Code
boolean duplicate = false;
for(int i = 0; i < arr.length; i++) {
    for(int j = 0; j < arr.length; j++) {
        if(arr[i] == arr[j]) {
            duplicate = true;
        }
    }
}
Error: Every element equals itself.
Correct Code
for(int i = 0; i < arr.length; i++) {
    for(int j = i + 1; j < arr.length; j++) {
        if(arr[i] == arr[j]) {
            duplicate = true;
        }
    }
}
Riddle: Don't compare element with itself.
Answer: Start inner loop at i + 1.

🔹 Q24 — Fibonacci Wrong Update Order
Broken Code
int a = 0, b = 1;
for(int i = 0; i < n; i++) {
    a = b;
    b = a + b;
}
Error: Overwrites needed value.
Correct Code
int temp = a + b;
a = b;
b = temp;
Riddle: Save before replacing.
Answer: Use temp variable.

🔹 Q25 — Method Calls Itself Incorrectly
Broken Code
public static int countdown(int n) {
    System.out.println(n);
    return countdown(n - 1);
}
Error: No stopping condition.
Correct Code
public static int countdown(int n) {
    if(n == 0) return 0;
    System.out.println(n);
    return countdown(n - 1);
}
Riddle: Every recursion must end.
Answer: Add base case.

🔹 Q26 — Bubble Sort Wrong Inner Limit
Broken Code
for(int i = 0; i < arr.length; i++) {
    for(int j = 0; j < arr.length; j++) {
        if(arr[j] > arr[j + 1]) {
            int temp = arr[j];
            arr[j] = arr[j + 1];
            arr[j + 1] = temp;
        }
    }
}
Error: j + 1 can go out of bounds.
Correct Code
for(int i = 0; i < arr.length - 1; i++) {
    for(int j = 0; j < arr.length - 1 - i; j++) {
        if(arr[j] > arr[j + 1]) {
            int temp = arr[j];
            arr[j] = arr[j + 1];
            arr[j + 1] = temp;
        }
    }
}
Riddle: Stop before the edge.
Answer: Limit inner loop.

🔹 Q27 — Selection Sort Wrong Swap Position
Broken Code
for(int i = 0; i < arr.length; i++) {
    int min = 0;
    for(int j = i + 1; j < arr.length; j++) {
        if(arr[j] < arr[min]) {
            min = j;
        }
    }
}
Error: min must start at i.
Correct Code
int min = i;
Riddle: Start searching from your current index.
Answer: Initialize min to i.

🔹 Q28 — Counting Frequency (Wrong Index)
Broken Code
int[] freq = new int[10];
for(int i = 0; i < arr.length; i++) {
    freq[i]++;
}
Error: Should increment based on value.
Correct Code
freq[arr[i]]++;
Riddle: Count the value, not the position.
Answer: Use arr[i] as index.

🔹 Q29 — Matrix Diagonal Sum Wrong Condition
Broken Code
int sum = 0;
for(int i = 0; i < matrix.length; i++) {
    for(int j = 0; j < matrix[i].length; j++) {
        if(i != j) {
            sum += matrix[i][j];
        }
    }
}
Error: Condition reversed.
Correct Code
if(i == j) {
    sum += matrix[i][j];
}
Riddle: Diagonal meets when row equals column.
Answer: Use i == j.

🔹 Q30 — Reverse String Builder Wrong Insert
Broken Code
String reversed = "";
for(int i = 0; i < str.length(); i++) {
    reversed += str.charAt(i);
}
Error: Not reversing.
Correct Code
for(int i = str.length() - 1; i >= 0; i--) {
    reversed += str.charAt(i);
}
Riddle: Start from the end.
Answer: Loop backwards.

🔹 Q31 — Palindrome Check Wrong Logic
Broken Code
boolean isPalindrome = true;
for(int i = 0; i < str.length(); i++) {
    if(str.charAt(i) != str.charAt(i)) {
        isPalindrome = false;
    }
}
Error: Comparing same index.
Correct Code
for(int i = 0; i < str.length() / 2; i++) {
    if(str.charAt(i) != str.charAt(str.length() - 1 - i)) {
        isPalindrome = false;
        break;
    }
}
Riddle: Compare opposite ends.
Answer: Mirror index.

🔹 Q32 — Binary Search Wrong Mid
Broken Code
int mid = (low + high);
Error: Not dividing by 2.
Correct Code
int mid = (low + high) / 2;
Riddle: Middle requires division.
Answer: Divide by 2.

🔹 Q33 — Binary Search Infinite Loop
Broken Code
while(low < high) {
    int mid = (low + high) / 2;
    if(arr[mid] < target)
        low = mid;
    else
        high = mid;
}
Error: Boundaries not updated correctly.
Correct Code
if(arr[mid] < target)
    low = mid + 1;
else
    high = mid - 1;
Riddle: Move past the middle.
Answer: Use ±1.

🔹 Q34 — Counting Vowels Wrong Condition
Broken Code
if(c == 'a' && c == 'e' && c == 'i' && c == 'o' && c == 'u')
Error: Character cannot equal all vowels.
Correct Code
if(c == 'a' || c == 'e' || c == 'i' || c == 'o' || c == 'u')
Riddle: A letter can be one vowel, not all.
Answer: Use OR.

🔹 Q35 — Remove Duplicates Wrong Loop Range
Broken Code
for(int i = 0; i < arr.length; i++) {
    for(int j = 0; j < arr.length; j++) {
Error: Should compare only ahead.
Correct Code
for(int i = 0; i < arr.length; i++) {
    for(int j = i + 1; j < arr.length; j++) {
Riddle: Compare forward, not backward.
Answer: Start j at i+1.

🔹 Q36 — Count Digits Wrong Update
Broken Code
while(n > 0) {
    count++;
}
Error: n never changes.
Correct Code
while(n > 0) {
    n /= 10;
    count++;
}
Riddle: Remove digits one by one.
Answer: Divide by 10.

🔹 Q37 — Sum of Digits Wrong Operator
Broken Code
sum += n / 10;
Error: Should use remainder.
Correct Code
sum += n % 10;
Riddle: Last digit comes from remainder.
Answer: Use %.

🔹 Q38 — Armstrong Number Wrong Power
Broken Code
sum += digit * digit;
Error: Should raise to power of number of digits.
Correct Code
sum += Math.pow(digit, digits);
Riddle: Power depends on digit count.
Answer: Use exponent.

🔹 Q39 — Merge Two Arrays Wrong Index
Broken Code
merged[i] = arr2[i];
Error: Overwrites arr1 values.
Correct Code
merged[arr1.length + i] = arr2[i];
Riddle: Offset the second array.
Answer: Add length offset.

🔹 Q40 — Matrix Transpose Wrong Assignment
Broken Code
transpose[i][j] = matrix[i][j];
Error: No swap.
Correct Code
transpose[j][i] = matrix[i][j];
Riddle: Swap row and column.
Answer: Reverse indices.

🔹 Q41 — Find Second Largest Wrong Logic
Broken Code
int second = 0;
for(int n : arr) {
    if(n > second) {
        second = n;
    }
}
Error: Finds max, not second max.
Correct Code
int first = Integer.MIN_VALUE;
int second = Integer.MIN_VALUE;
for(int n : arr) {
    if(n > first) {
        second = first;
        first = n;
    } else if(n > second && n != first) {
        second = n;
    }
}
Riddle: Track two champions.
Answer: Maintain first and second.

🔹 Q42 — Rotate Array Wrong Direction
Broken Code
arr[0] = arr[arr.length - 1];
Error: Overwrites without shifting.
Correct Code
int last = arr[arr.length - 1];
for(int i = arr.length - 1; i > 0; i--) {
    arr[i] = arr[i - 1];
}
arr[0] = last;
Riddle: Shift before replacing.
Answer: Store last first.

🔹 Q43 — Check Sorted Wrong Comparison
Broken Code
if(arr[i] < arr[i + 1])
    return false;
Error: Reversed condition.
Correct Code
if(arr[i] > arr[i + 1])
    return false;
Riddle: Sorted means never decreasing.
Answer: Reverse comparison.

🔹 Q44 — Anagram Check Wrong Length Validation
Broken Code
if(str1.length() != str1.length())
    return false;
Error: Comparing same string.
Correct Code
if(str1.length() != str2.length())
    return false;
Riddle: Compare both lengths.
Answer: Use str2.

🔹 Q45 — GCD Wrong Loop Range
Broken Code
for(int i = 1; i <= a; i++)
Error: Should go until min(a, b).
Correct Code
for(int i = 1; i <= Math.min(a, b); i++)
Riddle: GCD limited by smaller number.
Answer: Use min.

🔹 Q46 — LCM Wrong Formula
Broken Code
int lcm = a * b;
Error: Missing division by gcd.
Correct Code
int lcm = (a * b) / gcd(a, b);
Riddle: Multiply, then divide by GCD.
Answer: Use formula.

🔹 Q47 — Power Calculation Wrong Loop
Broken Code
for(int i = 0; i <= exp; i++) {
    result *= base;
}
Error: One extra multiplication.
Correct Code
for(int i = 0; i < exp; i++) {
    result *= base;
}
Riddle: Multiply exactly exponent times.
Answer: Use <.

🔹 Q48 — Missing Reset in Nested Count
Broken Code
int count = 0;
for(int i = 0; i < arr.length; i++) {
    for(int j = 0; j < arr.length; j++) {
        if(arr[i] == arr[j])
            count++;
    }
}
Error: Count never resets per element.
Correct Code
for(int i = 0; i < arr.length; i++) {
    int count = 0;
    for(int j = 0; j < arr.length; j++) {
        if(arr[i] == arr[j])
            count++;
    }
}
Riddle: Reset before counting each value.
Answer: Move count inside outer loop.

🔹 Q49 — Spiral Matrix Wrong Direction Change
Broken Code
left++;
right--;
Error: Both boundaries updated at once.
Correct Code
top++;
...
right--;
...
bottom--;
...
left++;
Riddle: Update boundary after finishing side.
Answer: Adjust one side at a time.

🔹 Q50 — Missing Return After Recursion Branch
Broken Code
if(n <= 1)
    return n;
fib(n - 1) + fib(n - 2);
Error: Missing return keyword.
Correct Code
return fib(n - 1) + fib(n - 2);
Riddle: Recursive sum must be returned.
Answer: Add return.
"""

def escape_swift_string(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

# Regex to split units starting with 🔹 Q and some number
units = re.split(r'🔹 Q\d+ — ', raw_text)[1:]

print("    private static func generateJavaLevel2Questions() -> [Question] {")
print("        var questions: [Question] = []")
print("")

for i, unit in enumerate(units, 1):
    lines = unit.strip().split('\n')
    title = lines[0].strip()
    
    # Extract sections
    broken_start = -1
    error_start = -1
    correct_start = -1
    riddle_start = -1
    answer_start = -1
    
    for idx, line in enumerate(lines):
        if line.startswith("Broken Code"): broken_start = idx
        elif line.startswith("Error:") or line.startswith("Issue:"): error_start = idx
        elif line.startswith("Correct Code"): correct_start = idx
        elif line.startswith("Riddle:"): riddle_start = idx
        elif line.startswith("Answer:"): answer_start = idx

    broken_lines = lines[broken_start+1:error_start]
    broken = "\n".join(broken_lines).strip()
    error = lines[error_start].split(':', 1)[1].strip()
    correct_lines = lines[correct_start+1:riddle_start]
    correct = "\n".join(correct_lines).strip()
    riddle = lines[riddle_start].split(':', 1)[1].strip()
    answer = lines[answer_start].split(':', 1)[1].strip()

    print(f"        questions.append(Question(")
    print(f"            title: \"Level 2 – Question {i}\",")
    print(f"            description: \"{escape_swift_string(error)}\",")
    print(f"            initialCode: \"{escape_swift_string(broken)}\",")
    print(f"            correctCode: \"{escape_swift_string(correct)}\",")
    print(f"            difficulty: 2,")
    print(f"            riddle: \"{escape_swift_string(riddle)}\",")
    print(f"            conceptExplanation: \"{escape_swift_string(answer)}\",")
    print(f"            language: .java")
    print(f"        ))")

print("")
print("        return questions")
print("    }")
