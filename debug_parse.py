import re

file_path = '/Users/student/Downloads/debugg lb copy.swiftpm/questions_raw.txt'

with open(file_path, 'r') as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
for i, line in enumerate(lines[:50]):
    print(f"Line {i}: {repr(line)}")
    match = re.match(r'^(Q\d+).*?([A-Za-z].+)$', line.strip())
    if match:
        print(f"  MATCH: {match.groups()}")
    else:
        print("  NO MATCH")
