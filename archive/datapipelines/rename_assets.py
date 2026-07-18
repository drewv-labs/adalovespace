import os
import re

root_dir = '/Users/drew/Library/Mobile Documents/com~apple~CloudDocs/Astrophotography/'

def sanitize_name(name):
    # Rule 1: Replace spaces, parentheses, colons, and commas with underscores
    sanitized = re.sub(r'[ ():,]', '_', name)
    # Rule 2: Ensure there are no double underscores
    sanitized = re.sub(r'_+', '_', sanitized)
    return sanitized

def rename_recursive(base_path):
    changes = []
    # Rule 3: Handle directory renaming bottom-up
    for root, dirs, files in os.walk(base_path, topdown=False):
        # Process files
        for name in files:
            # Rule 4: Avoid renaming hidden files
            if name.startswith('.'):
                continue
            
            new_name = sanitize_name(name)
            if new_name != name:
                old_path = os.path.join(root, name)
                new_path = os.path.join(root, new_name)
                
                # Handle potential collisions
                if os.path.exists(new_path) and old_path != new_path:
                    print(f"Collision detected: {new_path}. Skipping {old_path}")
                    continue
                
                os.rename(old_path, new_path)
                changes.append(f"FILE: {old_path} -> {new_name}")

        # Process directories
        for name in dirs:
            # Rule 4: Avoid renaming hidden directories
            if name.startswith('.'):
                continue
            
            new_name = sanitize_name(name)
            if new_name != name:
                old_path = os.path.join(root, name)
                new_path = os.path.join(root, new_name)
                
                # Handle potential collisions
                if os.path.exists(new_path) and old_path != new_path:
                    print(f"Collision detected: {new_path}. Skipping {old_path}")
                    continue
                
                os.rename(old_path, new_path)
                changes.append(f"DIR: {old_path} -> {new_name}")
    
    return changes

if __name__ == "__main__":
    print(f"Starting renaming process in {root_dir}...")
    all_changes = rename_recursive(root_dir)
    print(f"Finished. Total changes: {len(all_changes)}")
    for change in all_changes:
        print(change)
