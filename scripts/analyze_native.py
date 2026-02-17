#!/usr/bin/env python3
"""
Анализ и патчинг native библиотеки libclient.so
Находит функции check и licence, патчит их для возврата true
"""

import sys
import struct
import os
from pathlib import Path

def find_string(data, string):
    """Найти все вхождения строки в бинарных данных"""
    pattern = string.encode('utf-8')
    positions = []
    start = 0
    while True:
        pos = data.find(pattern, start)
        if pos == -1:
            break
        positions.append(pos)
        start = pos + 1
    return positions

def find_function_references(data, string_offset):
    """
    Найти функции, которые ссылаются на строку по офсету
    В ELF файлах это обычно через таблицу строк
    """
    # Упрощенный поиск - ищем ссылки на офсет в коде
    references = []
    # В ARM64 ссылки часто через ADRP + ADD инструкции
    # Это сложная эвристика, требует полного парсинга ELF
    return references

def patch_function_to_return_true(data, function_offset):
    """
    Патчит функцию по офсету, заставляя возвращать true (1)
    
    ARM64 инструкции:
    MOV W0, #1  : 0x20 0x00 0x80 0x52
    RET         : 0xC0 0x03 0x5F 0xD6
    """
    PATCH = bytes([
        0x20, 0x00, 0x80, 0x52,  # MOV W0, #1
        0xC0, 0x03, 0x5F, 0xD6   # RET
    ])
    
    # Заменяем первые 8 байт функции на патч
    new_data = bytearray(data)
    new_data[function_offset:function_offset+len(PATCH)] = PATCH
    return bytes(new_data)

def analyze_elf_symbols(filepath):
    """Анализ ELF файла для поиска экспортируемых символов"""
    try:
        import subprocess
        result = subprocess.run(
            ['readelf', '-s', filepath],
            capture_output=True,
            text=True
        )
        
        symbols = {}
        for line in result.stdout.split('\n'):
            if 'FUNC' in line or 'OBJECT' in line:
                parts = line.split()
                if len(parts) >= 8:
                    # Формат: Num Value Size Type Bind Vis Ndx Name
                    try:
                        value = int(parts[1], 16)
                        name = parts[-1]
                        symbols[name] = value
                    except (ValueError, IndexError):
                        continue
        
        return symbols
    except Exception as e:
        print(f"Warning: Could not analyze ELF symbols: {e}")
        return {}

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 analyze_native.py <libclient.so> [output.so]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file + ".patched"
    
    if not os.path.exists(input_file):
        print(f"Error: File not found: {input_file}")
        sys.exit(1)
    
    print(f"Analyzing: {input_file}")
    print("=" * 60)
    
    # Читаем файл
    with open(input_file, 'rb') as f:
        data = f.read()
    
    print(f"File size: {len(data)} bytes")
    print()
    
    # Анализ символов через readelf
    print("Analyzing ELF symbols...")
    symbols = analyze_elf_symbols(input_file)
    
    target_functions = []
    for name, offset in symbols.items():
        if 'check' in name.lower() or 'licence' in name.lower() or 'license' in name.lower():
            print(f"  Found potential target: {name} at 0x{offset:x}")
            target_functions.append((name, offset))
    
    if not target_functions:
        print("  No obvious check/licence functions found in symbols")
    print()
    
    # Поиск строковых констант
    print("Searching for string constants...")
    search_strings = [
        "Java_com_eternal_xdsdk_SuperJNI",
        "check",
        "licence",
        "license",
        "SuperJNI",
        "Companion"
    ]
    
    string_positions = {}
    for search_str in search_strings:
        positions = find_string(data, search_str)
        if positions:
            print(f"  '{search_str}' found at: {[hex(p) for p in positions]}")
            string_positions[search_str] = positions
    print()
    
    # Информация о патче
    print("ARM64 Patch Instructions:")
    print("  To make a function return true (1):")
    print("  Offset +0: 20 00 80 52  (MOV W0, #1)")
    print("  Offset +4: C0 03 5F D6  (RET)")
    print()
    
    # Автоматический патчинг если найдены целевые функции
    if target_functions:
        print("Applying patches...")
        patched_data = bytearray(data)
        
        for name, offset in target_functions:
            if 'check' in name.lower() or 'licence' in name.lower():
                print(f"  Patching {name} at 0x{offset:x}")
                
                # Проверяем что офсет валидный
                if offset > 0 and offset < len(patched_data) - 8:
                    # Показываем оригинальные байты
                    original = patched_data[offset:offset+8]
                    print(f"    Original: {' '.join(f'{b:02x}' for b in original)}")
                    
                    # Применяем патч
                    PATCH = bytes([0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6])
                    patched_data[offset:offset+8] = PATCH
                    print(f"    Patched:  {' '.join(f'{b:02x}' for b in PATCH)}")
        
        # Сохраняем пропатченный файл
        with open(output_file, 'wb') as f:
            f.write(patched_data)
        
        print()
        print(f"✓ Patched library saved to: {output_file}")
        
        # Устанавливаем те же права доступа
        original_stat = os.stat(input_file)
        os.chmod(output_file, original_stat.st_mode)
        
    else:
        print("⚠ No functions were automatically patched")
        print("  Manual analysis with Ghidra/IDA Pro recommended")
        print()
        print("Manual patching instructions:")
        print("  1. Open libclient.so in Ghidra or IDA Pro")
        print("  2. Find functions:")
        print("     - Java_com_eternal_xdsdk_SuperJNI_00024Companion_check")
        print("     - Java_com_eternal_xdsdk_SuperJNI_00024Companion_licence")
        print("  3. Note the file offset of each function")
        print("  4. Replace first 8 bytes with: 20 00 80 52 C0 03 5F D6")
        print("  5. Save the patched file")
    
    print()
    print("=" * 60)
    print("Analysis complete!")

if __name__ == '__main__':
    main()
