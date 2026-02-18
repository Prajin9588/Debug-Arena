import re
import os

def parse_questions(file_path):
    if not os.path.exists(file_path):
        print(f"Error: File not found at {file_path}")
        return

    with open(file_path, 'r') as f:
        content = f.read()

    # Regex to find starting headers like 'Q1 — Print Statement Typo'
    # Use simple split or updated regex
    # The - char might be varying.
    
    # Relaxed regex: Start with Q<digits>, optional separator, capture rest
    matches = list(re.finditer(r'^(Q\d+).*?([A-Za-z].+)$', content, re.MULTILINE))

    if not matches:
        print("No matches found for question pattern.")
        # Debug: print first few lines
        print("First 500 chars:")
        print(content[:500])
        return

    questions = []

    for i, match in enumerate(matches):
        start = match.end()
        end = matches[i+1].start() if i + 1 < len(matches) else len(content)
        
        q_identifier = match.group(1) # Q1
        q_title_suffix = match.group(2).strip() 
        
        body = content[start:end]
        
        fields = {}
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
        
        current_header = None
        current_content = []
        
        lines = body.split('\n')
        for line in lines:
            line_stripped = line.strip()
            # Check if line is a header
            is_header = False
            for h in headers_map:
                # Close match check
                if line_stripped.replace('\\', '') == h or h in line_stripped:
                     # exact match or starts with
                    if line_stripped.startswith(h):
                        if current_header:
                            fields[headers_map[current_header]] = '\n'.join(current_content).strip()
                        current_header = h
                        current_content = []
                        is_header = True
                        break
            
            if not is_header:
                if current_header:
                    current_content.append(line)
        
        if current_header:
            fields[headers_map[current_header]] = '\n'.join(current_content).strip()
            
        questions.append({
            'identifier': q_identifier,
            'title': f'Level 1 – Question {q_identifier[1:]}', 
            'description': fields.get('description', ''),
            'initialCode': fields.get('initialCode', ''),
            'correctCode': fields.get('correctCode', ''),
            'riddle': fields.get('riddle', ''),
            'conceptExplanation': fields.get('conceptExplanation', ''),
            'expectedPatterns': fields.get('expectedPatterns', ''),
        })

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
            lines = regex_raw.split('\n')
            for l in lines:
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

parse_questions('/Users/student/Downloads/debugg lb copy.swiftpm/questions_raw.txt')
