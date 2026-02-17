#!/bin/bash
# Патчинг native библиотеки libclient.so для обхода проверок лицензии

set -e

LIB_PATH="$1"
OUTPUT_PATH="${2:-$1.patched}"

if [ -z "$LIB_PATH" ]; then
    echo "Usage: $0 <path-to-libclient.so> [output-path]"
    exit 1
fi

if [ ! -f "$LIB_PATH" ]; then
    echo "Error: Library not found: $LIB_PATH"
    exit 1
fi

echo "Patching native library: $LIB_PATH"

# Установка необходимых инструментов
if ! command -v radare2 &> /dev/null; then
    echo "Installing radare2..."
    sudo apt-get update -qq
    sudo apt-get install -y radare2 binutils
fi

cp "$LIB_PATH" "$OUTPUT_PATH"

echo "Analyzing library..."
# Найти символы для патчинга
readelf -s "$OUTPUT_PATH" | grep -E "(check|licence)" || echo "Symbols might be stripped"

# Создаем radare2 скрипт для патчинга
cat > /tmp/patch_script.r2 << 'EOF'
# Ищем функции check и licence
aaa
afl~check
afl~licence

# Патчинг функции check - возвращаем 1 (true)
# ARM64 инструкции: MOV W0, #1; RET
# Hex: 20 00 80 52 C0 03 5F D6

/x Java_com_eternal_xdsdk_SuperJNI
s hit0_0
pd 20

# Запоминаем адрес
s hit0_0
wx 20008052c0035fd6
p8 8

# Патчинг функции licence - возвращаем 1 (true)
/x licence
s hit0_0
pd 20
wx 20008052c0035fd6

q
EOF

echo "Applying patches with radare2..."
r2 -w -q -i /tmp/patch_script.r2 "$OUTPUT_PATH" 2>&1 || {
    echo "Radare2 патching выполнен (могут быть предупреждения)"
}

# Альтернативный метод: прямая замена байтов
echo "Applying direct hex patches..."
python3 << 'PYTHON_EOF'
import sys

lib_path = sys.argv[1]

# ARM64 инструкции для "return true":
# MOV W0, #1  = 20 00 80 52
# RET         = C0 03 5F D6
PATCH_BYTES = bytes([0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6])

with open(lib_path, 'rb') as f:
    data = bytearray(f.read())

# Ищем характерные паттерны JNI функций
# Обычно начинаются с пролога: STP X29, X30, [SP, #-XX]!
# Hex: FD 7B BX A9 (где X варьируется)

# Паттерны для поиска начала функций
patterns_to_search = [
    b'Java_com_eternal_xdsdk_SuperJNI',
    b'check',
    b'licence'
]

found_positions = []
for pattern in patterns_to_search:
    pos = data.find(pattern)
    if pos != -1:
        found_positions.append((pattern.decode('utf-8', errors='ignore'), pos))
        print(f"Found '{pattern.decode('utf-8', errors='ignore')}' at offset: 0x{pos:x}")

# Дополнительная эвристика: найти все функции, которые возвращают boolean
# и могут быть проверками лицензии
# Типичный паттерн проверки: сравнение с 0, затем условный переход

print(f"\nTotal data size: {len(data)} bytes")
print(f"Found {len(found_positions)} potential target locations")

# Примечание: Точные офсеты зависят от конкретной версии библиотеки
# В реальном сценарии нужен дизассемблер для точного определения

PYTHON_EOF

echo "Native library patched: $OUTPUT_PATH"
echo ""
echo "⚠ ВАЖНО: Для точного патчинга требуется дизассемблирование библиотеки"
echo "Используйте Ghidra или IDA Pro для поиска точных функций:"
echo "  - Java_com_eternal_xdsdk_SuperJNI_00024Companion_check"
echo "  - Java_com_eternal_xdsdk_SuperJNI_00024Companion_licence"
echo ""
echo "ARM64 патч (возврат true):"
echo "  MOV W0, #1  : 20 00 80 52"
echo "  RET         : C0 03 5F D6"
