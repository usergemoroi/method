# APK Анализ: GameBlaster-Pro_3.1_Final

## Общая информация

- **Размер архива:** 6.4 МБ
- **Количество файлов:** 585
- **Дата сборки:** 18 января 2026
- **Пакет приложения:** `com.eternal.xdsdk`
- **Имя приложения:** GameBlaster Pro 3.1 Final

### Технологический стек
- **Язык:** Kotlin
- **Build System:** Gradle 8.11.1
- **Kotlin Plugin:** 1.9.0
- **Целевая платформа:** Android (min API 21)
- **R8 ProGuard:** Включён (full mode, версия 8.10.21)
- **Архитектуры:** ARM64-v8a, ARM, x86, x86_64

---

## Структура APK

```
/
 AndroidManifest.xml (бинарный формат, 49КБ)
 classes.dex (1.7 МБ) - байт-код приложения
 resources.arsc (569 КБ, 4147 строк)
 lib/arm64-v8a/
   ├── libclient.so (4.6 МБ) - основная логика
   ├── libe6bmfqax5v.so (846 КБ) - Mundo SDK
   └── libmsaoaidsec.so (670 КБ) - защита/анти-отладка
 assets/
   ├── burriEnc (699 КБ) - зашифрованные ресурсы
   ├── burriiiii/ - дополнительные .so библиотеки
   ├── app_acf, app_name
   └── dexopt/ - профили оптимизации
 Obs/ - обфусцированные ресурсы (Unicode имена)
 META-INF/ - подпись APK
```

---

## Основные компоненты (Java/Kotlin)

### Пакет `com.eternal.xdsdk`
- `App` - Application класс
- `MainActivity` - Главный экран
- `LoginActivity` - Экран входа/активации
- `SuperJNI$Companion` - JNI обёртка
- `FloaterService` - Сервис плавающей кнопки

### Дополнительные компоненты
- 24 stub-провайдера (stub1-stub24) - вероятно, для обхода детекта
- Stub-ресиверы для фреймворка
- Provider сервисы
- Поставщики контента

---

## Система лицензирования XDSDK

### Найденные URL и домены
- **Основной домен:** `62v.net`
- **API endpoint:** `https://www.62v.net/jnative/binder`
- **Поддомен:** `blackeji.62v.net`
- **Контакт:** `nico: help@62v.net`

### JNI методы в libclient.so

#### Проверка лицензии
```java
Java_com_eternal_xdsdk_SuperJNI_00024Companion_check
Java_com_eternal_xdsdk_SuperJNI_00024Companion_licence
```

#### Система обновлений
```java
Java_com_eternal_xdsdk_SuperJNI_00024Companion_update
Java_com_eternal_xdsdk_SuperJNI_00024Companion_currPlugUrl
Java_com_eternal_xdsdk_SuperJNI_00024Companion_currPlugVer
Java_com_eternal_xdsdk_SuperJNI_00024Companion_currGameVer
```

#### Прочее
```java
Java_com_eternal_xdsdk_SuperJNI_00024Companion_urlTg
Java_com_eternal_xdsdk_SuperJNI_00024Companion_getTime
```

#### FloaterService
```java
Java_com_eternal_xdsdk_FloaterService_connect
Java_com_eternal_xdsdk_FloaterService_disconnect
Java_com_eternal_xdsdk_FloaterService_drawOn
Java_com_eternal_xdsdk_FloaterService_findGame
Java_com_eternal_xdsdk_FloaterService_drawTick
Java_com_eternal_xdsdk_FloaterService_initSurface
Java_com_eternal_xdsdk_FloaterService_removeSurface
Java_com_eternal_xdsdk_FloaterService_setScreen
Java_com_eternal_xdsdk_FloaterService_switch
```

---

## Строки ресурсов (многоязычный интерфейс)

### Логин и активация
- **English:**
  - Clear Login
  - Cleared Login
  - Invalid Key
  - Login
  - Show password

- **Italiano:**
  - Mostra password
  - Errore
  - Passa al mese successivo

- **Tagalog (Филиппинский):**
  - Ipakita ang password
  - Keyfini
  - Tushdan oldin yoki keyinligini tanlang
  - Keyingi oyga o (введите свой ключ)

- **Spanish:**
  - Errorea

### Сообщения об ошибках
- Meta Activation Failed
- Game Connection Error!
- Download Failed
- Error
- Invalid Key
- Failed to Copy Game Obb :(
- Success
- Update Check Failed
- Errorea
- Errore
- Passa al mese successivo

---

## Дополнительные библиотеки

### libe6bmfqax5v.so (Mundo SDK)
- **Размер:** 846 КБ
- **Функции:**
  - `Mundo_Activate_SDK` - активация SDK
  - `JNI_OnLoad` - загрузка JNI
  - Стандартные функции C++ runtime
- Связана с библиотекой "Mundo" из AndroidManifest

### libmsaoaidsec.so (Security)
- **Размер:** 670 КБ
- Обфусцированные строки (например: `d\`I2`, `6f}xIk`)
- Вероятно: анти-отладка или проверка целостности
- Содержит стандартные функции проверки (`__stack_chk_fail`)

### Assets/burriiiiii/*.so
- `lib2f8c0b3257fcc345.so` для разных архитектур
- **Размеры:** 235-400 КБ каждая
- Вероятно: плагины или дополнительные модули

---

## Разрешения приложения


### Основные разрешения
- `INTERNET` - сетевые запросы
- `ACCESS_NETWORK_STATE` - проверка сети
- `SYSTEM_ALERT_WINDOW` - оверлеи поверх экрана
- `FOREGROUND_SERVICE` - фоновый сервис
- `REQUEST_INSTALL_PACKAGES` - установка APK

### Опасные разрешения
- `MANAGE_EXTERNAL_STORAGE` - полный доступ к хранилищу
- `RECORD_AUDIO` - запись звука
- `READ_PHONE_STATE` - доступ к телефону
- `QUERY_ALL_PACKAGES` - список всех приложений
- `PACKAGE_USAGE_STATS` - статистика использования
- `HIDE_OVERLAY_WINDOWS` - скрытие оверлеев

---

## Криптография и защита

### Зашифрованные ресурсы
- **burriEnc (699 КБ)** - основной контент приложения
- Вероятный алгоритм: XTS/AES (упомянут в .txt)
- Расшифровка: в libclient.so

### Сетевая защита
- TLS 1.3
- Certificate Verify
- HTTPS только

### Подпись APK
- META-INF/AATMARAM.RSA
- META-INF/AATMARAM.SF
- META-INF/MANIFEST.MF

---

## Архитектура защиты XDSDK

```

               Приложение запускается               │

                     │
                     ▼
              ┌──────────────┐
              │ LoginActivity │ ← Экран ввода ключа
              └──────┬───────┘
                     │
                     ▼
          ┌──────────────────────┐
          │ SuperJNI.check()    │ ← JNI вызов проверки ключа
          └──────────┬─────────┘
                     │
                     ▼
          ┌──────────────────────┐
          │ libclient.so        │ ← Основная логика
          │  ┌────────────────┐ │
          │  │ libcurl        │ │ ← HTTP запросы к 62v.net
          │  │ OpenSSL        │ │ ← TLS/SSL
          │  └────────────────┘ │
          └──────────┬─────────┘
                     │
                     ▼
          ┌──────────────────────┐
          │ 62v.net сервер     │ ← Проверка лицензии
          └──────────┬─────────┘
                     │
          ┌────────┼────────┐
          │        │        │
      Success   Fail   Update
          │        │        │
          ▼        ▼        ▼
     MainActivity  Exit  Download patch
          │                    │
          ▼                    ▼
     burriEnc ◄───────────── libclient.so (расшифровка)
          │
          ▼
     FloaterService (оверлей)
```

---

## Технические метрики

| Компонент | Размер | Строк | Описание |
|-----------|--------|--------|----------|
| classes.dex | 1.7 МБ | 18,237 | Байт-код Kotlin/Java |
| libclient.so | 4.6 МБ | 21,825 | Основная нативная библиотека |
| resources.arsc | 569 КБ | 4,147 | Таблица ресурсов |
| burriEnc | 699 КБ | - | Зашифрованные ассеты |
| APK (total) | 6.4 МБ | 585 файлов | Полный архив |

---

## Выводы

1. Приложение использует систему лицензирования XDSDK с клиент-серверной архитектурой
2. Сервер `62v.net` находится в сети (вероятно живой)
3. Логика проверки находится в нативном коде (libclient.so), что затрудняет модификацию
4. Многоязычный интерфейс поддерживает английский, итальянский, тагалогский, испанский
5. Зашифрованные ресурсы (burriEnc) требуют рабочей libclient.so
6. Система обновлений отделена от лицензирования и может быть сохранена
7. Приложение имеет очень широкие разрешения, что характерно для overlay-приложений

---

*Анализ выполнен: 17 февраля 2026*
