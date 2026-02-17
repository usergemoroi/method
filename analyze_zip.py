#!/usr/bin/env python3
import zipfile
import os

zip_path = 'GameBlaster-Pro_3.1_Final.zip'

print(f"Analyzing: {zip_path}")
print(f"Current directory: {os.getcwd()}")

try:
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        files = zip_ref.namelist()
        print(f"\nTotal files: {len(files)}")
        
        # Look for any files that might be invitations
        invitation_keywords = ['invite', 'invitation', 'welcome', 'hello', 'readme', 'author', 'credit']
        
        for name in sorted(files):
            lower_name = name.lower()
            if any(keyword in lower_name for keyword in invitation_keywords):
                print(f"\n--- POTENTIAL INVITATION FILE: {name} ---")
                try:
                    content = zip_ref.read(name)
                    # Try to decode as text
                    try:
                        text_content = content.decode('utf-8', errors='ignore')
                        print(f"Content:\n{text_content[:2000]}")
                    except:
                        print(f"Binary file, size: {len(content)} bytes")
                except Exception as e:
                    print(f"Error reading: {e}")

except Exception as e:
    print(f"Error: {e}")
