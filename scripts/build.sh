#!/bin/bash
# Сборка и подпись пропатченного APK

set -e

DECOMPILED_DIR="${1:-decompiled}"
OUTPUT_APK="${2:-app-patched.apk}"
KEYSTORE="${3:-release.keystore}"
KEY_ALIAS="${4:-releasekey}"
KEY_PASS="${5:-android}"

echo "========================================="
echo "Building patched APK"
echo "========================================="
echo ""

if [ ! -d "$DECOMPILED_DIR" ]; then
    echo "Error: Decompiled directory not found: $DECOMPILED_DIR"
    exit 1
fi

# Установка необходимых инструментов
if ! command -v apktool &> /dev/null; then
    echo "Installing apktool..."
    wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool -O /tmp/apktool
    wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O /tmp/apktool.jar
    sudo mv /tmp/apktool /usr/local/bin/apktool
    sudo mv /tmp/apktool.jar /usr/local/bin/apktool.jar
    sudo chmod +x /usr/local/bin/apktool
fi

if ! command -v zipalign &> /dev/null; then
    echo "Installing Android build tools..."
    sudo apt-get update -qq
    sudo apt-get install -y zipalign apksigner || {
        echo "⚠ zipalign not available via apt, downloading Android SDK tools..."
        # Альтернатива: скачать из Android SDK
    }
fi

# 1. Очистка META-INF
echo "[1/5] Cleaning old signatures..."
META_INF="$DECOMPILED_DIR/original/META-INF"
if [ -d "$META_INF" ]; then
    echo "Removing old META-INF..."
    rm -rf "$META_INF"
fi
echo "✓ Old signatures removed"
echo ""

# 2. Сборка APK с помощью apktool
echo "[2/5] Building APK with apktool..."
UNSIGNED_APK="${OUTPUT_APK%.apk}-unsigned.apk"
rm -f "$UNSIGNED_APK"
apktool b "$DECOMPILED_DIR" -o "$UNSIGNED_APK"
echo "✓ APK built: $UNSIGNED_APK"
echo ""

# 3. Создание keystore если не существует
echo "[3/5] Preparing keystore..."
if [ ! -f "$KEYSTORE" ]; then
    echo "Creating new keystore: $KEYSTORE"
    keytool -genkeypair \
        -keystore "$KEYSTORE" \
        -alias "$KEY_ALIAS" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass "$KEY_PASS" \
        -keypass "$KEY_PASS" \
        -dname "CN=Developer, OU=Dev, O=Company, L=City, S=State, C=US" \
        -noprompt
    echo "✓ Keystore created"
else
    echo "✓ Using existing keystore: $KEYSTORE"
fi
echo ""

# 4. Выравнивание APK
echo "[4/5] Aligning APK..."
ALIGNED_APK="${OUTPUT_APK%.apk}-aligned.apk"
rm -f "$ALIGNED_APK"

if command -v zipalign &> /dev/null; then
    zipalign -v -p 4 "$UNSIGNED_APK" "$ALIGNED_APK"
    echo "✓ APK aligned"
else
    echo "⚠ zipalign not available, skipping alignment"
    cp "$UNSIGNED_APK" "$ALIGNED_APK"
fi
echo ""

# 5. Подпись APK (V2/V3)
echo "[5/5] Signing APK..."
rm -f "$OUTPUT_APK"

if command -v apksigner &> /dev/null; then
    # Используем apksigner для V2/V3 подписи
    apksigner sign \
        --ks "$KEYSTORE" \
        --ks-key-alias "$KEY_ALIAS" \
        --ks-pass "pass:$KEY_PASS" \
        --key-pass "pass:$KEY_PASS" \
        --out "$OUTPUT_APK" \
        "$ALIGNED_APK"
    
    echo "✓ APK signed with V2/V3 signature"
    
    # Проверка подписи
    apksigner verify --verbose "$OUTPUT_APK"
    
elif command -v jarsigner &> /dev/null; then
    # Fallback: используем jarsigner (V1 only)
    cp "$ALIGNED_APK" "$OUTPUT_APK"
    jarsigner -verbose \
        -keystore "$KEYSTORE" \
        -storepass "$KEY_PASS" \
        -keypass "$KEY_PASS" \
        "$OUTPUT_APK" \
        "$KEY_ALIAS"
    
    echo "✓ APK signed with V1 signature (jarsigner)"
    echo "⚠ Warning: V1 signature only, may not work on Android 11+"
else
    echo "ERROR: No signing tool available (apksigner or jarsigner)"
    exit 1
fi

# Очистка временных файлов
rm -f "$UNSIGNED_APK" "$ALIGNED_APK"

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
echo ""
echo "Output APK: $OUTPUT_APK"
echo "Size: $(du -h "$OUTPUT_APK" | cut -f1)"
echo ""
echo "Installation:"
echo "  adb install -r $OUTPUT_APK"
echo ""
echo "Testing checklist:"
echo "  [ ] APK installs without errors"
echo "  [ ] App launches directly to MainActivity"
echo "  [ ] No license check prompts"
echo "  [ ] Auto-update functionality works"
echo "  [ ] Assets load correctly (burriEnc decrypts)"
echo "  [ ] No crashes on startup"
