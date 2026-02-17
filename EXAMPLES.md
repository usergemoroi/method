# Примеры использования

## Базовые примеры

### Пример 1: Простой патчинг

```bash
# 1. Поместите APK в корень проекта
cp ~/Downloads/myapp.apk ./app.apk

# 2. Запустите полный конвейер
./scripts/full_pipeline.sh app.apk

# 3. Установите пропатченный APK
adb install -r app-patched.apk
```

### Пример 2: Патчинг с кастомными именами файлов

```bash
./scripts/full_pipeline.sh original_v1.2.3.apk patched_v1.2.3.apk
```

### Пример 3: Ручной патчинг шаг за шагом

```bash
# Декомпиляция
./scripts/decompile.sh myapp.apk

# Анализ нативной библиотеки
python3 scripts/analyze_native.py decompiled/lib/arm64-v8a/libclient.so

# Патчинг native
./scripts/patch_native.sh decompiled/lib/arm64-v8a/libclient.so

# Патчинг Smali
./scripts/patch_smali.sh decompiled

# Сборка
./scripts/build.sh decompiled myapp-patched.apk
```

## Продвинутые примеры

### Пример 4: Использование кастомного keystore

```bash
# Создать keystore
keytool -genkeypair \
    -keystore mykey.jks \
    -alias myalias \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storepass mypassword \
    -keypass mypassword \
    -dname "CN=MyName, OU=MyUnit, O=MyOrg, L=MyCity, S=MyState, C=US"

# Использовать при сборке
./scripts/build.sh decompiled output.apk mykey.jks myalias mypassword
```

### Пример 5: Патчинг с проверкой каждого шага

```bash
#!/bin/bash
set -e

echo "=== Step 1: Decompile ==="
./scripts/decompile.sh app.apk
ls -la decompiled/

echo "=== Step 2: Backup ==="
cp -r decompiled decompiled.backup

echo "=== Step 3: Analyze Native ==="
python3 scripts/analyze_native.py decompiled/lib/arm64-v8a/libclient.so

echo "=== Step 4: Patch Native ==="
./scripts/patch_native.sh decompiled/lib/arm64-v8a/libclient.so

echo "=== Step 5: Verify Native Patch ==="
xxd decompiled/lib/arm64-v8a/libclient.so | grep "2000 8052 c003 5fd6"
if [ $? -eq 0 ]; then
    echo "✓ Native patch found"
fi

echo "=== Step 6: Patch Smali ==="
./scripts/patch_smali.sh decompiled

echo "=== Step 7: Verify Smali Patch ==="
grep -r "const/4 v0, 0x1" decompiled/smali*/com/eternal/xdsdk/
if [ $? -eq 0 ]; then
    echo "✓ Smali patch found"
fi

echo "=== Step 8: Build ==="
./scripts/build.sh decompiled app-patched.apk

echo "=== Step 9: Test ==="
./scripts/test_apk.sh app-patched.apk

echo "=== All steps completed ==="
```

### Пример 6: Патчинг с использованием Ghidra

```bash
# 1. Декомпилировать APK
./scripts/decompile.sh app.apk

# 2. Открыть в Ghidra и найти офсеты
# Запустить Ghidra
/opt/ghidra/ghidraRun

# Импортировать: File → Import File → decompiled/lib/arm64-v8a/libclient.so
# Анализ: Analysis → Auto Analyze
# Найти функции: Window → Symbol Tree → фильтр "check"
# Записать офсеты (например, check = 0x12340, licence = 0x15680)

# 3. Пропатчить вручную в hex редакторе
LIBCLIENT="decompiled/lib/arm64-v8a/libclient.so"

# Патч для check (офсет 0x12340)
printf '\x20\x00\x80\x52\xc0\x03\x5f\xd6' | \
  dd of="$LIBCLIENT" bs=1 seek=$((0x12340)) conv=notrunc

# Патч для licence (офсет 0x15680)
printf '\x20\x00\x80\x52\xc0\x03\x5f\xd6' | \
  dd of="$LIBCLIENT" bs=1 seek=$((0x15680)) conv=notrunc

# 4. Продолжить стандартный процесс
./scripts/patch_smali.sh decompiled
./scripts/build.sh decompiled app-patched.apk
```

### Пример 7: Патчинг с перехватом сетевых запросов

```bash
# Терминал 1: Запустить mitmproxy
pip3 install mitmproxy
mitmweb -p 8080

# Терминал 2: Настроить устройство и установить сертификат
# (вручную в Settings на устройстве)

# Установить пропатченный APK
adb install -r app-patched.apk

# Запустить приложение
adb shell am start -n com.eternal/.MainActivity

# Смотреть запросы в браузере: http://127.0.0.1:8081
# Искать запросы к серверу лицензий - их не должно быть
# Искать запросы к серверу обновлений - они должны быть
```

### Пример 8: Патчинг нескольких архитектур

```bash
#!/bin/bash
# Патчинг всех архитектур в APK

./scripts/decompile.sh app.apk

# ARM64
if [ -f decompiled/lib/arm64-v8a/libclient.so ]; then
    echo "Patching ARM64..."
    ./scripts/patch_native.sh decompiled/lib/arm64-v8a/libclient.so
fi

# ARM32 (требует другие инструкции)
if [ -f decompiled/lib/armeabi-v7a/libclient.so ]; then
    echo "Patching ARM32..."
    # Патч ARM32: 01 20 70 47 (MOVS R0, #1; BX LR)
    LIBCLIENT="decompiled/lib/armeabi-v7a/libclient.so"
    
    # Найти офсеты с помощью radare2 или Ghidra
    # Затем применить патч
    # printf '\x01\x20\x70\x47' | dd of="$LIBCLIENT" bs=1 seek=OFFSET conv=notrunc
fi

# x86_64
if [ -f decompiled/lib/x86_64/libclient.so ]; then
    echo "Patching x86_64..."
    # Патч x86_64: B8 01 00 00 00 C3 (MOV EAX, 1; RET)
    # Применить аналогично
fi

./scripts/patch_smali.sh decompiled
./scripts/build.sh decompiled app-patched-multiarch.apk
```

## Интеграция и автоматизация

### Пример 9: GitHub Actions

```yaml
# .github/workflows/patch-apk.yml
name: Patch APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      apk_url:
        description: 'URL to APK'
        required: true

jobs:
  patch:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '17'
    
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y python3 wget unzip
        chmod +x scripts/*.sh
    
    - name: Download APK
      run: |
        wget -O app.apk "${{ github.event.inputs.apk_url || secrets.APK_URL }}"
    
    - name: Patch APK
      run: |
        ./scripts/full_pipeline.sh app.apk
    
    - name: Upload patched APK
      uses: actions/upload-artifact@v3
      with:
        name: patched-apk
        path: app-patched.apk
        retention-days: 30
    
    - name: Create Release
      if: startsWith(github.ref, 'refs/tags/')
      uses: softprops/action-gh-release@v1
      with:
        files: app-patched.apk
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Пример 10: GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - patch
  - test
  - deploy

variables:
  APK_FILE: "app.apk"
  OUTPUT_APK: "app-patched.apk"

before_script:
  - apt-get update -qq
  - apt-get install -y default-jdk python3 wget unzip
  - chmod +x scripts/*.sh

patch_apk:
  stage: patch
  script:
    - wget -O $APK_FILE "$APK_URL"
    - ./scripts/full_pipeline.sh $APK_FILE
  artifacts:
    paths:
      - app-patched.apk
    expire_in: 1 week

test_apk:
  stage: test
  script:
    - echo "Running tests..."
    - ./scripts/test_apk.sh app-patched.apk || true
  artifacts:
    paths:
      - test_logs_*.txt
    expire_in: 1 day

deploy_apk:
  stage: deploy
  only:
    - main
  script:
    - echo "Deploying to server..."
    - curl -F "file=@app-patched.apk" "$DEPLOY_URL"
```

### Пример 11: Docker контейнер

```dockerfile
# Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    default-jdk \
    python3 \
    python3-pip \
    wget \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Установить apktool
RUN wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool -O /usr/local/bin/apktool && \
    wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O /usr/local/bin/apktool.jar && \
    chmod +x /usr/local/bin/apktool

# Копировать скрипты
COPY scripts/ /workspace/scripts/
RUN chmod +x /workspace/scripts/*.sh

# Точка входа
ENTRYPOINT ["/workspace/scripts/full_pipeline.sh"]

# Использование:
# docker build -t xdsdk-patcher .
# docker run -v $(pwd):/data xdsdk-patcher /data/app.apk
```

### Пример 12: Batch патчинг нескольких APK

```bash
#!/bin/bash
# batch_patch.sh - патчинг нескольких APK

APK_DIR="apks"
OUTPUT_DIR="patched"

mkdir -p "$OUTPUT_DIR"

for apk in "$APK_DIR"/*.apk; do
    filename=$(basename "$apk")
    name="${filename%.apk}"
    
    echo "================================================"
    echo "Processing: $filename"
    echo "================================================"
    
    # Патчинг
    ./scripts/full_pipeline.sh "$apk" "$OUTPUT_DIR/${name}-patched.apk"
    
    if [ $? -eq 0 ]; then
        echo "✓ Success: $filename"
    else
        echo "✗ Failed: $filename"
    fi
    
    echo ""
done

echo "Batch patching complete!"
ls -lh "$OUTPUT_DIR"
```

## Отладка и тестирование

### Пример 13: Детальная отладка

```bash
#!/bin/bash
# debug_patch.sh

set -x  # Печатать все команды

APK="app.apk"

# Декомпиляция с максимальным выводом
apktool d "$APK" -o decompiled -f --verbose

# Анализ структуры
echo "=== APK Structure ==="
tree -L 3 decompiled/

# Поиск XDSDK компонентов
echo "=== XDSDK Components ==="
find decompiled -name "*xdsdk*" -o -name "*SuperJNI*" -o -name "*LoginActivity*"

# Анализ AndroidManifest
echo "=== Activities ==="
grep -A 5 "<activity" decompiled/AndroidManifest.xml

# Анализ native библиотеки
echo "=== Native Library ==="
readelf -s decompiled/lib/arm64-v8a/libclient.so | grep -i "check\|licence\|update"

# Дизассемблирование
echo "=== Disassembly ==="
objdump -D -b binary -m aarch64 decompiled/lib/arm64-v8a/libclient.so | less

set +x
```

### Пример 14: Сравнение до и после патча

```bash
#!/bin/bash
# compare_patch.sh

APK_ORIGINAL="app.apk"
APK_PATCHED="app-patched.apk"

# Декомпилировать оба
apktool d "$APK_ORIGINAL" -o original -f
apktool d "$APK_PATCHED" -o patched -f

# Сравнить структуру
echo "=== Directory Diff ==="
diff -rq original/ patched/ | grep -v "\.dex\|META-INF"

# Сравнить AndroidManifest
echo "=== AndroidManifest Diff ==="
diff -u original/AndroidManifest.xml patched/AndroidManifest.xml

# Сравнить SuperJNI
echo "=== SuperJNI Diff ==="
SUPERJNI_ORIG=$(find original -name "*SuperJNI*.smali" | head -1)
SUPERJNI_PATCH=$(find patched -name "*SuperJNI*.smali" | head -1)
diff -u "$SUPERJNI_ORIG" "$SUPERJNI_PATCH"

# Сравнить native библиотеку
echo "=== Native Library Diff ==="
xxd original/lib/arm64-v8a/libclient.so > /tmp/orig.hex
xxd patched/lib/arm64-v8a/libclient.so > /tmp/patch.hex
diff -u /tmp/orig.hex /tmp/patch.hex | head -100
```

### Пример 15: Мониторинг приложения на устройстве

```bash
#!/bin/bash
# monitor_app.sh

PACKAGE="com.eternal"

echo "Installing app..."
adb install -r app-patched.apk

echo "Starting app..."
adb shell am start -n "$PACKAGE/.MainActivity"

echo "Monitoring logs (Ctrl+C to stop)..."
adb logcat -c
adb logcat | grep -i --line-buffered "$PACKAGE\|xdsdk\|AndroidRuntime" | while read line; do
    if echo "$line" | grep -qi "error\|exception\|crash"; then
        echo -e "\033[0;31m$line\033[0m"  # Красный для ошибок
    elif echo "$line" | grep -qi "warning"; then
        echo -e "\033[1;33m$line\033[0m"  # Желтый для предупреждений
    else
        echo "$line"
    fi
done
```

## Кастомизация

### Пример 16: Добавление кастомных патчей

```bash
# custom_patches.sh
# Добавить после стандартных патчей

DECOMPILED_DIR="decompiled"

# Добавить кастомный код в MainActivity
MAIN_ACTIVITY=$(find "$DECOMPILED_DIR" -name "MainActivity.smali" | head -1)

if [ -f "$MAIN_ACTIVITY" ]; then
    echo "Adding custom code to MainActivity..."
    
    # Добавить Toast при запуске
    sed -i '/invoke-super.*onCreate/a \
    \
    # Custom: Show toast\
    const-string v0, "Patched version"\
    const/4 v1, 0x0\
    invoke-static {p0, v0, v1}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;\
    move-result-object v0\
    invoke-virtual {v0}, Landroid/widget/Toast;->show()V' "$MAIN_ACTIVITY"
fi

# Удалить analytics
echo "Removing analytics..."
find "$DECOMPILED_DIR" -name "*.smali" -exec sed -i '/analytics\|tracking\|firebase/d' {} \;

# Отключить рекламу
echo "Disabling ads..."
find "$DECOMPILED_DIR" -name "*Ad*.smali" -exec bash -c '
    file="$1"
    # Заменить все методы на пустые
    sed -i "s/invoke-.*AdView/# invoke (disabled)/g" "$file"
' bash {} \;
```

Эти примеры покрывают большинство сценариев использования инструментов патчинга!
