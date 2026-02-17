# Техническая документация по патчингу XDSDK

## Обзор

Данный проект содержит инструменты для удаления системы проверки лицензий из Android-приложения с XDSDK, сохраняя при этом функциональность автообновлений и корректную работу с зашифрованными ассетами.

## Архитектура XDSDK

### 1. Native Layer (libclient.so)

**Расположение:** `lib/arm64-v8a/libclient.so`

**Критические функции:**

#### 1.1. Функция проверки лицензии
```c
// JNI: Java_com_eternal_xdsdk_SuperJNI_00024Companion_check
JNIEXPORT jboolean JNICALL check(JNIEnv* env, jobject obj, jstring key) {
    // Отправляет HTTP запрос к серверу проверки
    // Возвращает true если ключ валидный
}
```

**Патч (ARM64 Assembly):**
```asm
MOV W0, #1      ; Загрузить 1 в регистр W0 (возвращаемое значение)
RET             ; Вернуться из функции
```

**Hex патч:**
```
20 00 80 52 C0 03 5F D6
```

#### 1.2. Функция проверки licence
```c
// JNI: Java_com_eternal_xdsdk_SuperJNI_00024Companion_licence
JNIEXPORT jboolean JNICALL licence(JNIEnv* env, jobject obj) {
    // Дополнительная проверка наличия активной лицензии
    // Может проверять срок действия и другие параметры
}
```

**Патч:** Аналогичен функции check

#### 1.3. Функция update (НЕ ТРОГАТЬ!)
```c
// JNI: Java_com_eternal_xdsdk_SuperJNI_00024Companion_update
JNIEXPORT jobject JNICALL update(JNIEnv* env, jobject obj) {
    // Запрашивает информацию об обновлениях
    // Возвращает объект с полями: currPlugUrl, currPlugVer
}
```

**Важно:** Эта функция должна остаться нетронутой!

#### 1.4. Расшифровка burriEnc
```c
// Функция расшифровки AES-XTS
void decrypt_burri(uint8_t* encrypted_data, size_t len, uint8_t* key) {
    // Используется для расшифровки assets/burriEnc
    // НЕ МОДИФИЦИРОВАТЬ!
}
```

**Важно:** Алгоритм расшифровки не должен быть затронут патчами!

### 2. Java/Smali Layer

#### 2.1. Класс SuperJNI

**Путь:** `smali/com/eternal/xdsdk/SuperJNI.smali`

**Структура класса:**

```smali
.class public final Lcom/eternal/xdsdk/SuperJNI;
.super Ljava/lang/Object;

# Companion object с нативными методами
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lcom/eternal/xdsdk/SuperJNI$Companion;
    }
.end annotation

# Нативные методы
.method public static native check(Ljava/lang/String;)Z
.end method

.method public static native licence()Z
.end method

.method public static native update()Lcom/eternal/xdsdk/UpdateInfo;
.end method
```

**Патч для check():**

```smali
.method public static check(Ljava/lang/String;)Z
    .locals 1
    
    # License check bypassed - always return true
    const/4 v0, 0x1
    return v0
    
.end method
```

**Патч для licence():**

```smali
.method public static licence()Z
    .locals 1
    
    # License check bypassed - always return true
    const/4 v0, 0x1
    return v0
    
.end method
```

#### 2.2. Класс LoginActivity

**Путь:** `smali/com/eternal/xdsdk/LoginActivity.smali`

**Оригинальный onCreate:**

```smali
.method protected onCreate(Landroid/os/Bundle;)V
    .locals 5
    
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
    
    # Показ UI для ввода лицензионного ключа
    const v0, 0x7f0d001a
    invoke-virtual {p0, v0}, Landroid/app/Activity;->setContentView(I)V
    
    # ... код обработки ввода ключа
    
.end method
```

**Пропатченный onCreate:**

```smali
.method protected onCreate(Landroid/os/Bundle;)V
    .locals 3
    
    # Call super.onCreate
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
    
    # Skip login - go directly to MainActivity
    new-instance v0, Landroid/content/Intent;
    const-class v1, Lcom/eternal/MainActivity;
    invoke-direct {v0, p0, v1}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    invoke-virtual {p0, v0}, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
    invoke-virtual {p0}, Landroid/app/Activity;->finish()V
    
    return-void
    
.end method
```

### 3. AndroidManifest.xml

**Изменение LAUNCHER Activity:**

**До:**
```xml
<activity android:name=".LoginActivity">
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>

<activity android:name=".MainActivity">
    <!-- без intent-filter -->
</activity>
```

**После:**
```xml
<activity android:name=".LoginActivity">
    <!-- LAUNCHER intent-filter removed by patch -->
</activity>

<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```

## Инструменты

### 1. Декомпиляция: apktool

```bash
apktool d app.apk -o decompiled
```

**Что получаем:**
- `AndroidManifest.xml` - в читаемом виде
- `smali/` - байткод в smali формате
- `lib/` - нативные библиотеки
- `assets/` - ассеты, включая burriEnc
- `res/` - ресурсы

### 2. Анализ нативных библиотек

#### readelf - анализ символов
```bash
readelf -s lib/arm64-v8a/libclient.so | grep -E "(check|licence)"
```

#### Ghidra - дизассемблирование
1. Импортировать libclient.so
2. Автоанализ
3. Найти функции через Symbol Tree
4. Найти офсеты функций

#### radare2 - патчинг
```bash
r2 -w libclient.so
aaa                          # Анализ
afl~check                    # Найти check
s sym.check                  # Перейти к функции
wx 20008052c0035fd6          # Записать патч
q                            # Выход
```

### 3. Сборка: apktool + apksigner

```bash
# Сборка
apktool b decompiled -o unsigned.apk

# Выравнивание
zipalign -v -p 4 unsigned.apk aligned.apk

# Подпись (V2/V3 для Android 11+)
apksigner sign --ks keystore.jks --out signed.apk aligned.apk
```

## Процесс патчинга

### Шаг 1: Декомпиляция
```bash
./scripts/decompile.sh app.apk
```

### Шаг 2: Анализ нативной библиотеки
```bash
python3 scripts/analyze_native.py decompiled/lib/arm64-v8a/libclient.so
```

**Вывод покажет:**
- Найденные символы check/licence
- Офсеты функций
- Инструкции для ручного патчинга

### Шаг 3: Патчинг (автоматический)
```bash
./scripts/patch_all.sh
```

**Или ручной патчинг:**

1. **Native:**
   ```bash
   ./scripts/patch_native.sh decompiled/lib/arm64-v8a/libclient.so
   ```

2. **Smali:**
   ```bash
   ./scripts/patch_smali.sh decompiled
   ```

### Шаг 4: Сборка
```bash
./scripts/build.sh
```

**Результат:** `app-patched.apk`

### Шаг 5: Тестирование
```bash
adb install -r app-patched.apk
adb logcat | grep -i "eternal\|xdsdk"
```

**Проверить:**
- ✓ Приложение запускается без экрана логина
- ✓ Нет запросов к серверу лицензий
- ✓ Автообновления работают
- ✓ Ассеты загружаются (burriEnc расшифровывается)
- ✓ Нет крашей

## Возможные проблемы

### Проблема 1: App crashes при старте

**Причина:** Некорректный патч native библиотеки затронул критические функции

**Решение:**
1. Проверить что патч применен только к check/licence
2. Убедиться что расшифровка ассетов не затронута
3. Проверить logcat на ошибки JNI

### Проблема 2: Автообновления не работают

**Причина:** Метод update был заблокирован или требует авторизации

**Решение:**
1. Убедиться что метод update НЕ пропатчен
2. Проверить сетевые запросы через mitmproxy
3. Возможно нужна эмуляция валидной сессии

### Проблема 3: APK не устанавливается

**Причина:** Некорректная подпись или отсутствие V2/V3 signature

**Решение:**
```bash
# Использовать apksigner вместо jarsigner
apksigner sign --ks keystore.jks --out signed.apk aligned.apk

# Проверить подпись
apksigner verify --verbose signed.apk
```

### Проблема 4: Assets не загружаются

**Причина:** Патч повредил алгоритм расшифровки

**Решение:**
1. Откатить патчи native библиотеки
2. Применить патч ТОЛЬКО к check/licence, избегая других функций
3. Использовать более точный метод патчинга (Ghidra + ручное редактирование)

## ARM64 Assembly Reference

### Регистры
- `W0-W30` - 32-битные регистры
- `X0-X30` - 64-битные регистры
- `W0/X0` - используется для возвращаемого значения

### Инструкции для патчинга

#### Возврат true (boolean)
```asm
MOV W0, #1      ; 20 00 80 52
RET             ; C0 03 5F D6
```

#### Возврат false (boolean)
```asm
MOV W0, #0      ; 00 00 80 52
RET             ; C0 03 5F D6
```

#### Возврат NULL (pointer)
```asm
MOV X0, #0      ; 00 00 80 D2
RET             ; C0 03 5F D6
```

#### NOP (нет операции)
```asm
NOP             ; 1F 20 03 D5
```

## Безопасность

**⚠️ ВАЖНО:**

1. Этот метод следует использовать только для собственных приложений
2. Модификация чужих приложений может нарушать лицензионные соглашения
3. Перед распространением пропатченного APK убедитесь, что у вас есть права на это
4. Всегда создавайте резервные копии оригинального APK

## Дополнительные ресурсы

- [apktool documentation](https://ibotpeaches.github.io/Apktool/)
- [ARM64 instruction set](https://developer.arm.com/documentation/ddi0596/latest/)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Smali/Baksmali](https://github.com/JesusFreke/smali)
