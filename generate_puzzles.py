import re
import sys

def parse_puzzles(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    puzzles = []
    current_puzzle = {}
    
    # We will identify sections by headers
    # Headers: 
    # Title (starts with emoji/number)
    # Question: 
    # Broken Code
    # Error
    # Correct Code
    # Riddle
    
    section = None
    buffer = []
    
    def save_section():
        if section and buffer:
            content = "".join(buffer).strip()
            current_puzzle[section] = content
            buffer.clear()
            
    for line in lines:
        stripped = line.strip()
        
        # Check for headers
        if stripped.startswith("Question:"):
            # Title was the previous section (or lines before this)
            # Actually, the lines before "Question:" are the title.
            # But we might have been in "Riddle" of previous puzzle.
            # So if we hit "Question:", we are definitely in a new puzzle's body, 
            # and the lines since the last "Riddle" ended are the Title.
            
            # This logic is tricky. 
            # stricter approach:
            pass

    # improving parsing strategy: using text.split based on "Question:"
    content = "".join(lines)
    # Split by "Question:"
    # The first chunk is title of puzzle 1 (and maybe junk at start).
    # subsequent chunks: [Description]... [Next Title]
    
    # Let's try splitting by the pattern of the title.
    # The titles are "1️⃣ ...", "2️⃣ ...", "1️⃣0️⃣ ..."
    # We can split by `\n[0-9️⃣]+.*\n`
    
    # Updated parsing logic: Split by puzzle start
    # Pattern to find the start of a puzzle: 
    # Starts with emoji number, then newline(s) then "Question:"
    
    start_pattern = r"(?:[0-9️⃣🔟]+)[^\n]*\n+Question:"
    
    # helper to find all start indices
    starts = [m.start() for m in re.finditer(start_pattern, content)]
    
    if not starts:
        print("No start patterns found!")
        return

    # Add end of file
    starts.append(len(content))
    
    puzzle_blocks = []
    for i in range(len(starts) - 1):
        puzzle_blocks.append(content[starts[i]:starts[i+1]])
        
    print(f"Found {len(puzzle_blocks)} puzzle blocks.")
    
    swift_code = "static let allPuzzles: [Puzzle] = [\n"
    
    for i, block in enumerate(puzzle_blocks):
        try:
            # Parse individual block
            # 1. Title (first line)
            lines = block.split('\n')
            raw_title = lines[0].strip()
            # Clean title
            clean_title = re.sub(r'^[0-9️⃣🔟]+', '', raw_title).strip()
            title = f"Level {i+1}: {clean_title}"
            
            # 2. Description (Question)
            # Find "Question:"
            q_match = re.search(r'Question:\s*(.*)', block)
            description = q_match.group(1).strip() if q_match else "Fix the code."
            
            # 3. Broken Code
            # From "Broken Code" to "Error" or "Correct Code"
            # Find positions
            bc_start = re.search(r'\nBroken Code\n', block)
            error_start = re.search(r'\nError\n', block)
            cc_start = re.search(r'\nCorrect Code\n', block)
            
            initial_code = ""
            error_msg = ""
            
            if bc_start:
                start_idx = bc_start.end()
                end_idx = error_start.start() if error_start else (cc_start.start() if cc_start else len(block))
                initial_code = block[start_idx:end_idx].strip()
                
            # 4. Error (Optional)
            if error_start:
                start_idx = error_start.end()
                end_idx = cc_start.start() if cc_start else len(block)
                error_msg = block[start_idx:end_idx].strip()
            else:
                # If no error section, maybe use a default or check if "Error" is in description
                # User's logic: some puzzles don't have Error section.
                error_msg = "Logic Error / Unexpected Behavior"
                
            # 5. Correct Code
            correct_code = ""
            riddle_start = re.search(r'\nRiddle\n', block)
            
            if cc_start:
                start_idx = cc_start.end()
                end_idx = riddle_start.start() if riddle_start else len(block)
                correct_code = block[start_idx:end_idx].strip()
                
            # 6. Riddle
            riddle = ""
            if riddle_start:
                riddle = block[riddle_start.end():].strip()
            
            # Escape for swift
            def esc(s):
                return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
                
            story = f"System Error: {esc(error_msg)}"
            
            swift_code += f"        Puzzle(\n"
            swift_code += f"            title: \"{esc(title)}\",\n"
            swift_code += f"            description: \"{esc(description)}\",\n"
            swift_code += f"            initialCode: \"{esc(initial_code)}\",\n"
            swift_code += f"            correctCode: \"{esc(correct_code)}\",\n"
            swift_code += f"            difficulty: 1,\n"
            swift_code += f"            hints: [\"{esc(riddle)}\"],\n"
            swift_code += f"            storyFragment: \"{story}\",\n"
            swift_code += f"            locked: {'false' if i == 0 else 'true'}\n"
            swift_code += f"        ),\n"
            
        except Exception as e:
            print(f"Error parsing block {i}: {e}")
            
    swift_code += "    ]"
    
    with open('puzzles_swift.txt', 'w') as f:
        f.write(swift_code)
        
    print("Generated code written to puzzles_swift.txt")
    
    if len(matches) == 0:
        print("NO MATCHES FOUND. Debugging...")
        print(content[:500])
    
    with open('puzzles_swift.txt', 'w') as f:
        f.write(swift_code)
        
    print("Generated code written to puzzles_swift.txt")

if __name__ == "__main__":
    parse_puzzles("puzzles.txt")
