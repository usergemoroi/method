#!/bin/bash
# Декомпиляция APK с помощью apktool

set -e

APK_FILE="$1"
OUTPUT_DIR="decompiled"

if [ -z "$APK_FILE" ]; then
    echo "Usage: $0 <apk-file>"
    exit 1
fi

if [ ! -f "$APK_FILE" ]; then
    echo "Error: APK file not found: $APK_FILE"
    exit 1
fi

# Установка apktool если не установлен
if ! command -v apktool &> /dev/null; then
    echo "Installing apktool..."
    wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool -O /tmp/apktool
    wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O /tmp/apktool.jar
    sudo mv /tmp/apktool /usr/local/bin/apktool
    sudo mv /tmp/apktool.jar /usr/local/bin/apktool.jar
    sudo chmod +x /usr/local/bin/apktool
fi

echo "Decompiling APK..."
rm -rf "$OUTPUT_DIR"
apktool d "$APK_FILE" -o "$OUTPUT_DIR" -f

echo "APK decompiled to: $OUTPUT_DIR"
echo "Structure:"
ls -la "$OUTPUT_DIR"

# Проверка наличия критических компонентов
if [ -f "$OUTPUT_DIR/lib/arm64-v8a/libclient.so" ]; then
    echo "✓ Found libclient.so (arm64-v8a)"
else
    echo "⚠ libclient.so not found in lib/arm64-v8a/"
fi

if [ -f "$OUTPUT_DIR/assets/burriEnc" ]; then
    echo "✓ Found burriEnc asset"
else
    echo "⚠ burriEnc not found in assets/"
fi

echo "Searching for XDSDK classes..."
find "$OUTPUT_DIR" -name "*SuperJNI*" -o -name "*LoginActivity*" | head -10
