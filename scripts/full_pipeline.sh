#!/bin/bash
# Полный конвейер патчинга: декомпиляция -> патчинг -> сборка

set -e

APK_INPUT="${1:-app.apk}"
OUTPUT_APK="${2:-app-patched.apk}"
DECOMPILED_DIR="decompiled"

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo_success() {
    echo -e "${GREEN}✓${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo_error() {
    echo -e "${RED}✗${NC} $1"
}

echo "========================================="
echo "XDSDK License Bypass - Full Pipeline"
echo "========================================="
echo ""
echo "Input APK:  $APK_INPUT"
echo "Output APK: $OUTPUT_APK"
echo ""

# Проверка входного файла
if [ ! -f "$APK_INPUT" ]; then
    echo_error "Input APK not found: $APK_INPUT"
    echo ""
    echo "Usage: $0 <input.apk> [output.apk]"
    exit 1
fi

# Проверка зависимостей
echo "[0/5] Checking dependencies..."

MISSING_DEPS=()

if ! command -v apktool &> /dev/null; then
    MISSING_DEPS+=("apktool")
fi

if ! command -v python3 &> /dev/null; then
    MISSING_DEPS+=("python3")
fi

if ! command -v keytool &> /dev/null; then
    MISSING_DEPS+=("keytool (Java JDK)")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo_error "Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Install with:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y default-jdk python3"
    echo ""
    echo "For apktool, run: ./scripts/decompile.sh (will auto-install)"
    exit 1
fi

echo_success "All dependencies available"
echo ""

# Шаг 1: Декомпиляция
echo "[1/5] Decompiling APK..."
if [ -d "$DECOMPILED_DIR" ]; then
    echo_warning "Removing existing decompiled directory..."
    rm -rf "$DECOMPILED_DIR"
fi

./scripts/decompile.sh "$APK_INPUT" || {
    echo_error "Decompilation failed"
    exit 1
}
echo_success "Decompilation completed"
echo ""

# Шаг 2: Патчинг native библиотеки
echo "[2/5] Patching native library..."
LIBCLIENT="$DECOMPILED_DIR/lib/arm64-v8a/libclient.so"

if [ -f "$LIBCLIENT" ]; then
    echo "  Analyzing libclient.so..."
    python3 scripts/analyze_native.py "$LIBCLIENT" "$LIBCLIENT.tmp" 2>&1 | tee /tmp/native_analysis.log
    
    # Если патч успешен, заменяем оригинал
    if [ -f "$LIBCLIENT.tmp" ]; then
        mv "$LIBCLIENT.tmp" "$LIBCLIENT"
        echo_success "Native library patched"
    else
        echo_warning "Automatic patching failed, manual patching may be required"
        echo_warning "See /tmp/native_analysis.log for details"
    fi
else
    echo_warning "libclient.so not found at expected location"
    echo "  Searching for library..."
    find "$DECOMPILED_DIR" -name "libclient.so" -o -name "*.so" | head -5
fi
echo ""

# Шаг 3: Патчинг Smali
echo "[3/5] Patching Smali code..."
./scripts/patch_smali.sh "$DECOMPILED_DIR" || {
    echo_error "Smali patching failed"
    exit 1
}
echo_success "Smali patching completed"
echo ""

# Шаг 4: Проверка изменений
echo "[4/5] Verifying patches..."

# Проверка что SuperJNI пропатчен
if find "$DECOMPILED_DIR" -name "*SuperJNI*.smali" -exec grep -q "const/4 v0, 0x1" {} \; 2>/dev/null; then
    echo_success "SuperJNI methods patched"
else
    echo_warning "Could not verify SuperJNI patch"
fi

# Проверка что LoginActivity пропатчен
if find "$DECOMPILED_DIR" -name "*LoginActivity*.smali" -exec grep -q "MainActivity" {} \; 2>/dev/null; then
    echo_success "LoginActivity patched"
else
    echo_warning "Could not verify LoginActivity patch"
fi

# Проверка AndroidManifest
if grep -q "MainActivity.*MAIN\|MAIN.*MainActivity" "$DECOMPILED_DIR/AndroidManifest.xml" 2>/dev/null; then
    echo_success "AndroidManifest updated"
else
    echo_warning "Could not verify AndroidManifest changes"
fi

echo ""

# Шаг 5: Сборка
echo "[5/5] Building patched APK..."
./scripts/build.sh "$DECOMPILED_DIR" "$OUTPUT_APK" || {
    echo_error "Build failed"
    exit 1
}
echo ""

# Финальная проверка
if [ -f "$OUTPUT_APK" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_APK" | cut -f1)
    echo "========================================="
    echo_success "Pipeline completed successfully!"
    echo "========================================="
    echo ""
    echo "Output: $OUTPUT_APK"
    echo "Size:   $FILE_SIZE"
    echo ""
    echo "Installation:"
    echo "  adb install -r $OUTPUT_APK"
    echo ""
    echo "Testing checklist:"
    echo "  [ ] Install APK on device"
    echo "  [ ] App launches without login screen"
    echo "  [ ] Main functionality works"
    echo "  [ ] Auto-update works (check Settings or About)"
    echo "  [ ] No crashes (monitor: adb logcat)"
    echo ""
    echo "If you encounter issues:"
    echo "  1. Check logs: adb logcat | grep -i 'eternal\\|xdsdk\\|AndroidRuntime'"
    echo "  2. Review docs/WORKFLOW.md for troubleshooting"
    echo "  3. For manual patching: docs/TECHNICAL.md"
else
    echo_error "Pipeline failed - output APK not created"
    exit 1
fi
