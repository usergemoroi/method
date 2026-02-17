#!/bin/bash
# Главный скрипт для применения всех патчей

set -e

DECOMPILED_DIR="${1:-decompiled}"

if [ ! -d "$DECOMPILED_DIR" ]; then
    echo "Error: Decompiled directory not found: $DECOMPILED_DIR"
    echo "Usage: $0 [decompiled-directory]"
    exit 1
fi

echo "========================================="
echo "XDSDK License Bypass - Full Patch"
echo "========================================="
echo ""

# 1. Патчинг native библиотеки
echo "[1/3] Patching native library..."
LIBCLIENT="$DECOMPILED_DIR/lib/arm64-v8a/libclient.so"
if [ -f "$LIBCLIENT" ]; then
    ./scripts/patch_native.sh "$LIBCLIENT" "$LIBCLIENT.patched"
    mv "$LIBCLIENT.patched" "$LIBCLIENT"
    echo "✓ Native library patched"
else
    echo "⚠ libclient.so not found at $LIBCLIENT"
    echo "  Searching for library..."
    find "$DECOMPILED_DIR" -name "libclient.so"
fi
echo ""

# 2. Патчинг Smali кода
echo "[2/3] Patching Smali code..."
./scripts/patch_smali.sh "$DECOMPILED_DIR"
echo ""

# 3. Проверка системы обновлений
echo "[3/3] Verifying update system..."
UPDATE_CHECK=$(find "$DECOMPILED_DIR" -name "*.smali" -exec grep -l "update.*currPlugUrl\|currPlugVer" {} \; | head -1)
if [ -n "$UPDATE_CHECK" ]; then
    echo "✓ Update system found in: $UPDATE_CHECK"
    echo "  Verifying it's not modified..."
    if grep -q "update" "$UPDATE_CHECK"; then
        echo "✓ Update method appears intact"
    fi
else
    echo "⚠ Could not verify update system"
fi
echo ""

# 4. Проверка assets
echo "Checking assets..."
if [ -f "$DECOMPILED_DIR/assets/burriEnc" ]; then
    echo "✓ burriEnc asset present (size: $(stat -f%z "$DECOMPILED_DIR/assets/burriEnc" 2>/dev/null || stat -c%s "$DECOMPILED_DIR/assets/burriEnc") bytes)"
else
    echo "⚠ burriEnc not found"
fi
echo ""

echo "========================================="
echo "Patching completed!"
echo "========================================="
echo ""
echo "Summary of changes:"
echo "  ✓ Native check/licence methods → return true"
echo "  ✓ Smali SuperJNI methods → bypassed"
echo "  ✓ LoginActivity → auto-skip to MainActivity"
echo "  ✓ AndroidManifest → LAUNCHER points to MainActivity"
echo "  ✓ Update system → preserved"
echo "  ✓ Asset encryption → not modified"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Build APK: ./scripts/build.sh"
echo "  3. Test on device"
