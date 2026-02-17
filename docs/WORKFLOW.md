# Рабочий процесс патчинга

## Быстрый старт

### Предварительные требования

```bash
# Обновить систему
sudo apt-get update

# Установить Java (для apktool)
sudo apt-get install -y default-jdk

# Установить инструменты Android
sudo apt-get install -y zipalign

# Клонировать репозиторий
git clone <your-repo>
cd <your-repo>

# Сделать скрипты исполняемыми
chmod +x scripts/*.sh
```

### Автоматический патчинг (рекомендуется)

```bash
# 1. Положите ваш APK в корень проекта
cp /path/to/app.apk ./app.apk

# 2. Запустите полный конвейер
./scripts/full_pipeline.sh app.apk

# Результат: app-patched.apk
```

### Ручной патчинг (для продвинутых)

#### Шаг 1: Декомпиляция
```bash
./scripts/decompile.sh app.apk
# Создает директорию: decompiled/
```

#### Шаг 2: Анализ нативной библиотеки
```bash
python3 scripts/analyze_native.py decompiled/lib/arm64-v8a/libclient.so

# Вывод покажет:
# - Символы функций
# - Офсеты в файле
# - Инструкции для патчинга
```

**Если нужен точный анализ:**

1. Открыть `libclient.so` в Ghidra:
   ```bash
   # Установить Ghidra (если не установлен)
   # https://ghidra-sre.org/
   
   # Импортировать libclient.so
   # File -> Import File -> выбрать .so
   # Запустить Auto Analysis
   ```

2. Найти функции:
   - Window -> Symbol Tree
   - Искать: `Java_com_eternal_xdsdk_SuperJNI_00024Companion_check`
   - Искать: `Java_com_eternal_xdsdk_SuperJNI_00024Companion_licence`

3. Получить офсеты:
   - Кликнуть на функцию
   - В Listing window будет показан адрес
   - File offset = адрес - base address

4. Пропатчить вручную:
   ```bash
   # Использовать hex редактор (например, hexedit или xxd)
   hexedit decompiled/lib/arm64-v8a/libclient.so
   
   # Перейти к офсету функции (например, 0x12340)
   # Заменить первые 8 байт на: 20 00 80 52 C0 03 5F D6
   ```

#### Шаг 3: Патчинг Smali
```bash
./scripts/patch_smali.sh decompiled

# Модифицирует:
# - SuperJNI.smali (методы check/licence)
# - LoginActivity.smali (onCreate)
# - AndroidManifest.xml (LAUNCHER activity)
```

**Ручная проверка:**

```bash
# Проверить SuperJNI
cat decompiled/smali*/com/eternal/xdsdk/SuperJNI*.smali | grep -A 5 "check\|licence"

# Проверить LoginActivity
cat decompiled/smali*/com/eternal/xdsdk/LoginActivity.smali | grep -A 10 "onCreate"

# Проверить Manifest
cat decompiled/AndroidManifest.xml | grep -A 5 "MainActivity\|LoginActivity"
```

#### Шаг 4: Сборка
```bash
./scripts/build.sh decompiled app-patched.apk

# Процесс:
# 1. Очистка META-INF
# 2. Сборка с apktool
# 3. zipalign
# 4. Подпись с apksigner (V2/V3)
```

#### Шаг 5: Установка и тестирование
```bash
# Установка
adb install -r app-patched.apk

# Запуск
adb shell am start -n com.eternal/.MainActivity

# Мониторинг логов
adb logcat -c
adb logcat | grep -i "eternal\|xdsdk\|AndroidRuntime"
```

## Расширенные сценарии

### Сценарий 1: Отладка проблем с нативной библиотекой

```bash
# Извлечь библиотеку из APK
unzip -j app.apk "lib/arm64-v8a/libclient.so" -d /tmp/

# Сравнить с пропатченной
cmp /tmp/libclient.so decompiled/lib/arm64-v8a/libclient.so

# Посмотреть различия в hex
xxd /tmp/libclient.so > original.hex
xxd decompiled/lib/arm64-v8a/libclient.so > patched.hex
diff -u original.hex patched.hex | less

# Дизассемблировать участок кода
objdump -D -b binary -m aarch64 --start-address=0x12340 --stop-address=0x12360 \
  decompiled/lib/arm64-v8a/libclient.so
```

### Сценарий 2: Проверка сетевых запросов

```bash
# Установить mitmproxy
pip3 install mitmproxy

# Запустить proxy
mitmweb -p 8080

# Настроить Android устройство:
# Settings -> Wi-Fi -> Long press network -> Modify -> Advanced
# Proxy: Manual
# Host: <IP компьютера>
# Port: 8080

# Установить сертификат mitmproxy на устройстве
adb push ~/.mitmproxy/mitmproxy-ca-cert.cer /sdcard/
# Settings -> Security -> Install from storage

# Запустить приложение и проверить запросы в mitmweb
```

### Сценарий 3: Анализ расшифровки burriEnc

```bash
# Извлечь burriEnc
unzip -j app.apk "assets/burriEnc" -d /tmp/

# Проверить формат
file /tmp/burriEnc
xxd /tmp/burriEnc | head -20

# Попытаться найти сигнатуру AES-XTS в библиотеке
strings decompiled/lib/arm64-v8a/libclient.so | grep -i "aes\|xts\|crypt"

# Посмотреть вызовы к функциям расшифровки
r2 decompiled/lib/arm64-v8a/libclient.so
aaa
afl~decrypt
afl~aes
```

### Сценарий 4: Проверка автообновлений

```bash
# Найти код обновлений в Smali
find decompiled -name "*.smali" -exec grep -l "update\|currPlugUrl\|currPlugVer" {} \;

# Проверить метод update в SuperJNI
cat decompiled/smali*/com/eternal/xdsdk/SuperJNI*.smali | grep -A 20 "method.*update"

# Перехватить запрос обновления через mitmproxy
# Искать URL типа: http://api.eternal.com/update или https://...
```

### Сценарий 5: Откат изменений

```bash
# Восстановить оригинальный APK
git checkout -- decompiled/

# Или заново декомпилировать
rm -rf decompiled/
./scripts/decompile.sh app.apk

# Откатить только native патчи
cd decompiled/lib/arm64-v8a/
unzip -j ../../../../app.apk "lib/arm64-v8a/libclient.so"
```

## Чеклист перед релизом

- [ ] **Функциональность**
  - [ ] Приложение запускается без крашей
  - [ ] Не показывается экран ввода лицензии
  - [ ] Основной функционал работает
  - [ ] Можно загружать контент
  - [ ] Нет зависаний при старте

- [ ] **Проверки безопасности**
  - [ ] Удалены все отладочные логи
  - [ ] Нет хардкодненных ключей/токенов
  - [ ] APK подписан релизным keystore
  - [ ] META-INF очищен от старых подписей

- [ ] **Автообновления**
  - [ ] Метод update() НЕ пропатчен
  - [ ] Запросы к серверу обновлений работают
  - [ ] currPlugUrl и currPlugVer получают данные
  - [ ] Скачивание обновлений работает

- [ ] **Assets и ресурсы**
  - [ ] burriEnc корректно расшифровывается
  - [ ] Все ресурсы загружаются
  - [ ] Нет ошибок про missing assets

- [ ] **Совместимость**
  - [ ] Работает на Android 11+
  - [ ] Работает на Android 7-10
  - [ ] Подпись V2/V3 валидна
  - [ ] zipalign применен

## Troubleshooting

### Ошибка: "apktool: command not found"

```bash
wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool -O /tmp/apktool
wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O /tmp/apktool.jar
sudo mv /tmp/apktool /usr/local/bin/
sudo mv /tmp/apktool.jar /usr/local/bin/
sudo chmod +x /usr/local/bin/apktool
```

### Ошибка: "zipalign: command not found"

```bash
# Вариант 1: Установить из репозитория
sudo apt-get install -y zipalign

# Вариант 2: Скачать Android SDK
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-*.zip
cd cmdline-tools/bin
./sdkmanager --install "build-tools;33.0.0"
# zipalign будет в: build-tools/33.0.0/zipalign
```

### Ошибка: "apksigner: command not found"

```bash
# Установить через SDK (как выше)
# Или использовать jarsigner как fallback:
jarsigner -verbose -keystore release.keystore app.apk releasekey
```

### Ошибка при декомпиляции: "brut.androlib.AndrolibException"

```bash
# Обновить apktool до последней версии
# Или использовать флаг --no-res
apktool d app.apk -o decompiled --no-res
```

### APK крашится при запуске

```bash
# Проверить logcat
adb logcat | grep -i "fatal\|exception"

# Частые причины:
# 1. Некорректный патч native библиотеки
# 2. Проблемы с подписью
# 3. Конфликт MainActivity в манифесте
# 4. Ошибки в Smali синтаксисе

# Решение: откатить патчи и применять по одному
```

### Автообновления не работают

```bash
# Проверить что метод update не затронут
grep -A 30 "method.*update" decompiled/smali*/com/eternal/xdsdk/SuperJNI*.smali

# Должен быть вызов нативного метода:
# invoke-static {...}, Lcom/eternal/xdsdk/SuperJNI;->update()L...;

# Проверить сетевые запросы через mitmproxy
```

## Автоматизация

### CI/CD скрипт

```bash
#!/bin/bash
# .github/workflows/patch.yml или Jenkins

set -e

# 1. Скачать оригинальный APK (из приватного хранилища)
wget -O app.apk "https://storage.example.com/app.apk"

# 2. Патчинг
./scripts/full_pipeline.sh app.apk

# 3. Тестирование (через эмулятор)
./scripts/test_apk.sh app-patched.apk

# 4. Загрузка результата
curl -X POST -F "file=@app-patched.apk" "https://deploy.example.com/upload"

echo "✓ Patched APK deployed"
```

### Git hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash

# Проверить что keystore не коммитится
if git diff --cached --name-only | grep -q "\.keystore\|\.jks"; then
    echo "ERROR: Keystore files should not be committed!"
    exit 1
fi

# Проверить синтаксис Python скриптов
python3 -m py_compile scripts/*.py

echo "✓ Pre-commit checks passed"
```
