#!/usr/bin/env python3
"""
Script to fix all JWT decorators in profile.py
"""

import re

def fix_jwt_decorators():
    file_path = r"e:\AppProjects\CampusNet Update\CampusNet\backend\routes\profile.py"
    
    # Read the file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace @token_required with @jwt_required()
    content = re.sub(r'@token_required\n', '@jwt_required()\n', content)
    
    # Replace function signatures that have current_user_id parameter
    # Pattern: def function_name(current_user_id):
    content = re.sub(r'def (\w+)\(current_user_id\):', r'def \1():', content)
    
    # Add current_user_id = get_jwt_identity() at the start of each function
    # Find function definitions and add the line
    functions_to_fix = [
        'delete_achievement', 'get_skills', 'add_skill', 'update_skill', 
        'delete_skill', 'generate_cv'
    ]
    
    for func_name in functions_to_fix:
        # Pattern to find function and add get_jwt_identity call
        pattern = f'(def {func_name}\(\):\s*\n\s*"""[^"]*"""\s*\n\s*try:\s*\n)'
        replacement = f'\\1        current_user_id = get_jwt_identity()\n        '
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)
    
    # Fix Profile() constructor calls
    content = re.sub(r'Profile\(user_id=current_user_id\)', 'Profile()', content)
    
    # Fix Achievement() constructor calls  
    content = re.sub(r'Achievement\(\s*profile_id=([^,\)]+),([^)]+)\)', 
                    lambda m: f'Achievement()', content)
    
    # Fix Skill() constructor calls
    content = re.sub(r'Skill\(\s*profile_id=([^,\)]+),([^)]+)\)', 
                    lambda m: f'Skill()', content)
    
    # Write back the file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("Fixed JWT decorators and function signatures")

if __name__ == "__main__":
    fix_jwt_decorators()
