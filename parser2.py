print("SCRIPT STARTED")
import os

file_path = '/Users/student/Downloads/debugg lb copy.swiftpm/questions_raw.txt'
print(f"Reading {file_path}")

if not os.path.exists(file_path):
    print("File not found")
    exit(1)

with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print(f"Read {len(lines)} lines")

questions = []
# Headers map
headers_map = {
    'Broken Code': 'initialCode',
    'Error': 'description',
    'Correct Code': 'correctCode',
    'Riddle': 'riddle',
    'Hidden Test Cases (Logic-validated)': 'hiddenTests',
    'Logic Rule': 'conceptExplanation',
    'Regex / Token Rules': 'expectedPatterns',
    'Answer': 'answer' 
}

def is_question_header(line):
    # Q1 — ...
    if line.startswith('Q') and len(line) > 1 and line[1].isdigit():
        return True
    return False

# First pass: identify question blocks
q_starts = []
for i, line in enumerate(lines):
    if is_question_header(line):
        q_starts.append(i)

print(f"Found {len(q_starts)} questions")

if not q_starts:
    exit(0)

for i in range(len(q_starts)):
    start_idx = q_starts[i]
    end_idx = q_starts[i+1] if i+1 < len(q_starts) else len(lines)
    
    header_line = lines[start_idx].strip()
    parts = header_line.split(' ', 2) # Q1, -, Title...
    q_id = parts[0]
    
    title_start = 0
    for char_i, char in enumerate(header_line):
        if char_i > len(q_id) and char.isalpha():
            title_start = char_i
            break
    q_title_suffix = header_line[title_start:] if title_start > 0 else "Unknown"
    
    body_lines = lines[start_idx+1:end_idx]
    
    fields = {}
    current_header = None
    current_content = []

    for line in body_lines:
        line_stripped = line.strip()
        is_header = False
        for h in headers_map:
            if line_stripped.startswith(h) and len(line_stripped) <= len(h) + 5: 
                if current_header:
                    fields[headers_map[current_header]] = '\n'.join(current_content).strip()
                current_header = h
                current_content = []
                is_header = True
                break
        
        if not is_header:
            if current_header:
                current_content.append(line.rstrip())
    
    if current_header:
        fields[headers_map[current_header]] = '\n'.join(current_content).strip()
        
    questions.append({
        'identifier': q_id,
        'title': f'Level 1 – Question {q_id[1:]}',
        'description': fields.get('description', ''),
        'initialCode': fields.get('initialCode', ''),
        'correctCode': fields.get('correctCode', ''),
        'riddle': fields.get('riddle', ''),
        'conceptExplanation': fields.get('conceptExplanation', ''),
        'expectedPatterns': fields.get('expectedPatterns', ''),
    })

# Generate Swift
swift_code = []
swift_code.append('    private static func generateLevel1Questions(for language: Language) -> [Question] {')
swift_code.append('        var questions: [Question] = []')
swift_code.append('')
swift_code.append('        if language == .swift {')

for q in questions:
    def escape_swift_string(s):
        return s.replace('\\', '\\\\').replace('\"', '\\\"').replace('\n', '\\n')
        
    title = q['title']
    desc = escape_swift_string(q['description'])
    init_code = escape_swift_string(q['initialCode'])
    corr_code = escape_swift_string(q['correctCode'])
    riddle = escape_swift_string(q['riddle'])
    concept = escape_swift_string(q['conceptExplanation'])
    
    regex_raw = q['expectedPatterns']
    regex_list = []
    if regex_raw:
        rlines = regex_raw.split('\n')
        for l in rlines:
            if l.strip():
                    regex_list.append(f'\"{escape_swift_string(l.strip())}\"')
    
    regex_str = '[' + ', '.join(regex_list) + ']'
    
    swift_code.append('            questions.append(Question(')
    swift_code.append(f'                title: \"{title}\",')
    swift_code.append(f'                description: \"{desc}\",')
    swift_code.append(f'                initialCode: \"{init_code}\",')
    swift_code.append(f'                correctCode: \"{corr_code}\",')
    swift_code.append(f'                difficulty: 1,')
    swift_code.append(f'                riddle: \"{riddle}\",')
    swift_code.append(f'                conceptExplanation: \"{concept}\",')
    swift_code.append(f'                language: .swift,')
    swift_code.append(f'                expectedPatterns: {regex_str}')
    swift_code.append('            ))')
    
swift_code.append('        }')
swift_code.append('        return questions')
swift_code.append('    }')

print('\n'.join(swift_code))
