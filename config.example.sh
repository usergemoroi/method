#!/bin/bash
# Конфигурация для патчинга - скопируйте в config.sh и настройте

# === APK Настройки ===

# Входной APK файл
INPUT_APK="app.apk"

# Выходной APK файл
OUTPUT_APK="app-patched.apk"

# Директория для декомпилированных файлов
DECOMPILED_DIR="decompiled"

# === Подпись APK ===

# Путь к keystore
KEYSTORE_PATH="release.keystore"

# Алиас ключа
KEY_ALIAS="releasekey"

# Пароль keystore и ключа (НЕ коммитьте config.sh с реальными паролями!)
KEYSTORE_PASSWORD="android"
KEY_PASSWORD="android"

# DN для генерации нового keystore
KEYSTORE_DN="CN=Developer, OU=Dev, O=Company, L=City, S=State, C=US"

# === Целевое приложение ===

# Имя пакета приложения
PACKAGE_NAME="com.eternal"

# Главная Activity (куда переходить после обхода LoginActivity)
MAIN_ACTIVITY="MainActivity"

# LoginActivity которую нужно обойти
LOGIN_ACTIVITY="LoginActivity"

# === Пути к компонентам XDSDK ===

# Путь к SuperJNI классу (относительно smali/)
SUPERJNI_CLASS="com/eternal/xdsdk/SuperJNI"

# Путь к LoginActivity (относительно smali/)
LOGIN_CLASS="com/eternal/xdsdk/LoginActivity"

# Путь к native библиотеке (относительно decompiled/)
LIBCLIENT_PATH="lib/arm64-v8a/libclient.so"

# === Функции для патчинга ===

# Имена нативных функций в libclient.so
NATIVE_CHECK_FUNCTION="Java_com_eternal_xdsdk_SuperJNI_00024Companion_check"
NATIVE_LICENCE_FUNCTION="Java_com_eternal_xdsdk_SuperJNI_00024Companion_licence"

# Имена методов в Smali
SMALI_CHECK_METHOD="check"
SMALI_LICENCE_METHOD="licence"

# Метод update который НЕ ТРОГАЕМ
SMALI_UPDATE_METHOD="update"

# === Assets ===

# Зашифрованный asset файл (НЕ трогать его расшифровку!)
ENCRYPTED_ASSET="assets/burriEnc"

# === Опции патчинга ===

# Применять ли патч к native библиотеке (true/false)
PATCH_NATIVE=true

# Применять ли патч к Smali коду (true/false)
PATCH_SMALI=true

# Изменять ли AndroidManifest.xml (true/false)
PATCH_MANIFEST=true

# Создавать ли резервные копии перед патчингом (true/false)
CREATE_BACKUPS=true

# === Отладка ===

# Уровень логирования (0=minimal, 1=normal, 2=verbose)
LOG_LEVEL=1

# Сохранять ли промежуточные файлы (true/false)
KEEP_TEMP_FILES=false

# Директория для логов
LOG_DIR="logs"

# === Тестирование ===

# Автоматически устанавливать APK после сборки (true/false)
AUTO_INSTALL=false

# Автоматически запускать приложение после установки (true/false)
AUTO_LAUNCH=false

# Собирать логи после запуска (true/false)
COLLECT_LOGS=true

# Время ожидания перед сбором логов (секунды)
LOG_COLLECT_DELAY=5

# === Advanced ===

# Использовать radare2 для патчинга native (true/false)
USE_RADARE2=false

# Использовать Ghidra скрипт для анализа (true/false)
USE_GHIDRA_SCRIPT=false

# Путь к Ghidra (если USE_GHIDRA_SCRIPT=true)
GHIDRA_PATH="/opt/ghidra"

# Кастомные параметры apktool для декомпиляции
APKTOOL_DECODE_OPTIONS="-f"

# Кастомные параметры apktool для компиляции
APKTOOL_BUILD_OPTIONS=""

# === ARM64 Патч инструкции ===

# Hex код для "return true" в ARM64
ARM64_RETURN_TRUE="20008052c0035fd6"

# Hex код для "return false" в ARM64  
ARM64_RETURN_FALSE="00008052c0035fd6"

# === Hooks ===

# Выполнить перед декомпиляцией
PRE_DECOMPILE_HOOK=""

# Выполнить после декомпиляции
POST_DECOMPILE_HOOK=""

# Выполнить перед патчингом
PRE_PATCH_HOOK=""

# Выполнить после патчинга
POST_PATCH_HOOK=""

# Выполнить перед сборкой
PRE_BUILD_HOOK=""

# Выполнить после сборки
POST_BUILD_HOOK=""

# === Примеры использования hooks ===

# PRE_DECOMPILE_HOOK="echo 'Starting decompilation...'"
# POST_PATCH_HOOK="./scripts/verify_patches.sh"
# POST_BUILD_HOOK="./scripts/test_apk.sh $OUTPUT_APK"
