#!/bin/bash
# Тестирование пропатченного APK

set -e

APK_FILE="${1:-app-patched.apk}"
PACKAGE_NAME="com.eternal"  # Может потребоваться изменить

if [ ! -f "$APK_FILE" ]; then
    echo "Error: APK not found: $APK_FILE"
    echo "Usage: $0 <apk-file>"
    exit 1
fi

echo "========================================="
echo "Testing Patched APK"
echo "========================================="
echo ""
echo "APK: $APK_FILE"
echo ""

# Проверка что устройство подключено
if ! adb devices | grep -q "device$"; then
    echo "Error: No Android device connected"
    echo "Please connect a device or start an emulator"
    exit 1
fi

# Получить имя пакета из APK
echo "[1/6] Analyzing APK..."
PACKAGE_INFO=$(aapt dump badging "$APK_FILE" 2>/dev/null | grep "package: name" || echo "")
if [ -n "$PACKAGE_INFO" ]; then
    PACKAGE_NAME=$(echo "$PACKAGE_INFO" | sed "s/.*name='\([^']*\)'.*/\1/")
    echo "Package: $PACKAGE_NAME"
else
    echo "Warning: Could not extract package name, using default: $PACKAGE_NAME"
fi
echo ""

# Проверка подписи
echo "[2/6] Verifying signature..."
if command -v apksigner &> /dev/null; then
    apksigner verify "$APK_FILE" && echo "✓ Signature valid" || echo "⚠ Signature verification failed"
else
    echo "⚠ apksigner not available, skipping signature check"
fi
echo ""

# Установка APK
echo "[3/6] Installing APK..."
adb install -r "$APK_FILE" && echo "✓ Installation successful" || {
    echo "✗ Installation failed"
    exit 1
}
echo ""

# Запуск приложения
echo "[4/6] Starting application..."
MAIN_ACTIVITY=$(aapt dump badging "$APK_FILE" 2>/dev/null | grep "launchable-activity" | sed "s/.*name='\([^']*\)'.*/\1/" || echo ".MainActivity")
echo "Main activity: $MAIN_ACTIVITY"

adb shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY" && echo "✓ App started" || {
    echo "⚠ Failed to start app"
}
sleep 3
echo ""

# Проверка что приложение работает
echo "[5/6] Checking app status..."
RUNNING=$(adb shell ps | grep "$PACKAGE_NAME" || echo "")
if [ -n "$RUNNING" ]; then
    echo "✓ App is running"
else
    echo "⚠ App is not running (may have crashed)"
fi
echo ""

# Сбор логов
echo "[6/6] Collecting logs..."
LOG_FILE="test_logs_$(date +%Y%m%d_%H%M%S).txt"
echo "Saving logs to: $LOG_FILE"

# Очистить старые логи
adb logcat -c

# Перезапустить приложение для чистых логов
adb shell am force-stop "$PACKAGE_NAME"
sleep 1
adb shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY"
sleep 5

# Собрать логи
adb logcat -d > "$LOG_FILE"

# Проверить на ошибки
echo ""
echo "Log analysis:"
ERROR_COUNT=$(grep -i "error\|exception\|crash" "$LOG_FILE" | grep -i "eternal\|xdsdk" | wc -l)
FATAL_COUNT=$(grep -i "fatal" "$LOG_FILE" | grep -i "eternal\|xdsdk" | wc -l)

if [ $FATAL_COUNT -gt 0 ]; then
    echo "✗ Found $FATAL_COUNT FATAL errors"
    echo "  Check $LOG_FILE for details"
    grep -i "fatal" "$LOG_FILE" | grep -i "eternal\|xdsdk" | head -5
elif [ $ERROR_COUNT -gt 0 ]; then
    echo "⚠ Found $ERROR_COUNT errors (may be non-critical)"
else
    echo "✓ No obvious errors in logs"
fi

# Проверить что LoginActivity не запущена
if grep -q "LoginActivity" "$LOG_FILE"; then
    echo "⚠ Warning: LoginActivity appears in logs (should be bypassed)"
else
    echo "✓ LoginActivity bypassed"
fi

# Проверить что MainActivity запущена
if grep -q "MainActivity" "$LOG_FILE"; then
    echo "✓ MainActivity started"
else
    echo "⚠ MainActivity not found in logs"
fi

echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo ""
echo "Results:"
echo "  [✓] APK installed"
echo "  [$([ -n "$RUNNING" ] && echo "✓" || echo "✗")] App running"
echo "  [$([ $FATAL_COUNT -eq 0 ] && echo "✓" || echo "✗")] No fatal errors"
echo ""
echo "Manual testing:"
echo "  1. Check that app opened without login screen"
echo "  2. Navigate through the app to test functionality"
echo "  3. Check Settings/About for update functionality"
echo "  4. Test loading of content/assets"
echo ""
echo "Logs saved to: $LOG_FILE"
echo ""
echo "To monitor live logs:"
echo "  adb logcat | grep -i '$PACKAGE_NAME'"
echo ""
echo "To uninstall:"
echo "  adb uninstall $PACKAGE_NAME"
